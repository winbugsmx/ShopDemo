<#
.SYNOPSIS
    Asegura que cada "Fuente editable" con .mermaid tenga imagen PNG activa encima.

.DESCRIPTION
    - Inserta <img> si falta antes de la linea Fuente editable
    - Actualiza Fuente editable con enlaces a PNG + Mermaid
    - Exporta PNG si no existe
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$DocsDir = Join-Path $Root 'docs\teoria-entrevistas'
$DiagramsDir = Join-Path $DocsDir 'assets\diagrams'
$PngExport = Join-Path $DiagramsDir 'png'
$PngActive = Join-Path $DocsDir 'assets\images\diagrams'
$Mmdc = Join-Path $PSScriptRoot 'node_modules\.bin\mmdc.cmd'

New-Item -ItemType Directory -Force -Path $PngActive | Out-Null

function Ensure-Png {
    param([string]$BaseName)
    $mmd = Join-Path $DiagramsDir ($BaseName + '.mermaid')
    $pngExport = Join-Path $PngExport ($BaseName + '.png')
    $pngActive = Join-Path $PngActive ($BaseName + '.png')
    if (-not (Test-Path $mmd)) { return $false }
    if (-not (Test-Path $pngExport)) {
        if (Test-Path $Mmdc) {
            & $Mmdc -i $mmd -o $pngExport -b white 2>&1 | Out-Null
        }
    }
    if (Test-Path $pngExport) {
        Copy-Item $pngExport $pngActive -Force
        return $true
    }
    return $false
}

function Get-BaseFromFuenteLine {
    param([string]$Line)
    if ($Line -match 'assets/diagrams/([^\]/\s]+\.mermaid)') {
        return [System.IO.Path]::GetFileNameWithoutExtension($Matches[1])
    }
    return $null
}

$pattern = '(?i)Fuente editable[^:]*:\s*\[([^\]]*)\]\(\./assets/diagrams/([^)]+\.mermaid)\)'
$fixed = 0
$updated = 0

Get-ChildItem $DocsDir -Filter '*.md' | Where-Object { $_.Name -ne 'README.md' } | ForEach-Object {
    $lines = [System.Collections.Generic.List[string]]@(Get-Content $_.FullName -Encoding UTF8)
    $changed = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -notmatch 'Fuente editable') { continue }
        if ($lines[$i] -notmatch 'assets/diagrams/.*\.mermaid') { continue }

        $base = Get-BaseFromFuenteLine -Line $lines[$i]
        if (-not $base) { continue }

        Ensure-Png -BaseName $base | Out-Null
        $imgSrc = "./assets/images/diagrams/$base.png"
        $imgMd = "![Diagrama: $base]($imgSrc)"
        $mmdLink = "./assets/diagrams/$base.mermaid"
        $newFuente = "> *Fuente editable (Mermaid):* [$base.mermaid]($mmdLink)"

        # Insertar imagen si la linea anterior no es markdown image con este base
        $prevIdx = $i - 1
        while ($prevIdx -ge 0 -and $lines[$prevIdx].Trim() -eq '') { $prevIdx-- }
        $hasImg = ($prevIdx -ge 0) -and ($lines[$prevIdx] -match '!\[' -and $lines[$prevIdx] -match [regex]::Escape($base))

        if (-not $hasImg) {
            $lines.Insert($i, '')
            $lines.Insert($i, $imgMd)
            $i += 2
            $fixed++
            $changed = $true
        }

        if ($lines[$i] -ne $newFuente) {
            $lines[$i] = $newFuente
            $updated++
            $changed = $true
        }
    }

    if ($changed) {
        [System.IO.File]::WriteAllLines($_.FullName, $lines, [System.Text.UTF8Encoding]::new($false))
        Write-Host "[OK] $($_.Name)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Imagenes insertadas: $fixed | Fuentes actualizadas: $updated" -ForegroundColor Cyan
