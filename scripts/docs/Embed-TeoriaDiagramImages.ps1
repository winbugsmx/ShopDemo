<#
.SYNOPSIS
    Convierte imagenes HTML a sintaxis Markdown incrustada (![alt](path)).

.DESCRIPTION
    - <img src="..."> -> ![alt](path)  (visible en vista previa Markdown)
    - Fuente editable: solo enlace al .mermaid (la PNG ya esta incrustada arriba)
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$DocsDir = Join-Path $Root 'docs\teoria-entrevistas'

function Convert-Content {
    param([string]$Text)

    # HTML img -> markdown image
    $Text = [regex]::Replace($Text, '<img\s+src="([^"]+)"\s+alt="([^"]*)"(?:\s+width="[^"]*")?\s*/>', {
        param($m)
        $src = $m.Groups[1].Value
        $alt = $m.Groups[2].Value
        if ([string]::IsNullOrWhiteSpace($alt)) { $alt = 'Diagrama' }
        return "![$alt]($src)"
    })

    # Fuente editable: quitar enlace PNG, dejar solo Mermaid
    $Text = [regex]::Replace($Text,
        '> \*\*Fuente editable:\*\* \[Imagen PNG\]\(\./assets/images/diagrams/[^)]+\.png\) \| \[[^\]]+\]\(\./assets/diagrams/([^)]+\.mermaid)\)',
        {
            param($m)
            $mmd = $m.Groups[1].Value
            return "> *Fuente editable (Mermaid):* [$mmd](./assets/diagrams/$mmd)"
        })

    return $Text
}

$count = 0
Get-ChildItem $DocsDir -Filter '*.md' | Where-Object { $_.Name -ne 'README.md' } | ForEach-Object {
    $original = [System.IO.File]::ReadAllText($_.FullName, [System.Text.UTF8Encoding]::new($false))
    $updated = Convert-Content -Text $original
    if ($updated -ne $original) {
        [System.IO.File]::WriteAllText($_.FullName, $updated, [System.Text.UTF8Encoding]::new($false))
        $imgs = ([regex]::Matches($updated, '!\[[^\]]*\]\(\./assets/')).Count
        Write-Host "[OK] $($_.Name) - imagenes markdown: $imgs" -ForegroundColor Green
        $count++
    }
}

Write-Host ""
Write-Host "Capitulos convertidos: $count" -ForegroundColor Cyan
