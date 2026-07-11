$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$fixes = @(
    @('Source/Catalog/Source/Orders/Source/Inventory', 'Source/Catalog, Source/Orders, Source/Inventory'),
    @('Source/Catalog/Source/Orders/Inventory', 'Source/Catalog, Source/Orders, Source/Inventory'),
    @('Source/Catalog/Source/Inventory/Analytics', 'Source/Catalog, Source/Inventory y Analytics'),
    @('Source/Catalog/Source/Inventory', 'Source/Catalog y Source/Inventory'),
    @('Source/Orders/Source/Inventory', 'Source/Orders y Source/Inventory')
)
$count = 0
Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object {
    $_.Extension -in '.md', '.mdc' -and $_.FullName -notmatch 'node_modules'
} | ForEach-Object {
    $c = [IO.File]::ReadAllText($_.FullName)
    $n = $c
    foreach ($f in $fixes) { $n = $n.Replace($f[0], $f[1]) }
    if ($n -ne $c) {
        [IO.File]::WriteAllText($_.FullName, $n)
        $script:count++
    }
}
Write-Host "Fixed $count files"
