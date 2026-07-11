<#
.SYNOPSIS
    Provisiona la infraestructura Azure de ShopDemo (ACA, AKS o ambos).

.DESCRIPTION
    Script del curso Lite Thinking - ShopDemo.
    NO construye ni publica imágenes Docker (usar GitHub Actions o build manual).

    Modos:
      ACA  - Event Hubs, Storage, ACR, PostgreSQL (ACI), Container Apps (5 APIs + MCP)
      AKS  - Event Hubs, ACR, cluster AKS, Ingress NGINX, genera k8s/secrets.yaml
      All  - ACA + AKS (laboratorio completo)

    Documentación:
      - Documentación del Proyecto/despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md
      - Documentación del Proyecto/despliegue/aks/IMPLEMENTACION-DESPLIEGUE-AKS.md
      - Documentación del Proyecto/INTEGRACION-AZURE-EVENT-HUBS.md
      - Documentación del Proyecto/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md
      - Source/scripts/azure/README.md

.PARAMETER Mode
    ACA | AKS | All

.PARAMETER EnvFile
    Ruta al archivo .env.azure (por defecto: junto a este script).

.EXAMPLE
    cd I:\Curso\ShopDemo\scripts\azure
    copy .env.azure.example .env.azure
    # Editar .env.azure con tu Subscription ID y nombres únicos
    .\Deploy-AzureShopDemo.ps1 -Mode ACA

.EXAMPLE
    .\Deploy-AzureShopDemo.ps1 -Mode AKS
    # Luego: publicar imágenes en ACR, apply compartidos + k8s/azure/ (ver k8s/README.md)
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('ACA', 'AKS', 'All')]
    [string] $Mode,

    [string] $EnvFile = (Join-Path $PSScriptRoot '.env.azure')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# -----------------------------------------------------------------------------
# Utilidades
# -----------------------------------------------------------------------------

function Write-Step {
    param([string] $Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Info {
    param([string] $Message)
    Write-Host "    $Message" -ForegroundColor DarkGray
}

function Write-Warn {
    param([string] $Message)
    Write-Host "    [AVISO] $Message" -ForegroundColor Yellow
}

function Write-Ok {
    param([string] $Message)
    Write-Host "    [OK] $Message" -ForegroundColor Green
}

function Import-EnvFile {
    param([string] $Path)
    if (-not (Test-Path $Path)) {
        throw "No se encontró '$Path'. Copia .env.azure.example a .env.azure y complétalo."
    }
    $config = @{}
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq '' -or $line.StartsWith('#')) { return }
        $idx = $line.IndexOf('=')
        if ($idx -lt 1) { return }
        $key = $line.Substring(0, $idx).Trim()
        $val = $line.Substring($idx + 1).Trim()
        if ($val -match '^<<<.*>>>$') {
            throw "Completa el valor de '$key' en $Path"
        }
        $config[$key] = $val
    }
    return $config
}

function Invoke-AzCli {
    param(
        [string] $Label,
        [string[]] $AzArguments,
        [switch] $AllowFailure
    )
    Write-Info $Label
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & az @AzArguments 2>&1
    }
    finally {
        $ErrorActionPreference = $prevEap
    }
    if ($LASTEXITCODE -ne 0 -and -not $AllowFailure) {
        throw "Falló: az $($AzArguments -join ' ')`n$output"
    }
    return $output
}

function Test-AzGroupExists {
    param([string] $Name)
    $r = Invoke-AzCli 'Comprobar Resource Group' @(
        'group', 'show', '--name', $Name, '-o', 'none'
    ) -AllowFailure
    return $LASTEXITCODE -eq 0
}

function Test-AzResourceExists {
    param([string[]] $AzArgs)
    $null = Invoke-AzCli 'Comprobar recurso' @($AzArgs + @('-o', 'none')) -AllowFailure
    return $LASTEXITCODE -eq 0
}

function Test-AcaEnvReady {
    param([string]$Name, [string]$ResourceGroup)
    if (-not (Test-AzResourceExists @('containerapp', 'env', 'show', '--name', $Name, '--resource-group', $ResourceGroup))) {
        return $false
    }
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $json = & az containerapp env show --name $Name --resource-group $ResourceGroup -o json 2>$null | ConvertFrom-Json
    }
    finally {
        $ErrorActionPreference = $prevEap
    }
    return ($null -ne $json -and $json.properties.provisioningState -eq 'Succeeded')
}

function Wait-AcaEnvReady {
    param([string]$Name, [string]$ResourceGroup, [int]$MaxMinutes = 20)
    for ($i = 0; $i -lt ($MaxMinutes * 6); $i++) {
        if (Test-AcaEnvReady -Name $Name -ResourceGroup $ResourceGroup) { return $true }
        Start-Sleep -Seconds 10
    }
    return $false
}

function Get-AcrCredentials {
    param([string] $AcrName)
    # Lab: admin habilitado para pull en Container Apps sin managed identity.
    # Producción: usar identidad administrada + rol AcrPull (ver doc Azure).
    Invoke-AzCli 'Habilitar admin en ACR (lab)' @(
        'acr', 'update', '--name', $AcrName, '--admin-enabled', 'true'
    ) | Out-Null
    $loginServer = Invoke-AzCli 'ACR login server' @(
        'acr', 'show', '--name', $AcrName, '--query', 'loginServer', '-o', 'tsv'
    )
    $password = Invoke-AzCli 'ACR password' @(
        'acr', 'credential', 'show', '--name', $AcrName,
        '--query', 'passwords[0].value', '-o', 'tsv'
    )
    return @{
        LoginServer = $loginServer.Trim()
        Username    = $AcrName
        Password    = $password.Trim()
    }
}

function Merge-Hash {
    param([hashtable[]] $Tables)
    $result = @{}
    foreach ($t in $Tables) {
        if ($null -eq $t) { continue }
        foreach ($k in $t.Keys) { $result[$k] = $t[$k] }
    }
    return $result
}

function New-PostgresDatabases {
    param(
        [string] $PostgresHost,
        [string] $User,
        [string] $Password
    )
    $psql = Get-Command psql -ErrorAction SilentlyContinue
    if (-not $psql) {
        Write-Warn "psql no está en PATH. Crea las bases manualmente (Cloud Shell o cliente SQL):"
        Write-Info "CREATE DATABASE `"ShopDemoCatalog`";"
        Write-Info "CREATE DATABASE `"ShopDemoOrders`";"
        Write-Info "CREATE DATABASE `"ShopDemoInventory`";"
        return
    }
    $conn = "host=$PostgresHost port=5432 user=$User password=$Password dbname=postgres sslmode=require"
    $sql = 'CREATE DATABASE "ShopDemoCatalog"; CREATE DATABASE "ShopDemoOrders"; CREATE DATABASE "ShopDemoInventory";'
    & psql $conn -c $sql
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "No se pudieron crear las BD automáticamente. Ejecuta el SQL manualmente contra $PostgresHost"
    }
    else {
        Write-Ok "Bases ShopDemoCatalog, ShopDemoOrders, ShopDemoInventory creadas"
    }
}

function New-K8sSecretsFile {
    param(
        [string] $RepoRoot,
        [string] $EventHubsConn,
        [string] $PostgresPassword,
        [string] $PostgresUser
    )
    $outPath = Join-Path $RepoRoot 'k8s\secrets.yaml'
    $ehEscaped = $EventHubsConn -replace '"', '\"'
    $content = @"
# GENERADO por Deploy-AzureShopDemo.ps1 - NO COMMITEAR
# Aplicar: kubectl apply -f k8s/secrets.yaml
# Guía: Documentación del Proyecto/despliegue/aks/IMPLEMENTACION-DESPLIEGUE-AKS.md

apiVersion: v1
kind: Secret
metadata:
  name: shopdemo-secrets
  namespace: shopdemo
type: Opaque
stringData:
  POSTGRES_USER: $PostgresUser
  POSTGRES_PASSWORD: $PostgresPassword
  EVENT_HUBS_CONNECTION_STRING: "$ehEscaped"
  PG_CATALOG_CONN: "Host=shopdemo-postgres;Port=5432;Database=ShopDemoCatalog;Username=$PostgresUser;Password=$PostgresPassword"
  PG_ORDERS_CONN: "Host=shopdemo-postgres;Port=5432;Database=ShopDemoOrders;Username=$PostgresUser;Password=$PostgresPassword"
  PG_INVENTORY_CONN: "Host=shopdemo-postgres;Port=5432;Database=ShopDemoInventory;Username=$PostgresUser;Password=$PostgresPassword"
  AZURITE_CHECKPOINT_CONN: "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://shopdemo-azurite:10000/devstoreaccount1;"
"@
    Set-Content -Path $outPath -Value $content -Encoding UTF8
    Write-Ok "Generado $outPath (checkpoints Azurite in-cluster para AKS)"
}

function New-ContainerAppIfMissing {
    param(
        [hashtable] $Config,
        [hashtable] $Acr,
        [string] $AppName,
        [string] $ImageName,
        [string] $Ingress,          # external | internal
        [int] $MinReplicas,
        [int] $MaxReplicas,
        [hashtable] $Secrets,
        [hashtable] $EnvVars
    )
    $rg = $Config.RESOURCE_GROUP
    $acaEnvName = $Config.ACA_ENV_NAME
    $tag = $Config.IMAGE_TAG
    $image = "$($Acr.LoginServer)/${ImageName}:$tag"

    if (Test-AzResourceExists @('containerapp', 'show', '--name', $AppName, '--resource-group', $rg)) {
        Write-Warn "Container App '$AppName' ya existe - omitiendo creación"
        return
    }

    $secretArgs = @()
    foreach ($kv in $Secrets.GetEnumerator()) {
        $val = [string]$kv.Value
        if ($val -match '[;=\s]') {
            $escaped = $val -replace '"', '\"'
            $secretArgs += "$($kv.Key)=`"$escaped`""
        }
        else {
            $secretArgs += "$($kv.Key)=$val"
        }
    }

    $envArgs = @()
    foreach ($kv in $EnvVars.GetEnumerator()) {
        $envArgs += "$($kv.Key)=$($kv.Value)"
    }

    $createArgs = @(
        'containerapp', 'create',
        '--name', $AppName,
        '--resource-group', $rg,
        '--environment', $acaEnvName,
        '--image', $image,
        '--registry-server', $Acr.LoginServer,
        '--registry-username', $Acr.Username,
        '--registry-password', $Acr.Password,
        '--target-port', '8080',
        '--ingress', $Ingress,
        '--min-replicas', "$MinReplicas",
        '--max-replicas', "$MaxReplicas",
        '--cpu', '0.5',
        '--memory', '1.0Gi'
    )
    if ($secretArgs.Count -gt 0) {
        $createArgs += '--secrets'
        $createArgs += $secretArgs
    }
    if ($envArgs.Count -gt 0) {
        $createArgs += '--env-vars'
        $createArgs += $envArgs
    }

    Invoke-AzCli "Crear Container App $AppName" $createArgs | Out-Null
    Write-Ok "Container App $AppName creada"
}

function Get-ContainerAppFqdn {
    param([string] $AppName, [string] $ResourceGroup)
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $fqdn = (& az containerapp show --name $AppName --resource-group $ResourceGroup `
            --query 'properties.configuration.ingress.fqdn' -o tsv 2>$null | Out-String).Trim()
    }
    finally {
        $ErrorActionPreference = $prevEap
    }
    return $fqdn
}

# -----------------------------------------------------------------------------
# Inicio
# -----------------------------------------------------------------------------

Write-Host ""
Write-Host "ShopDemo - Provisionamiento Azure (modo: $Mode)" -ForegroundColor White
Write-Host "Ref: Documentación del Proyecto/despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md" -ForegroundColor DarkGray

$cfg = Import-EnvFile -Path $EnvFile
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path

$deployAca = $Mode -in 'ACA', 'All'
$deployAks = $Mode -in 'AKS', 'All'

# -----------------------------------------------------------------------------
# Paso 0 - Prerrequisitos
# -----------------------------------------------------------------------------
Write-Step "Paso 0 - Prerrequisitos (Azure CLI, login, extensiones)"
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw "Instala Azure CLI: https://learn.microsoft.com/cli/azure/install-azure-cli"
}

Invoke-AzCli 'Registrar proveedor Microsoft.App' @(
    'provider', 'register', '--namespace', 'Microsoft.App', '--wait'
) | Out-Null
Invoke-AzCli 'Registrar proveedor Microsoft.ContainerInstance' @(
    'provider', 'register', '--namespace', 'Microsoft.ContainerInstance', '--wait'
) | Out-Null
Invoke-AzCli 'Registrar proveedor Microsoft.ContainerService' @(
    'provider', 'register', '--namespace', 'Microsoft.ContainerService', '--wait'
) | Out-Null
Invoke-AzCli 'Extensión containerapp' @(
    'extension', 'add', '--name', 'containerapp', '--upgrade', '-y'
) | Out-Null

$account = Invoke-AzCli 'Cuenta actual' @('account', 'show', '-o', 'json') | ConvertFrom-Json
if ($cfg.AZURE_SUBSCRIPTION_ID -and $account.id -ne $cfg.AZURE_SUBSCRIPTION_ID) {
    Invoke-AzCli 'Seleccionar suscripción' @(
        'account', 'set', '--subscription', $cfg.AZURE_SUBSCRIPTION_ID
    ) | Out-Null
}
Write-Ok "Sesión: $($account.user.name) / $($cfg.AZURE_SUBSCRIPTION_ID)"

if ($deployAks -and -not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Warn "kubectl no encontrado - necesario para aplicar manifiestos tras el script AKS"
}
if ($deployAks -and -not (Get-Command helm -ErrorAction SilentlyContinue)) {
    Write-Warn "helm no encontrado - instálalo para Ingress NGINX en AKS"
}

# -----------------------------------------------------------------------------
# Paso 1 - Resource Group
# Ref: IMPLEMENTACION-DESPLIEGUE-AZURE.md §3
# -----------------------------------------------------------------------------
Write-Step "Paso 1 - Resource Group ($($cfg.RESOURCE_GROUP))"
if (-not (Test-AzGroupExists $cfg.RESOURCE_GROUP)) {
    Invoke-AzCli 'Crear Resource Group' @(
        'group', 'create', '--name', $cfg.RESOURCE_GROUP, '--location', $cfg.AZURE_LOCATION
    ) | Out-Null
}
Write-Ok "Resource Group listo"

# -----------------------------------------------------------------------------
# Paso 2 - Event Hubs + Storage Account
# Ref: INTEGRACION-AZURE-EVENT-HUBS.md §5
# -----------------------------------------------------------------------------
Write-Step "Paso 2 - Azure Event Hubs y Storage (checkpoints ACA)"

if (-not (Test-AzResourceExists @(
        'eventhubs', 'namespace', 'show',
        '--resource-group', $cfg.RESOURCE_GROUP,
        '--name', $cfg.EVENT_HUB_NAMESPACE
    ))) {
    Invoke-AzCli 'Crear namespace Event Hubs' @(
        'eventhubs', 'namespace', 'create',
        '--resource-group', $cfg.RESOURCE_GROUP,
        '--name', $cfg.EVENT_HUB_NAMESPACE,
        '--sku', 'Standard',
        '--location', $cfg.AZURE_LOCATION
    ) | Out-Null
}

if (-not (Test-AzResourceExists @(
        'eventhubs', 'eventhub', 'show',
        '--resource-group', $cfg.RESOURCE_GROUP,
        '--namespace-name', $cfg.EVENT_HUB_NAMESPACE,
        '--name', $cfg.EVENT_HUB_NAME
    ))) {
    Invoke-AzCli 'Crear Event Hub' @(
        'eventhubs', 'eventhub', 'create',
        '--resource-group', $cfg.RESOURCE_GROUP,
        '--namespace-name', $cfg.EVENT_HUB_NAMESPACE,
        '--name', $cfg.EVENT_HUB_NAME,
        '--partition-count', '4',
        '--cleanup-policy', 'Delete',
        '--retention-time', '24'
    ) | Out-Null
}

$ehConn = Invoke-AzCli 'Connection string Event Hubs' @(
    'eventhubs', 'namespace', 'authorization-rule', 'keys', 'list',
    '--resource-group', $cfg.RESOURCE_GROUP,
    '--namespace-name', $cfg.EVENT_HUB_NAMESPACE,
    '--name', 'RootManageSharedAccessKey',
    '--query', 'primaryConnectionString', '-o', 'tsv'
).Trim()
Write-Ok "Event Hubs: $($cfg.EVENT_HUB_NAMESPACE) / $($cfg.EVENT_HUB_NAME)"

if (-not (Test-AzResourceExists @(
        'storage', 'account', 'show',
        '--name', $cfg.STORAGE_ACCOUNT_NAME,
        '--resource-group', $cfg.RESOURCE_GROUP
    ))) {
    Invoke-AzCli 'Crear Storage Account' @(
        'storage', 'account', 'create',
        '--name', $cfg.STORAGE_ACCOUNT_NAME,
        '--resource-group', $cfg.RESOURCE_GROUP,
        '--location', $cfg.AZURE_LOCATION,
        '--sku', 'Standard_LRS'
    ) | Out-Null
}

$storageConn = Invoke-AzCli 'Connection string Storage' @(
    'storage', 'account', 'show-connection-string',
    '--name', $cfg.STORAGE_ACCOUNT_NAME,
    '--resource-group', $cfg.RESOURCE_GROUP,
    '--query', 'connectionString', '-o', 'tsv'
).Trim()

if ($deployAca) {
    Invoke-AzCli 'Contenedor blob inventory-checkpoints' @(
        'storage', 'container', 'create',
        '--name', 'inventory-checkpoints',
        '--account-name', $cfg.STORAGE_ACCOUNT_NAME,
        '--auth-mode', 'login'
    ) | Out-Null
    Invoke-AzCli 'Contenedor blob analytics-checkpoints' @(
        'storage', 'container', 'create',
        '--name', 'analytics-checkpoints',
        '--account-name', $cfg.STORAGE_ACCOUNT_NAME,
        '--auth-mode', 'login'
    ) | Out-Null
    Write-Ok "Contenedores de checkpoint en Storage Account (modo ACA)"
}

# -----------------------------------------------------------------------------
# Paso 3 - Azure Container Registry
# Ref: IMPLEMENTACION-DESPLIEGUE-AZURE.md §4
# -----------------------------------------------------------------------------
Write-Step "Paso 3 - Azure Container Registry ($($cfg.ACR_NAME))"
if (-not (Test-AzResourceExists @('acr', 'show', '--name', $cfg.ACR_NAME))) {
    Invoke-AzCli 'Crear ACR' @(
        'acr', 'create',
        '--resource-group', $cfg.RESOURCE_GROUP,
        '--name', $cfg.ACR_NAME,
        '--sku', 'Basic',
        '--admin-enabled', 'false'
    ) | Out-Null
}

$acr = Get-AcrCredentials -AcrName $cfg.ACR_NAME
Write-Ok "ACR: $($acr.LoginServer)"

$repos = Invoke-AzCli 'Listar repositorios ACR' @(
    'acr', 'repository', 'list', '--name', $cfg.ACR_NAME, '-o', 'tsv'
) -AllowFailure
$repoList = @($repos | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
$requiredImages = @('shopdemo-catalog', 'shopdemo-orders', 'shopdemo-inventory', 'shopdemo-analytics', 'shopdemo-mcp')
$missing = @($requiredImages | Where-Object { $repoList -notcontains $_ })
if ($missing.Count -gt 0 -and $deployAca) {
    Write-Warn "Imágenes no encontradas en ACR: $($missing -join ', ')"
    Write-Info "Publica con .github/workflows/deploy-azure.yml o build manual (doc §6)"
    Write-Info "Las Container Apps fallarán al arrancar hasta que existan con tag '$($cfg.IMAGE_TAG)'"
}

# -----------------------------------------------------------------------------
# Paso 4 - PostgreSQL en ACI (solo ACA / All)
# Ref: IMPLEMENTACION-DESPLIEGUE-AZURE.md §6
# -----------------------------------------------------------------------------
$pgFqdn = $null
if ($deployAca) {
    Write-Step "Paso 4 - PostgreSQL en Azure Container Instances"
    if (-not (Test-AzResourceExists @(
            'container', 'show',
            '--resource-group', $cfg.RESOURCE_GROUP,
            '--name', $cfg.POSTGRES_ACI_NAME
        ))) {
        $pgImage = "$($acr.LoginServer)/postgres:16-alpine"
        Invoke-AzCli 'Crear ACI PostgreSQL' @(
            'container', 'create',
            '--resource-group', $cfg.RESOURCE_GROUP,
            '--name', $cfg.POSTGRES_ACI_NAME,
            '--image', $pgImage,
            '--registry-login-server', $acr.LoginServer,
            '--registry-username', $acr.Username,
            '--registry-password', $acr.Password,
            '--os-type', 'Linux',
            '--cpu', '1', '--memory', '1.5',
            '--ports', '5432',
            '--ip-address', 'Public',
            '--dns-name-label', $cfg.POSTGRES_DNS_LABEL,
            '--environment-variables',
            "POSTGRES_USER=$($cfg.POSTGRES_USER)",
            "POSTGRES_PASSWORD=$($cfg.POSTGRES_PASSWORD)",
            '--location', $cfg.AZURE_LOCATION
        ) | Out-Null
    }

    $pgFqdn = Invoke-AzCli 'FQDN PostgreSQL ACI' @(
        'container', 'show',
        '--resource-group', $cfg.RESOURCE_GROUP,
        '--name', $cfg.POSTGRES_ACI_NAME,
        '--query', 'ipAddress.fqdn', '-o', 'tsv'
    ).Trim()

    New-PostgresDatabases -PostgresHost $pgFqdn -User $cfg.POSTGRES_USER -Password $cfg.POSTGRES_PASSWORD
    Write-Ok "PostgreSQL ACI: $pgFqdn"
}
else {
    Write-Step "Paso 4 - PostgreSQL omitido (modo AKS usa postgres in-cluster en k8s/postgres/)"
}

# -----------------------------------------------------------------------------
# Paso 5 - Container Apps Environment (solo ACA / All)
# Ref: IMPLEMENTACION-DESPLIEGUE-AZURE.md §5
# -----------------------------------------------------------------------------
if ($deployAca) {
    Write-Step "Paso 5 - Log Analytics + Container Apps Environment"

    if (-not (Test-AzResourceExists @(
            'monitor', 'log-analytics', 'workspace', 'show',
            '--resource-group', $cfg.RESOURCE_GROUP,
            '--workspace-name', $cfg.LOG_ANALYTICS_NAME
        ))) {
        Invoke-AzCli 'Crear Log Analytics' @(
            'monitor', 'log-analytics', 'workspace', 'create',
            '--resource-group', $cfg.RESOURCE_GROUP,
            '--workspace-name', $cfg.LOG_ANALYTICS_NAME
        ) | Out-Null
    }

    $logId = Invoke-AzCli 'Log Analytics customerId' @(
        'monitor', 'log-analytics', 'workspace', 'show',
        '--resource-group', $cfg.RESOURCE_GROUP,
        '--workspace-name', $cfg.LOG_ANALYTICS_NAME,
        '--query', 'customerId', '-o', 'tsv'
    ).Trim()
    $logKey = Invoke-AzCli 'Log Analytics key' @(
        'monitor', 'log-analytics', 'workspace', 'get-shared-keys',
        '--resource-group', $cfg.RESOURCE_GROUP,
        '--workspace-name', $cfg.LOG_ANALYTICS_NAME,
        '--query', 'primarySharedKey', '-o', 'tsv'
    ).Trim()

    if (Test-AcaEnvReady -Name $cfg.ACA_ENV_NAME -ResourceGroup $cfg.RESOURCE_GROUP) {
        Write-Ok "Environment: $($cfg.ACA_ENV_NAME) (listo)"
    }
    elseif (Test-AzResourceExists @('containerapp', 'env', 'show', '--name', $cfg.ACA_ENV_NAME, '--resource-group', $cfg.RESOURCE_GROUP)) {
        if (Wait-AcaEnvReady -Name $cfg.ACA_ENV_NAME -ResourceGroup $cfg.RESOURCE_GROUP -MaxMinutes 15) {
            Write-Ok "Environment: $($cfg.ACA_ENV_NAME) (provisionando -> listo)"
        }
        else {
            Write-Warn "ACA Environment no llego a Succeeded - eliminando para recrear"
            Invoke-AzCli 'Eliminar ACA Environment' @(
                'containerapp', 'env', 'delete', '--name', $cfg.ACA_ENV_NAME,
                '--resource-group', $cfg.RESOURCE_GROUP, '--yes'
            ) | Out-Null
            Start-Sleep -Seconds 30
            $acaLocations = @($cfg.AZURE_LOCATION, 'eastus2', 'centralus') | Select-Object -Unique
            $created = $false
            foreach ($loc in $acaLocations) {
                Write-Info "Intentando ACA Environment en $loc"
                Invoke-AzCli "Crear Container Apps Environment ($loc)" @(
                    'containerapp', 'env', 'create',
                    '--name', $cfg.ACA_ENV_NAME,
                    '--resource-group', $cfg.RESOURCE_GROUP,
                    '--location', $loc,
                    '--logs-workspace-id', $logId,
                    '--logs-workspace-key', $logKey
                ) -AllowFailure | Out-Null
                if (Wait-AcaEnvReady -Name $cfg.ACA_ENV_NAME -ResourceGroup $cfg.RESOURCE_GROUP) {
                    $created = $true
                    break
                }
                Write-Warn "Environment no listo en $loc"
                Invoke-AzCli 'Eliminar ACA Environment' @(
                    'containerapp', 'env', 'delete', '--name', $cfg.ACA_ENV_NAME,
                    '--resource-group', $cfg.RESOURCE_GROUP, '--yes'
                ) -AllowFailure | Out-Null
                Start-Sleep -Seconds 15
            }
            if (-not $created) {
                throw 'No se pudo provisionar Container Apps Environment. Prueba otra region (eastus2, centralus).'
            }
        }
    }
    else {
        $acaLocations = @($cfg.AZURE_LOCATION, 'eastus2', 'centralus') | Select-Object -Unique
        $created = $false
        foreach ($loc in $acaLocations) {
            Write-Info "Intentando ACA Environment en $loc"
            Invoke-AzCli "Crear Container Apps Environment ($loc)" @(
                'containerapp', 'env', 'create',
                '--name', $cfg.ACA_ENV_NAME,
                '--resource-group', $cfg.RESOURCE_GROUP,
                '--location', $loc,
                '--logs-workspace-id', $logId,
                '--logs-workspace-key', $logKey
            ) -AllowFailure | Out-Null
            if (Wait-AcaEnvReady -Name $cfg.ACA_ENV_NAME -ResourceGroup $cfg.RESOURCE_GROUP) {
                $created = $true
                break
            }
            Write-Warn "Environment no listo en $loc"
            Invoke-AzCli 'Eliminar ACA Environment' @(
                'containerapp', 'env', 'delete', '--name', $cfg.ACA_ENV_NAME,
                '--resource-group', $cfg.RESOURCE_GROUP, '--yes'
            ) -AllowFailure | Out-Null
            Start-Sleep -Seconds 15
        }
        if (-not $created) {
            throw 'No se pudo provisionar Container Apps Environment. Prueba otra region (eastus2, centralus).'
        }
    }
    Write-Ok "Environment: $($cfg.ACA_ENV_NAME)"
}

# -----------------------------------------------------------------------------
# Paso 6 - Container Apps (5 servicios + MCP)
# Ref: IMPLEMENTACION-DESPLIEGUE-AZURE.md §8-11, IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md
# Checkpoints ACA: Storage Account real (no Azurite)
# -----------------------------------------------------------------------------
if ($deployAca) {
    Write-Step "Paso 6 - Container Apps (Catalog, Inventory, Orders, Analytics, MCP)"

    $pgCatalog = "Host=$pgFqdn;Port=5432;Database=ShopDemoCatalog;Username=$($cfg.POSTGRES_USER);Password=$($cfg.POSTGRES_PASSWORD);Ssl Mode=Require"
    $pgOrders = "Host=$pgFqdn;Port=5432;Database=ShopDemoOrders;Username=$($cfg.POSTGRES_USER);Password=$($cfg.POSTGRES_PASSWORD);Ssl Mode=Require"
    $pgInventory = "Host=$pgFqdn;Port=5432;Database=ShopDemoInventory;Username=$($cfg.POSTGRES_USER);Password=$($cfg.POSTGRES_PASSWORD);Ssl Mode=Require"

    $commonEhSecrets = @{
        'eh-connection' = $ehConn
    }
    $commonEhEnv = @{
        'ASPNETCORE_ENVIRONMENT'           = 'Production'
        'EventHubs__Enabled'               = 'true'
        'EventHubs__ConnectionString'      = 'secretref:eh-connection'
        'EventHubs__EventHubName'          = $cfg.EVENT_HUB_NAME
    }

    # Catalog - ingress externo
    New-ContainerAppIfMissing -Config $cfg -Acr $acr -AppName 'ca-shopdemo-catalog' `
        -ImageName 'shopdemo-catalog' -Ingress 'external' -MinReplicas 0 -MaxReplicas 2 `
        -Secrets (Merge-Hash $commonEhSecrets, @{ 'pg-catalog-conn' = $pgCatalog }) `
        -EnvVars (Merge-Hash $commonEhEnv, @{ 'ConnectionStrings__DefaultConnection' = 'secretref:pg-catalog-conn' })

    # Inventory - ingress interno + consumer Event Hubs + Storage checkpoints
    New-ContainerAppIfMissing -Config $cfg -Acr $acr -AppName 'ca-shopdemo-inventory' `
        -ImageName 'shopdemo-inventory' -Ingress 'internal' -MinReplicas 1 -MaxReplicas 2 `
        -Secrets (Merge-Hash $commonEhSecrets, @{
            'pg-inventory-conn'  = $pgInventory
            'storage-checkpoint' = $storageConn
        }) `
        -EnvVars (Merge-Hash $commonEhEnv, @{
            'ConnectionStrings__DefaultConnection'         = 'secretref:pg-inventory-conn'
            'EventHubs__ConsumerGroup'                       = 'inventory-service'
            'EventHubs__CheckpointStorageConnectionString' = 'secretref:storage-checkpoint'
            'EventHubs__CheckpointContainerName'           = 'inventory-checkpoints'
        })

    $inventoryFqdn = Get-ContainerAppFqdn -AppName 'ca-shopdemo-inventory' -ResourceGroup $cfg.RESOURCE_GROUP

    # Orders - ingress externo + URL interna Inventory
    New-ContainerAppIfMissing -Config $cfg -Acr $acr -AppName 'ca-shopdemo-orders' `
        -ImageName 'shopdemo-orders' -Ingress 'external' -MinReplicas 0 -MaxReplicas 2 `
        -Secrets (Merge-Hash $commonEhSecrets, @{ 'pg-orders-conn' = $pgOrders }) `
        -EnvVars (Merge-Hash $commonEhEnv, @{
            'ConnectionStrings__DefaultConnection' = 'secretref:pg-orders-conn'
            'InventoryApi__BaseUrl'                = "https://$inventoryFqdn"
        })

    # Analytics - ingress externo + Storage checkpoints
    New-ContainerAppIfMissing -Config $cfg -Acr $acr -AppName 'ca-shopdemo-analytics' `
        -ImageName 'shopdemo-analytics' -Ingress 'external' -MinReplicas 1 -MaxReplicas 1 `
        -Secrets (Merge-Hash $commonEhSecrets, @{ 'storage-checkpoint' = $storageConn }) `
        -EnvVars (Merge-Hash $commonEhEnv, @{
            'EventHubs__ConsumerGroup'                     = 'analytics-service'
            'EventHubs__CheckpointStorageConnectionString' = 'secretref:storage-checkpoint'
            'EventHubs__CheckpointContainerName'           = 'analytics-checkpoints'
        })

    $catalogFqdn = Get-ContainerAppFqdn -AppName 'ca-shopdemo-catalog' -ResourceGroup $cfg.RESOURCE_GROUP
    $analyticsFqdn = Get-ContainerAppFqdn -AppName 'ca-shopdemo-analytics' -ResourceGroup $cfg.RESOURCE_GROUP

    # MCP Gateway - ref: IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md §A3
    New-ContainerAppIfMissing -Config $cfg -Acr $acr -AppName 'ca-shopdemo-mcp' `
        -ImageName 'shopdemo-mcp' -Ingress 'external' -MinReplicas 1 -MaxReplicas 2 `
        -Secrets @{} `
        -EnvVars @{
            'ASPNETCORE_ENVIRONMENT'          = 'Production'
            'ShopDemo__CatalogApiBaseUrl'     = "https://$catalogFqdn"
            'ShopDemo__InventoryApiBaseUrl'   = "https://$inventoryFqdn"
            'ShopDemo__AnalyticsApiBaseUrl'   = "https://$analyticsFqdn"
        }

    Write-Ok "Container Apps desplegadas"
}

# -----------------------------------------------------------------------------
# Paso 7 - AKS (cluster + Ingress + secrets.yaml)
# Ref: IMPLEMENTACION-DESPLIEGUE-AKS.md
# Checkpoints AKS: Azurite in-cluster (k8s/azurite/) - distinto a ACA
# -----------------------------------------------------------------------------
if ($deployAks) {
    Write-Step "Paso 7 - Azure Kubernetes Service ($($cfg.AKS_CLUSTER_NAME))"

    if (-not (Test-AzResourceExists @(
            'aks', 'show', '--resource-group', $cfg.RESOURCE_GROUP, '--name', $cfg.AKS_CLUSTER_NAME
        ))) {
        $aksLocations = @($cfg.AZURE_LOCATION, 'eastus2', 'centralus') | Select-Object -Unique
        $aksCreated = $false
        foreach ($aksLoc in $aksLocations) {
            Write-Info "Intentando AKS en $aksLoc"
            Invoke-AzCli "Crear cluster AKS ($aksLoc)" @(
                'aks', 'create',
                '--resource-group', $cfg.RESOURCE_GROUP,
                '--name', $cfg.AKS_CLUSTER_NAME,
                '--location', $aksLoc,
                '--node-count', $cfg.AKS_NODE_COUNT,
                '--node-vm-size', $cfg.AKS_NODE_VM_SIZE,
                '--attach-acr', $cfg.ACR_NAME,
                '--generate-ssh-keys'
            ) -AllowFailure | Out-Null
            if (Test-AzResourceExists @('aks', 'show', '--resource-group', $cfg.RESOURCE_GROUP, '--name', $cfg.AKS_CLUSTER_NAME)) {
                $aksCreated = $true
                break
            }
            Write-Warn "AKS no creado en $aksLoc"
        }
        if (-not $aksCreated) {
            throw 'No se pudo crear el cluster AKS. Prueba otra region (eastus2, centralus).'
        }
    }
    Write-Ok "Cluster AKS listo"

    Invoke-AzCli 'Credenciales kubectl' @(
        'aks', 'get-credentials',
        '--resource-group', $cfg.RESOURCE_GROUP,
        '--name', $cfg.AKS_CLUSTER_NAME,
        '--overwrite-existing'
    ) | Out-Null

    if (Get-Command helm -ErrorAction SilentlyContinue) {
        $ingressNs = kubectl get namespace ingress-nginx -o name 2>$null
        if (-not $ingressNs) {
            & helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>$null
            & helm repo update 2>$null
            & helm install ingress-nginx ingress-nginx/ingress-nginx `
                --namespace ingress-nginx --create-namespace
            if ($LASTEXITCODE -eq 0) {
                Write-Ok "Ingress NGINX instalado (Helm)"
            }
            else {
                Write-Warn "No se pudo instalar Ingress NGINX - ejecuta Helm manualmente (doc AKS §6)"
            }
        }
        else {
            Write-Ok "Namespace ingress-nginx ya existe"
        }
    }

    New-K8sSecretsFile -RepoRoot $repoRoot `
        -EventHubsConn $ehConn `
        -PostgresPassword $cfg.POSTGRES_PASSWORD `
        -PostgresUser $cfg.POSTGRES_USER

    Write-Info "Siguiente (manual): publicar imágenes en ACR y aplicar manifiestos"
    Write-Info "  cd $repoRoot"
    Write-Info "  # Imágenes ACR ya en k8s/azure/*/deployment.yaml; set-image solo si cambias tag"
    Write-Info "  APPLY_INFRA=true bash .github/scripts/apply-k8s-manifests.sh k8s azure"
    Write-Info "  # O paso a paso: ver k8s/README.md (compartidos + k8s/azure/)"
    Write-Info "Guía: Documentación del Proyecto/despliegue/aks/IMPLEMENTACION-DESPLIEGUE-AKS.md §7-8"
}

# -----------------------------------------------------------------------------
# Resumen
# -----------------------------------------------------------------------------
Write-Step "Resumen y URLs"

if ($deployAca) {
    $apps = @('ca-shopdemo-catalog', 'ca-shopdemo-orders', 'ca-shopdemo-inventory', 'ca-shopdemo-analytics', 'ca-shopdemo-mcp')
    foreach ($app in $apps) {
        if (Test-AzResourceExists @('containerapp', 'show', '--name', $app, '--resource-group', $cfg.RESOURCE_GROUP)) {
            $fq = Get-ContainerAppFqdn -AppName $app -ResourceGroup $cfg.RESOURCE_GROUP
            Write-Host "  $app : https://$fq" -ForegroundColor White
        }
    }
    if ($pgFqdn) {
        Write-Host "  PostgreSQL ACI : $pgFqdn:5432" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "Event Hubs connection string guardada en recursos ACA (secreto eh-connection)." -ForegroundColor DarkGray
Write-Host "Storage (ACA checkpoints): $($cfg.STORAGE_ACCOUNT_NAME)" -ForegroundColor DarkGray
Write-Host "ACR: $($acr.LoginServer)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Validación: Documentación del Proyecto/GUIA-ENDPOINTS.md (sustituir localhost por FQDN ACA)" -ForegroundColor DarkGray
Write-Host "Limpieza:   .\Remove-AzureShopDemo.ps1" -ForegroundColor DarkGray
Write-Host ""
