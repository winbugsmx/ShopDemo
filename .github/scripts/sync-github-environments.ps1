<#
.SYNOPSIS
    Sincroniza GitHub Environments y secrets de ShopDemo vía gh CLI.

.DESCRIPTION
    Crea environments si faltan y escribe secrets desde:
      - scripts/azure/.env.azure
      - scripts/aws/.env.aws
      - k8s/secrets.example.yaml (PG + Azurite in-cluster)
      - Azure CLI (FQDNs MCP/Inventory en environment azure, si az está logueado)

    NO imprime valores secretos. Usar -WhatIf para revisar acciones.

.PARAMETER Target
    azure | azure-aks | aws | aws-eks | all (default)

.PARAMETER SkipSensitive
    Omite connection strings, credenciales AWS/Azure y passwords.

.PARAMETER AzureCredentialsFile
    Ruta a JSON sdk-auth para AZURE_CREDENTIALS (environments azure y azure-aks).

.EXAMPLE
    .\sync-github-environments.ps1 -WhatIf
    .\sync-github-environments.ps1 -Target azure-aks
    .\sync-github-environments.ps1 -AzureCredentialsFile C:\secrets\github-sp.json
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('all', 'azure', 'azure-aks', 'aws', 'aws-eks')]
    [string] $Target = 'all',

    [switch] $SkipSensitive,

    [string] $AzureCredentialsFile = '',

    [string] $Repo = 'winbugsmx/ShopDemo'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = Resolve-Path (Join-Path $PSScriptRoot '..\..')

function Import-DotEnv {
    param([string] $Path)
    $map = @{}
    if (-not (Test-Path $Path)) { return $map }
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq '' -or $line.StartsWith('#')) { return }
        $idx = $line.IndexOf('=')
        if ($idx -lt 1) { return }
        $key = $line.Substring(0, $idx).Trim()
        $val = $line.Substring($idx + 1).Trim()
        $map[$key] = $val
    }
    return $map
}

function Get-K8sLabSecrets {
    $example = Join-Path $Root 'k8s\secrets.example.yaml'
    if (-not (Test-Path $example)) { return @{} }
    $content = Get-Content $example -Raw
    $result = @{}
    foreach ($name in @('PG_CATALOG_CONN', 'PG_ORDERS_CONN', 'PG_INVENTORY_CONN', 'AZURITE_CHECKPOINT_CONN')) {
        if ($content -match "(?m)^\s+$name`: `"([^`"]+)`"") {
            $result[$name] = $Matches[1]
        }
    }
    foreach ($name in @('POSTGRES_USER', 'POSTGRES_PASSWORD')) {
        if ($content -match "(?m)^\s+$name`: (.+)$") {
            $result[$name] = $Matches[1].Trim()
        }
    }
    return $result
}

function Get-AwsCredentialsFromProfile {
    param([string] $Profile = '')
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) { return @{} }
    $args = @('configure', 'get', 'aws_access_key_id')
    if ($Profile) { $args += @('--profile', $Profile) }
    $id = & aws @args 2>$null
    $args = @('configure', 'get', 'aws_secret_access_key')
    if ($Profile) { $args += @('--profile', $Profile) }
    $secret = & aws @args 2>$null
    $result = @{}
    if ($id) { $result['AWS_ACCESS_KEY_ID'] = $id.Trim() }
    if ($secret) { $result['AWS_SECRET_ACCESS_KEY'] = $secret.Trim() }
    return $result
}
    param([string] $Name)
    if ($PSCmdlet.ShouldProcess($Name, 'Create GitHub environment')) {
        gh api --method PUT "repos/$Repo/environments/$Name" | Out-Null
        Write-Host "Environment OK: $Name" -ForegroundColor Green
    }
}

function Set-GhSecret {
    param(
        [string] $Name,
        [string] $Value,
        [string] $Environment = ''
    )
    if ([string]::IsNullOrWhiteSpace($Value)) {
        Write-Host "  SKIP $Name (sin valor local)" -ForegroundColor DarkYellow
        return
    }
    $scope = if ($Environment) { "env:$Environment" } else { 'repo' }
    if ($PSCmdlet.ShouldProcess("$scope/$Name", 'gh secret set')) {
        if ($Environment) {
            $Value | gh secret set $Name --env $Environment
        }
        else {
            $Value | gh secret set $Name
        }
        Write-Host "  SET $scope/$Name" -ForegroundColor Cyan
    }
}

function Sync-AzureAca {
    param($AzureEnv, [hashtable] $K8s)
    Write-Host "`n=== azure (ACA) ===" -ForegroundColor White
    Ensure-Environment -Name 'azure'

    Set-GhSecret -Name 'ACR_NAME' -Value $AzureEnv['ACR_NAME'] -Environment 'azure'
    Set-GhSecret -Name 'AZURE_RG' -Value $AzureEnv['RESOURCE_GROUP'] -Environment 'azure'
    Set-GhSecret -Name 'ACA_ENV' -Value $AzureEnv['ACA_ENV_NAME'] -Environment 'azure'

    if (-not $SkipSensitive -and $AzureCredentialsFile -and (Test-Path $AzureCredentialsFile)) {
        $json = Get-Content $AzureCredentialsFile -Raw
        Set-GhSecret -Name 'AZURE_CREDENTIALS' -Value $json -Environment 'azure'
        Set-GhSecret -Name 'AZURE_CREDENTIALS' -Value $json -Environment 'azure-aks'
    }

    # FQDNs vía Azure CLI (no secretos de GitHub)
    $rg = $AzureEnv['RESOURCE_GROUP']
    if ($rg -and (Get-Command az -ErrorAction SilentlyContinue)) {
        try {
            $apps = @{
                MCP_CATALOG_URL   = 'ca-shopdemo-catalog'
                MCP_INVENTORY_URL = 'ca-shopdemo-inventory'
                MCP_ANALYTICS_URL = 'ca-shopdemo-analytics'
            }
            foreach ($secret in $apps.Keys) {
                $app = $apps[$secret]
                $fqdn = az containerapp show -n $app -g $rg --query 'properties.configuration.ingress.fqdn' -o tsv 2>$null
                if ($fqdn) {
                    Set-GhSecret -Name $secret -Value "https://$fqdn" -Environment 'azure'
                }
            }
            $invFqdn = az containerapp show -n 'ca-shopdemo-inventory' -g $rg --query 'properties.configuration.ingress.fqdn' -o tsv 2>$null
            if ($invFqdn) {
                Set-GhSecret -Name 'INVENTORY_API_BASE_URL' -Value "https://$invFqdn" -Environment 'azure'
            }
        }
        catch {
            Write-Host "  Azure CLI: no se pudieron leer FQDNs ($($_.Exception.Message))" -ForegroundColor DarkYellow
        }
    }
}

function Sync-AzureAks {
    param($AzureEnv, $AwsEnv, [hashtable] $K8s)
    Write-Host "`n=== azure-aks ===" -ForegroundColor White
    Ensure-Environment -Name 'azure-aks'

    Set-GhSecret -Name 'ACR_NAME' -Value $AzureEnv['ACR_NAME'] -Environment 'azure-aks'
    Set-GhSecret -Name 'AZURE_RG' -Value $AzureEnv['RESOURCE_GROUP'] -Environment 'azure-aks'
    Set-GhSecret -Name 'AKS_CLUSTER_NAME' -Value $AzureEnv['AKS_CLUSTER_NAME'] -Environment 'azure-aks'
    Set-GhSecret -Name 'K8S_NAMESPACE' -Value 'shopdemo' -Environment 'azure-aks'

    if (-not $SkipSensitive -and $AzureCredentialsFile -and (Test-Path $AzureCredentialsFile)) {
        $json = Get-Content $AzureCredentialsFile -Raw
        Set-GhSecret -Name 'AZURE_CREDENTIALS' -Value $json -Environment 'azure-aks'
    }

    if (-not $SkipSensitive) {
        Set-GhSecret -Name 'EVENT_HUBS_CONNECTION_STRING' -Value $AwsEnv['EVENT_HUBS_CONNECTION_STRING'] -Environment 'azure-aks'
        foreach ($k in @('PG_CATALOG_CONN', 'PG_ORDERS_CONN', 'PG_INVENTORY_CONN', 'AZURITE_CHECKPOINT_CONN', 'POSTGRES_USER', 'POSTGRES_PASSWORD')) {
            Set-GhSecret -Name $k -Value $K8s[$k] -Environment 'azure-aks'
        }
    }
}

function Sync-AwsEcs {
    param($AwsEnv, [hashtable] $K8s)
    Write-Host "`n=== aws (ECS) ===" -ForegroundColor White
    Ensure-Environment -Name 'aws'

    Set-GhSecret -Name 'AWS_REGION' -Value $AwsEnv['AWS_REGION'] -Environment 'aws'
    Set-GhSecret -Name 'ECS_CLUSTER' -Value $AwsEnv['ECS_CLUSTER_NAME'] -Environment 'aws'
    Set-GhSecret -Name 'LAB_PREFIX' -Value $AwsEnv['LAB_PREFIX'] -Environment 'aws'
    Set-GhSecret -Name 'EKS_CLUSTER_NAME' -Value $AwsEnv['EKS_CLUSTER_NAME'] -Environment 'aws'

    if (-not $SkipSensitive) {
        Set-GhSecret -Name 'EVENT_HUBS_CONNECTION_STRING' -Value $AwsEnv['EVENT_HUBS_CONNECTION_STRING'] -Environment 'aws'
        Set-GhSecret -Name 'EVENT_HUB_NAME' -Value $AwsEnv['EVENT_HUB_NAME'] -Environment 'aws'
    }
}

function Sync-AwsEks {
    param($AwsEnv, [hashtable] $K8s)
    Write-Host "`n=== aws-eks ===" -ForegroundColor White
    Ensure-Environment -Name 'aws-eks'

    Set-GhSecret -Name 'AWS_REGION' -Value $AwsEnv['AWS_REGION'] -Environment 'aws-eks'
    Set-GhSecret -Name 'EKS_CLUSTER_NAME' -Value $AwsEnv['EKS_CLUSTER_NAME'] -Environment 'aws-eks'
    Set-GhSecret -Name 'K8S_NAMESPACE' -Value 'shopdemo' -Environment 'aws-eks'

    if (-not $SkipSensitive) {
        $profile = $AwsEnv['AWS_PROFILE']
        $awsCreds = Get-AwsCredentialsFromProfile -Profile $profile
        Set-GhSecret -Name 'AWS_ACCESS_KEY_ID' -Value $awsCreds['AWS_ACCESS_KEY_ID'] -Environment 'aws-eks'
        Set-GhSecret -Name 'AWS_SECRET_ACCESS_KEY' -Value $awsCreds['AWS_SECRET_ACCESS_KEY'] -Environment 'aws-eks'
        Set-GhSecret -Name 'EVENT_HUBS_CONNECTION_STRING' -Value $AwsEnv['EVENT_HUBS_CONNECTION_STRING'] -Environment 'aws-eks'
        foreach ($k in @('PG_CATALOG_CONN', 'PG_ORDERS_CONN', 'PG_INVENTORY_CONN', 'AZURITE_CHECKPOINT_CONN', 'POSTGRES_USER', 'POSTGRES_PASSWORD')) {
            Set-GhSecret -Name $k -Value $K8s[$k] -Environment 'aws-eks'
        }
    }
}

function Sync-RepoSecrets {
    param($AwsEnv)
    Write-Host "`n=== repository ===" -ForegroundColor White
    if (-not $SkipSensitive) {
        Set-GhSecret -Name 'EVENT_HUBS_CONNECTION_STRING' -Value $AwsEnv['EVENT_HUBS_CONNECTION_STRING']
        Set-GhSecret -Name 'EVENT_HUB_NAME' -Value $AwsEnv['EVENT_HUB_NAME']
    }
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw 'gh CLI no encontrado. Instala https://cli.github.com/'
}

$azureEnv = Import-DotEnv (Join-Path $Root 'scripts\azure\.env.azure')
$awsEnv = Import-DotEnv (Join-Path $Root 'scripts\aws\.env.aws')
$k8s = Get-K8sLabSecrets

Write-Host "Repo: $Repo | Target: $Target | SkipSensitive: $SkipSensitive" -ForegroundColor Gray

switch ($Target) {
    'all' {
        Sync-RepoSecrets -AwsEnv $awsEnv
        Sync-AzureAca -AzureEnv $azureEnv -K8s $k8s
        Sync-AzureAks -AzureEnv $azureEnv -AwsEnv $awsEnv -K8s $k8s
        Sync-AwsEcs -AwsEnv $awsEnv -K8s $k8s
        Sync-AwsEks -AwsEnv $awsEnv -K8s $k8s
    }
    'azure' { Sync-AzureAca -AzureEnv $azureEnv -K8s $k8s }
    'azure-aks' { Sync-AzureAks -AzureEnv $azureEnv -AwsEnv $awsEnv -K8s $k8s }
    'aws' { Sync-AwsEcs -AwsEnv $awsEnv -K8s $k8s }
    'aws-eks' { Sync-AwsEks -AwsEnv $awsEnv -K8s $k8s }
}

Write-Host "`nListo. Verifica con: gh secret list --env <nombre>" -ForegroundColor Green
