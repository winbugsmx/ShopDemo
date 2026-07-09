<#
.SYNOPSIS
    Exporta todos los .mermaid de teoria-entrevistas a PNG para visualización en Cursor/VS Code.

.DESCRIPTION
    Usa @mermaid-js/mermaid-cli (mmdc). Los PNG se guardan en assets/diagrams/png/.
    Ejecutar tras editar archivos .mermaid o antes de commitear documentación.

.EXAMPLE
    .\Export-TeoriaDiagrams.ps1
    .\Export-TeoriaDiagrams.ps1 -InjectMarkdown
#>
[CmdletBinding()]
param(
    [switch]$InjectMarkdown
)

$ErrorActionPreference = 'Continue'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$DiagramsDir = Join-Path $Root 'docs\teoria-entrevistas\assets\diagrams'
$PngDir = Join-Path $DiagramsDir 'png'
$DocsDir = Join-Path $Root 'docs\teoria-entrevistas'

New-Item -ItemType Directory -Force -Path $PngDir | Out-Null

$Mmdc = Join-Path $PSScriptRoot 'node_modules\.bin\mmdc.cmd'
if (-not (Test-Path $Mmdc)) {
    $Mmdc = 'mmdc'
}

function Invoke-Mmdc {
    param([string]$InputPath, [string]$OutputPath)
    if (Test-Path (Join-Path $PSScriptRoot 'node_modules\.bin\mmdc.cmd')) {
        & (Join-Path $PSScriptRoot 'node_modules\.bin\mmdc.cmd') -i $InputPath -o $OutputPath -b white 2>&1 | Out-Null
    }
    else {
        npx -p @mermaid-js/mermaid-cli mmdc -i $InputPath -o $OutputPath -b white 2>&1 | Out-Null
    }
    return ($LASTEXITCODE -eq 0) -and (Test-Path $OutputPath)
}

Write-Host "=== Exportando diagramas Mermaid a PNG ===" -ForegroundColor Cyan
$ok = 0
$fail = 0
$failed = @()

Get-ChildItem -Path $DiagramsDir -Filter '*.mermaid' -File | Sort-Object Name | ForEach-Object {
    $pngPath = Join-Path $PngDir ($_.BaseName + '.png')
    Write-Host "  $($_.Name) -> png\$($_.BaseName).png" -ForegroundColor DarkGray
    if (Invoke-Mmdc -InputPath $_.FullName -OutputPath $pngPath) {
        $ok++
    }
    else {
        $fail++
        $failed += $_.Name
        Write-Host "    [FALLO] $($_.Name)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Exportados: $ok | Fallidos: $fail" -ForegroundColor $(if ($fail -eq 0) { 'Green' } else { 'Yellow' })

if ($InjectMarkdown) {
    & (Join-Path $PSScriptRoot 'Activate-TeoriaDiagramImages.ps1')
}

if ($failed.Count -gt 0) {
    Write-Host "Revisa sintaxis en:" -ForegroundColor Yellow
    $failed | ForEach-Object { Write-Host "  - $_" }
}
