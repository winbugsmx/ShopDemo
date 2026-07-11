param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

function Invoke-FixText([string]$text) {
    $pairs = @(
        @('I:\Curso\ShopDemo\scripts\', 'I:\Curso\ShopDemo\Source\scripts\'),
        @('ShopDemo\scripts\', 'ShopDemo\Source\scripts\'),
        @('ShopDemo/scripts/', 'ShopDemo/Source/scripts/'),
        @('-f ShopDemo.Catalog.Api/Dockerfile .', '-f Source/Catalog/ShopDemo.Catalog.Api/Dockerfile Source'),
        @('-f ShopDemo.Orders.Api/Dockerfile .', '-f Source/Orders/ShopDemo.Orders.Api/Dockerfile Source'),
        @('-f ShopDemo.Inventory.Api/Dockerfile .', '-f Source/Inventory/ShopDemo.Inventory.Api/Dockerfile Source'),
        @('I:\Curso\ShopDemo\ShopDemo.Catalog.Api', 'I:\Curso\ShopDemo\Source\Catalog\ShopDemo.Catalog.Api'),
        @('I:\Curso\ShopDemo\ShopDemo.Orders.Api', 'I:\Curso\ShopDemo\Source\Orders\ShopDemo.Orders.Api'),
        @('I:\Curso\ShopDemo\ShopDemo.Inventory.Api', 'I:\Curso\ShopDemo\Source\Inventory\ShopDemo.Inventory.Api')
    )
    foreach ($p in $pairs) {
        $text = $text.Replace($p[0], $p[1])
    }
    while ($text.Contains('Source/Source/')) { $text = $text.Replace('Source/Source/', 'Source/') }
    return $text
}

$roots = @(
    (Join-Path $RepoRoot 'Documentación_Del_Proyecto'),
    (Join-Path $RepoRoot 'spec-driven'),
    (Join-Path $RepoRoot 'k8s'),
    (Join-Path $RepoRoot '.github'),
    (Join-Path $RepoRoot '.cursor'),
    (Join-Path $RepoRoot 'README.md'),
    (Join-Path $RepoRoot 'AGENTS.md')
)

$changed = 0
$extensions = @('.md', '.yml', '.yaml', '.ps1', '.py', '.mdc', '.json')

foreach ($item in $roots) {
    if (Test-Path $item -PathType Leaf) {
        $files = @(Get-Item -LiteralPath $item)
    } elseif (Test-Path $item -PathType Container) {
        $files = Get-ChildItem -LiteralPath $item -Recurse -File | Where-Object {
            $extensions -contains $_.Extension
        }
    } else { continue }

    foreach ($f in $files) {
        $c = [IO.File]::ReadAllText($f.FullName)
        $n = Invoke-FixText $c
        if ($n -ne $c) {
            [IO.File]::WriteAllText($f.FullName, $n)
            $changed++
            Write-Host "Updated: $($f.FullName)"
        }
    }
}

Write-Host "Files changed: $changed"
