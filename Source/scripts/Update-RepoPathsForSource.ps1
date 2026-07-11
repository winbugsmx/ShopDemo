param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

function Invoke-Replacements([string]$text) {
    $pairs = @(
        @('scripts/azure/', 'Source/scripts/azure/'),
        @('scripts/aws/', 'Source/scripts/aws/'),
        @('Source/scripts/docs/', 'Source/scripts/docs/'),
        @('scripts/github/', 'Source/scripts/github/'),
        @('scripts/generate-code-anexos.py', 'Source/scripts/generate-code-anexos.py'),
        @('ShopDemo.Shared/', 'Source/ShopDemo.Shared/'),
        @('Catalog/', 'Source/Catalog/'),
        @('Orders/', 'Source/Orders/'),
        @('Inventory/', 'Source/Inventory/'),
        @('Aspire/', 'Source/Aspire/'),
        @('AI/', 'Source/AI/')
    )
    foreach ($p in $pairs) {
        $text = $text.Replace($p[0], $p[1])
    }
    while ($text.Contains('Source/Source/')) { $text = $text.Replace('Source/Source/', 'Source/') }
    return $text
}

$includeRoots = @(
    (Join-Path $RepoRoot 'Documentación del Proyecto'),
    (Join-Path $RepoRoot 'spec-driven'),
    (Join-Path $RepoRoot 'k8s'),
    (Join-Path $RepoRoot '.github'),
    (Join-Path $RepoRoot '.cursor')
)
$includeFiles = @(
    (Join-Path $RepoRoot 'README.md'),
    (Join-Path $RepoRoot 'AGENTS.md'),
    (Join-Path $RepoRoot 'Source/ShopDemo.slnx'),
    (Join-Path $RepoRoot '.gitignore')
)

$changed = 0
$extensions = @('.md', '.yml', '.yaml', '.ps1', '.py', '.mdc', '.json', '.slnx', '.csproj')

foreach ($root in $includeRoots) {
    if (-not (Test-Path $root)) { continue }
    Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object {
        $extensions -contains $_.Extension -and $_.FullName -notmatch 'node_modules'
    } | ForEach-Object {
        $c = [IO.File]::ReadAllText($_.FullName)
        $n = Invoke-Replacements $c
        if ($n -ne $c) { [IO.File]::WriteAllText($_.FullName, $n); $script:changed++ }
    }
}

foreach ($f in $includeFiles) {
    if (-not (Test-Path $f)) { continue }
    $c = [IO.File]::ReadAllText($f)
    $n = Invoke-Replacements $c
    if ($n -ne $c) { [IO.File]::WriteAllText($f, $n); $script:changed++ }
}

# Deploy scripts: repo root is three levels up from azure/aws
@(
    (Join-Path $RepoRoot 'Source\scripts\azure\Deploy-AzureShopDemo.ps1'),
    (Join-Path $RepoRoot 'Source\scripts\aws\Deploy-AwsShopDemo.ps1')
) | ForEach-Object {
    if (-not (Test-Path $_)) { return }
    $c = [IO.File]::ReadAllText($_)
    $n = $c.Replace("Join-Path `$PSScriptRoot '..\..'", "Join-Path `$PSScriptRoot '..\..\..'")
    $n = Invoke-Replacements $n
    if ($n -ne $c) { [IO.File]::WriteAllText($_, $n); $script:changed++ }
}

# Docs scripts: repo root three levels up
Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'Source\scripts\docs') -Filter '*.ps1' -File | ForEach-Object {
    $c = [IO.File]::ReadAllText($_.FullName)
    $n = $c -replace 'Split-Path \(Split-Path \$PSScriptRoot -Parent\) -Parent', "(Resolve-Path (Join-Path `$PSScriptRoot '..\..\..')).Path"
    if ($n -match 'Resolve-Path.*Resolve-Path') {
        $n = $c.Replace(
            '$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent',
            '$Root = (Resolve-Path (Join-Path $PSScriptRoot ''..\..\..'')).Path'
        )
    }
    if ($n -ne $c) { [IO.File]::WriteAllText($_.FullName, $n); $script:changed++ }
}

# Catalog/Orders docker-compose: build context = Source/
$catalogCompose = Join-Path $RepoRoot 'Source\Catalog\ShopDemo.Catalog.Api\docker-compose.yml'
if (Test-Path $catalogCompose) {
    $c = [IO.File]::ReadAllText($catalogCompose)
    $n = $c.Replace('context: ..', 'context: ../..').Replace('dockerfile: ShopDemo.Catalog.Api/Dockerfile', 'dockerfile: Catalog/ShopDemo.Catalog.Api/Dockerfile')
    if ($n -ne $c) { [IO.File]::WriteAllText($catalogCompose, $n); $script:changed++ }
}
$ordersCompose = Join-Path $RepoRoot 'Source\Orders\ShopDemo.Orders.Api\docker-compose.yml'
if (Test-Path $ordersCompose) {
    $c = [IO.File]::ReadAllText($ordersCompose)
    $n = $c.Replace('context: ..', 'context: ../..').Replace('dockerfile: ShopDemo.Orders.Api/Dockerfile', 'dockerfile: Orders/ShopDemo.Orders.Api/Dockerfile')
    if ($n -ne $c) { [IO.File]::WriteAllText($ordersCompose, $n); $script:changed++ }
}

# generate-code-anexos.py
$gen = Join-Path $RepoRoot 'Source\scripts\generate-code-anexos.py'
if (Test-Path $gen) {
    $c = [IO.File]::ReadAllText($gen)
    $n = Invoke-Replacements $c
    if ($n -ne $c) { [IO.File]::WriteAllText($gen, $n); $script:changed++ }
}

Write-Host "Updated $changed files"
