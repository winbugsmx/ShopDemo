# Sync ShopDemo deployment secrets to GitHub (repo + environments azure/aws).
# Requires: gh auth login, az/aws CLI for optional value resolution.
# Usage: .\scripts\github\Setup-GitHubSecrets.ps1 [-Repo winbugsmx/ShopDemo] [-SkipAwsCredentials]

[CmdletBinding()]
param(
    [string] $Repo = 'winbugsmx/ShopDemo',
    [switch] $SkipAwsCredentials,
    [string] $AzureCredentialsFile = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

function Write-Step { param([string]$Message) Write-Host "`n==> $Message" -ForegroundColor Cyan }
function Write-Ok { param([string]$Message) Write-Host "    [OK] $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "    [AVISO] $Message" -ForegroundColor Yellow }

function Set-GhSecret {
    param(
        [string]$Name,
        [string]$Value,
        [string]$Environment = ''
    )
    if ([string]::IsNullOrWhiteSpace($Value)) {
        Write-Warn "Omitido '$Name' (valor vacío)"
        return
    }
    $args = @('secret', 'set', $Name, '--repo', $Repo, '--body', $Value)
    if ($Environment) { $args += @('--env', $Environment) }
    & gh @args | Out-Null
    $scope = if ($Environment) { "env:$Environment" } else { 'repo' }
    Write-Ok "$Name ($scope)"
}

function Get-AzurePgConn {
    param([string]$Database)
    $pgHost = az container show -g rg-shopdemo-lab -n aci-shopdemo-postgres --query ipAddress.fqdn -o tsv 2>$null
    if (-not $pgHost) { return $null }
    return "Host=$pgHost;Port=5432;Database=$Database;Username=ShopDemo;Password=ShopDemo123!;Ssl Mode=Require"
}

function Get-ContainerAppFqdn {
    param([string]$AppName)
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    $fqdn = az containerapp show -g rg-shopdemo-lab -n $AppName --query properties.configuration.ingress.fqdn -o tsv 2>$null
    $ErrorActionPreference = $prevEap
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($fqdn)) { return $null }
    return $fqdn.Trim()
}

Write-Step 'Comprobar gh autenticado'
$auth = & gh auth status 2>&1
if ($LASTEXITCODE -ne 0) { throw "Ejecuta: gh auth login`n$auth" }
Write-Ok "Autenticado en GitHub"

Write-Step 'Crear environments azure y aws'
& gh api --method PUT "repos/$Repo/environments/azure" | Out-Null
& gh api --method PUT "repos/$Repo/environments/aws" | Out-Null
Write-Ok 'Environments azure, aws'

# --- Shared repo secrets ---
$awsEnv = Join-Path $RepoRoot 'scripts\aws\.env.aws'
$ehConn = $null
$ehName = 'shopdemo-events'
if (Test-Path $awsEnv) {
    Get-Content $awsEnv | ForEach-Object {
        if ($_ -match '^EVENT_HUBS_CONNECTION_STRING=(.+)$') { $ehConn = $Matches[1].Trim() }
        if ($_ -match '^EVENT_HUB_NAME=(.+)$') { $ehName = $Matches[1].Trim() }
    }
}

Write-Step 'Secrets compartidos (repositorio)'
Set-GhSecret -Name 'EVENT_HUBS_CONNECTION_STRING' -Value $ehConn
Set-GhSecret -Name 'EVENT_HUB_NAME' -Value $ehName

# --- Azure environment ---
Write-Step 'Secrets environment: azure'
Set-GhSecret -Environment 'azure' -Name 'ACR_NAME' -Value 'acrshopdemolab01'
Set-GhSecret -Environment 'azure' -Name 'AZURE_RG' -Value 'rg-shopdemo-lab'
Set-GhSecret -Environment 'azure' -Name 'ACA_ENV' -Value 'aca-env-shopdemo'

if ($AzureCredentialsFile -and (Test-Path $AzureCredentialsFile)) {
    $creds = Get-Content -Raw -Path $AzureCredentialsFile
    Set-GhSecret -Environment 'azure' -Name 'AZURE_CREDENTIALS' -Value $creds
}
else {
    Write-Warn 'AZURE_CREDENTIALS omitido. Pásalo con -AzureCredentialsFile path\to\sp.json'
    Write-Warn 'Generar: az ad sp create-for-rbac --name github-shopdemo --role contributor --scopes /subscriptions/<id>/resourceGroups/rg-shopdemo-lab --sdk-auth > azure-sp.json'
}

Set-GhSecret -Environment 'azure' -Name 'PG_CATALOG_CONN' -Value (Get-AzurePgConn -Database 'ShopDemoCatalog')
Set-GhSecret -Environment 'azure' -Name 'PG_ORDERS_CONN' -Value (Get-AzurePgConn -Database 'ShopDemoOrders')
Set-GhSecret -Environment 'azure' -Name 'PG_INVENTORY_CONN' -Value (Get-AzurePgConn -Database 'ShopDemoInventory')

$storageConn = az storage account show-connection-string -g rg-shopdemo-lab -n shopdemochecklab01 --query connectionString -o tsv 2>$null
Set-GhSecret -Environment 'azure' -Name 'STORAGE_CHECKPOINT_CONN' -Value $storageConn

$invFqdn = Get-ContainerAppFqdn -AppName 'ca-shopdemo-inventory'
$catFqdn = Get-ContainerAppFqdn -AppName 'ca-shopdemo-catalog'
$anaFqdn = Get-ContainerAppFqdn -AppName 'ca-shopdemo-analytics'

if ($invFqdn) {
    Set-GhSecret -Environment 'azure' -Name 'INVENTORY_API_BASE_URL' -Value "https://$invFqdn"
    Set-GhSecret -Environment 'azure' -Name 'MCP_INVENTORY_URL' -Value "https://$invFqdn"
}
else { Write-Warn 'Container Apps sin FQDN — ejecuta Deploy-AzureShopDemo.ps1 -Mode ACA y vuelve a correr este script' }

if ($catFqdn) { Set-GhSecret -Environment 'azure' -Name 'MCP_CATALOG_URL' -Value "https://$catFqdn" }
if ($anaFqdn) { Set-GhSecret -Environment 'azure' -Name 'MCP_ANALYTICS_URL' -Value "https://$anaFqdn" }

# --- AWS environment ---
Write-Step 'Secrets environment: aws'
Set-GhSecret -Environment 'aws' -Name 'AWS_REGION' -Value 'us-east-2'
Set-GhSecret -Environment 'aws' -Name 'ECS_CLUSTER' -Value 'shopdemo-cluster'
Set-GhSecret -Environment 'aws' -Name 'LAB_PREFIX' -Value 'shopdemo'

if (-not $SkipAwsCredentials) {
    $keyId = aws configure get aws_access_key_id 2>$null
    $keySecret = aws configure get aws_secret_access_key 2>$null
    Set-GhSecret -Environment 'aws' -Name 'AWS_ACCESS_KEY_ID' -Value $keyId
    Set-GhSecret -Environment 'aws' -Name 'AWS_SECRET_ACCESS_KEY' -Value $keySecret
}
else {
    Write-Warn 'AWS keys omitidas (-SkipAwsCredentials)'
}

$ssmParams = aws ssm get-parameters `
    --names '/shopdemo/pg-catalog' '/shopdemo/pg-orders' '/shopdemo/pg-inventory' '/shopdemo/azurite-checkpoint' `
    --with-decryption --region us-east-2 --output json 2>$null | ConvertFrom-Json

if ($ssmParams.Parameters) {
    foreach ($p in $ssmParams.Parameters) {
        switch -Regex ($p.Name) {
            'pg-catalog$' { Set-GhSecret -Environment 'aws' -Name 'PG_CATALOG_CONN' -Value $p.Value }
            'pg-orders$' { Set-GhSecret -Environment 'aws' -Name 'PG_ORDERS_CONN' -Value $p.Value }
            'pg-inventory$' { Set-GhSecret -Environment 'aws' -Name 'PG_INVENTORY_CONN' -Value $p.Value }
            'azurite-checkpoint$' { Set-GhSecret -Environment 'aws' -Name 'AZURITE_CHECKPOINT_CONN' -Value $p.Value }
        }
    }
}

$statePath = Join-Path $RepoRoot 'scripts\aws\.deploy-state.json'
if (Test-Path $statePath) {
    $state = Get-Content $statePath | ConvertFrom-Json
    Set-GhSecret -Environment 'aws' -Name 'INVENTORY_API_BASE_URL' -Value $state.inventoryUrl
    Set-GhSecret -Environment 'aws' -Name 'MCP_INVENTORY_URL' -Value $state.inventoryUrl
    if ($state.albDns.catalog) {
        Set-GhSecret -Environment 'aws' -Name 'MCP_CATALOG_URL' -Value "http://$($state.albDns.catalog)"
    }
    if ($state.albDns.analytics) {
        Set-GhSecret -Environment 'aws' -Name 'MCP_ANALYTICS_URL' -Value "http://$($state.albDns.analytics)"
    }
}

Write-Step 'Listado de secrets configurados'
& gh secret list --repo $Repo
Write-Host ''
& gh secret list --repo $Repo --env azure
Write-Host ''
& gh secret list --repo $Repo --env aws
Write-Host ''
Write-Ok "Configuración completada en https://github.com/$Repo/settings/secrets/actions"
