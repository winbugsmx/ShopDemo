param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

$utf8 = New-Object System.Text.UTF8Encoding $false
$changed = 0

Get-ChildItem -LiteralPath $RepoRoot -Recurse -File | Where-Object {
    $_.Extension -in @('.md', '.yml', '.yaml', '.ps1', '.py', '.mdc', '.json', '.html') -and
    $_.FullName -notmatch '\\node_modules\\|\\bin\\|\\obj\\|\\.vs\\|\\\.git\\'
} | ForEach-Object {
    $c = [IO.File]::ReadAllText($_.FullName)
    if (-not $c.Contains('DocumentaciÃ³n')) { return }
    $n = $c.Replace('DocumentaciÃ³n de Estudio del Curso', 'Documentación de Estudio del Curso')
    $n = $n.Replace('DocumentaciÃ³n', 'Documentación')
    if ($n -ne $c) {
        [IO.File]::WriteAllText($_.FullName, $n, $utf8)
        $script:changed++
        Write-Host $_.FullName
    }
}

Write-Host "Mojibake fixes: $changed"
