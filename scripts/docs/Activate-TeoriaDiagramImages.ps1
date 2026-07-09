<#
.SYNOPSIS
    Deja solo imagenes PNG activas en la documentacion de teoria; elimina bloques Mermaid del markdown.

.DESCRIPTION
    1. Copia PNG a assets/images/diagrams/ (misma convencion que infografias que si cargan)
    2. Reemplaza referencias a assets/diagrams/png/ por assets/images/diagrams/
    3. Elimina bloques ```mermaid ... ```
    4. Convierte markdown image a HTML img para mejor compatibilidad con Cursor
#>
[CmdletBinding()]
param(
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$DocsDir = Join-Path $Root 'docs\teoria-entrevistas'
$PngSource = Join-Path $DocsDir 'assets\diagrams\png'
$PngTarget = Join-Path $DocsDir 'assets\images\diagrams'
$Mmdc = Join-Path $PSScriptRoot 'node_modules\.bin\mmdc.cmd'

New-Item -ItemType Directory -Force -Path $PngTarget | Out-Null

# Copiar/sincronizar PNG
if (Test-Path $PngSource) {
    Get-ChildItem $PngSource -Filter '*.png' | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $PngTarget $_.Name) -Force
    }
    Write-Host "PNG sincronizados: $((Get-ChildItem $PngTarget -Filter '*.png').Count)" -ForegroundColor Cyan
}

function Remove-MermaidBlocks {
    param([string]$Text)
    return [regex]::Replace($Text, '(?ms)^```mermaid\r?\n.*?\r?\n```\r?\n?', '')
}

function Convert-ImageRefs {
    param([string]$Text)
    # assets/diagrams/png -> assets/images/diagrams
    $Text = $Text -replace '\./assets/diagrams/png/', './assets/images/diagrams/'
    $Text = $Text -replace 'assets/diagrams/png/', 'assets/images/diagrams/'

    # Markdown image -> mantener sintaxis incrustada (mejor en vista previa Cursor)
    # Normalizar HTML img legacy a markdown si queda alguno
    $Text = [regex]::Replace($Text, '<img\s+src="([^"]+)"\s+alt="([^"]*)"(?:\s+width="[^"]*")?\s*/>', {
        param($m)
        $src = $m.Groups[1].Value
        $alt = $m.Groups[2].Value -replace '"', ''
        if ($alt -match '^Diagrama:\s*embedded-') { $alt = 'Diagrama' }
        if ([string]::IsNullOrWhiteSpace($alt)) { $alt = 'Diagrama' }
        return "![$alt]($src)"
    })

    return $Text
}

$mdFiles = Get-ChildItem $DocsDir -Filter '*.md' | Where-Object { $_.Name -ne 'README.md' }
$total = 0

foreach ($file in $mdFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $original = $content
    $content = Remove-MermaidBlocks -Text $content
    $content = Convert-ImageRefs -Text $content
    # Limpiar lineas vacias triples
    $content = [regex]::Replace($content, '(\r?\n){3,}', "`n`n")

    if ($content -ne $original) {
        if (-not $WhatIf) {
            [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.UTF8Encoding]::new($false))
        }
        $removed = ([regex]::Matches($original, '(?ms)^```mermaid')).Count
        Write-Host "[OK] $($file.Name) - bloques mermaid eliminados: $removed" -ForegroundColor Green
        $total += $removed
    }
}

Write-Host ""
Write-Host "Total bloques mermaid eliminados: $total" -ForegroundColor Cyan
Write-Host "Imagenes activas en: assets/images/diagrams/" -ForegroundColor Cyan

# Complementar lineas Fuente editable con PNG + enlaces
$complement = Join-Path $PSScriptRoot 'Complement-FuenteEditableImages.ps1'
$embed = Join-Path $PSScriptRoot 'Embed-TeoriaDiagramImages.ps1'
if (-not $WhatIf) {
    if (Test-Path $complement) {
        Write-Host ""
        Write-Host "Complementando Fuente editable con imagenes PNG..." -ForegroundColor Cyan
        & $complement
    }
    if (Test-Path $embed) {
        Write-Host ""
        Write-Host "Convirtiendo a imagenes Markdown incrustadas..." -ForegroundColor Cyan
        & $embed
    }
}
