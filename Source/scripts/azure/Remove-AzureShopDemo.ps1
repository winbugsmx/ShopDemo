<#
.SYNOPSIS
    Elimina todos los recursos de ShopDemo en Azure (Resource Group completo).

.DESCRIPTION
    Ref: Documentación del Proyecto/despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md §16

    ADVERTENCIA: borra el Resource Group configurado en .env.azure, incluyendo
    ACR, Event Hubs, Storage, AKS, Container Apps y PostgreSQL ACI.

.PARAMETER EnvFile
    Ruta al archivo .env.azure.

.PARAMETER Force
    Omite la confirmación interactiva.

.EXAMPLE
    .\Remove-AzureShopDemo.ps1
#>
[CmdletBinding()]
param(
    [string] $EnvFile = (Join-Path $PSScriptRoot '.env.azure'),
    [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Import-EnvFile {
    param([string] $Path)
    if (-not (Test-Path $Path)) {
        throw "No se encontró '$Path'."
    }
    $config = @{}
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq '' -or $line.StartsWith('#')) { return }
        $idx = $line.IndexOf('=')
        if ($idx -lt 1) { return }
        $config[$line.Substring(0, $idx).Trim()] = $line.Substring($idx + 1).Trim()
    }
    return $config
}

$cfg = Import-EnvFile -Path $EnvFile
$rg = $cfg.RESOURCE_GROUP

Write-Host ""
Write-Host "Eliminar Resource Group: $rg" -ForegroundColor Yellow
Write-Host "Esto borra TODOS los recursos del laboratorio ShopDemo en Azure." -ForegroundColor Yellow
Write-Host "Ref: Documentación del Proyecto/despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md §16" -ForegroundColor DarkGray
Write-Host ""

if (-not $Force) {
    $confirm = Read-Host "Escribe el nombre del RG para confirmar ($rg)"
    if ($confirm -ne $rg) {
        Write-Host "Cancelado." -ForegroundColor DarkGray
        exit 0
    }
}

if ($cfg.AZURE_SUBSCRIPTION_ID) {
    az account set --subscription $cfg.AZURE_SUBSCRIPTION_ID | Out-Null
}

Write-Host "Eliminando $rg (puede tardar varios minutos)..." -ForegroundColor Cyan
az group delete --name $rg --yes --no-wait
if ($LASTEXITCODE -ne 0) {
    throw "No se pudo iniciar la eliminación del Resource Group."
}

Write-Host ""
Write-Host "[OK] Eliminación iniciada (--no-wait). Verifica en Portal:" -ForegroundColor Green
Write-Host "     Resource groups -> $rg -> estado 'Deleting'" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Si generaste k8s/secrets.yaml, revísalo antes del próximo commit (no commitear)." -ForegroundColor DarkGray
Write-Host ""
