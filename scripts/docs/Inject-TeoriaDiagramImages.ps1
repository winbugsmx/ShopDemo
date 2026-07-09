<#
.SYNOPSIS
    Inserta referencias PNG antes de bloques Mermaid en la documentación de teoría.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$DocsDir = Join-Path $Root 'docs\teoria-entrevistas'
$DiagramsDir = Join-Path $DocsDir 'assets\diagrams'
$PngDir = Join-Path $DiagramsDir 'png'
$EmbeddedDir = Join-Path $DiagramsDir 'embedded'
$Mmdc = Join-Path $PSScriptRoot 'node_modules\.bin\mmdc.cmd'

New-Item -ItemType Directory -Force -Path $EmbeddedDir | Out-Null

function Export-MermaidToPng {
    param([string]$MmdPath, [string]$PngPath)
    if (Test-Path $PngPath) { return $true }
    if (-not (Test-Path $MmdPath)) { return $false }
    if (Test-Path $Mmdc) {
        & $Mmdc -i $MmdPath -o $PngPath -b white 2>&1 | Out-Null
    }
    else {
        npx -p @mermaid-js/mermaid-cli mmdc -i $MmdPath -o $PngPath -b white 2>&1 | Out-Null
    }
    return Test-Path $PngPath
}

function Get-Hash12 {
    param([string]$Text)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    return ([BitConverter]::ToString($hash) -replace '-', '').Substring(0, 12).ToLower()
}

function Process-MarkdownFile {
    param([string]$FilePath)
    $lines = Get-Content -Path $FilePath -Encoding UTF8
    $out = New-Object System.Collections.Generic.List[string]
    $i = 0
    $injected = 0

    while ($i -lt $lines.Count) {
        $line = $lines[$i]

        if ($line -eq '```mermaid') {
            $body = New-Object System.Collections.Generic.List[string]
            $i++
            while ($i -lt $lines.Count -and $lines[$i] -ne '```') {
                $body.Add($lines[$i])
                $i++
            }

            $baseName = $null
            $j = $i + 1
            while ($j -lt $lines.Count -and $lines[$j].Trim() -eq '') { $j++ }
            if ($j -lt $lines.Count -and $lines[$j] -match 'Fuente editable:.*assets/diagrams/([^/\]]+\.mermaid)') {
                $baseName = [System.IO.Path]::GetFileNameWithoutExtension($Matches[1])
            }

            if (-not $baseName) {
                $hash = Get-Hash12 -Text ($body -join "`n")
                $baseName = "embedded-$hash"
                $mmdPath = Join-Path $EmbeddedDir ($baseName + '.mermaid')
                if (-not (Test-Path $mmdPath)) {
                    Set-Content -Path $mmdPath -Value ($body -join "`n") -Encoding UTF8
                }
            }

            $pngRel = "./assets/diagrams/png/$baseName.png"
            $pngFull = Join-Path $PngDir ($baseName + '.png')
            $mmdSource = Join-Path $DiagramsDir ($baseName + '.mermaid')
            if (-not (Test-Path $mmdSource) -and (Test-Path (Join-Path $EmbeddedDir ($baseName + '.mermaid')))) {
                $mmdSource = Join-Path $EmbeddedDir ($baseName + '.mermaid')
            }
            Export-MermaidToPng -MmdPath $mmdSource -PngPath $pngFull | Out-Null

            $prev = if ($out.Count -gt 0) { $out[$out.Count - 1] } else { '' }
            if ($prev -notmatch '!\[.*\]\(\./assets/diagrams/png/' -and (Test-Path $pngFull)) {
                $out.Add("![Diagrama: $baseName]($pngRel)")
                $out.Add('')
                $injected++
            }

            $out.Add('```mermaid')
            foreach ($b in $body) { $out.Add($b) }
            $out.Add('```')

            if ($i -lt $lines.Count) { $i++ }
            continue
        }

        $out.Add($line)
        $i++
    }

    [System.IO.File]::WriteAllLines($FilePath, $out, [System.Text.UTF8Encoding]::new($false))
    return $injected
}

$total = 0
Get-ChildItem -Path $DocsDir -Filter '*.md' | Where-Object { $_.Name -ne 'README.md' } | ForEach-Object {
    $n = Process-MarkdownFile -FilePath $_.FullName
    if ($n -gt 0) {
        Write-Host "[OK] $($_.Name) - $n imagenes" -ForegroundColor Green
        $total += $n
    }
}

Write-Host ""
Write-Host "Total imagenes insertadas: $total" -ForegroundColor Cyan
