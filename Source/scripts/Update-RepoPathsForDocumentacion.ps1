param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

$ScriptsDocsPlaceholder = 'Source/scripts/docs/'
$DocsFolder = 'Documentación del Proyecto'

function Invoke-FixText([string]$text) {
    $text = $text.Replace('Source/scripts/docs/', $ScriptsDocsPlaceholder)

    $pairs = @(
        @('../../../../Documentación del Proyecto/', '../../../../Documentación del Proyecto/'),
        @('../../../Documentación del Proyecto/', '../../../Documentación del Proyecto/'),
        @('../../Documentación del Proyecto/', '../../Documentación del Proyecto/'),
        @('../Documentación del Proyecto/', '../Documentación del Proyecto/'),
        @('..\..\..\..\Documentación del Proyecto\', '..\..\..\..\Documentación del Proyecto\'),
        @('..\..\..\Documentación del Proyecto\', '..\..\..\Documentación del Proyecto\'),
        @('..\..\Documentación del Proyecto\', '..\..\Documentación del Proyecto\'),
        @('..\Documentación del Proyecto\', '..\Documentación del Proyecto\'),
        @('\Documentación del Proyecto\', '\Documentación del Proyecto\'),
        @('(Documentación del Proyecto/', '(Documentación del Proyecto/'),
        @('](Documentación del Proyecto/', '](Documentación del Proyecto/'),
        @('- Documentación del Proyecto/', '- Documentación del Proyecto/'),
        @('| `Documentación del Proyecto/', '| `Documentación del Proyecto/'),
        @('`Documentación del Proyecto/', '`Documentación del Proyecto/'),
        @('"Documentación del Proyecto/', '"Documentación del Proyecto/'),
        @("'Documentación del Proyecto/", "'Documentación del Proyecto/"),
        @('I:\Curso\ShopDemo\Documentación del Proyecto\', 'I:\Curso\ShopDemo\Documentación del Proyecto\'),
        @('I:\Curso\ShopDemo\Documentación del Proyecto/', 'I:\Curso\ShopDemo\Documentación del Proyecto/'),
        @('ShopDemo\Documentación del Proyecto\', 'ShopDemo\Documentación del Proyecto\'),
        @('ShopDemo/Documentación del Proyecto/', 'ShopDemo/Documentación del Proyecto/'),
        @('| `Documentación del Proyecto/` |', '| `Documentación del Proyecto/` |'),
        @('Documentación del Proyecto/despliegue', 'Documentación del Proyecto/despliegue'),
        @('Documentación del Proyecto/teoria-entrevistas', 'Documentación de Estudio del Curso'),
        @('Documentación del Proyecto/catalog', 'Documentación del Proyecto/catalog'),
        @('Documentación del Proyecto/orders', 'Documentación del Proyecto/orders'),
        @('Documentación del Proyecto/inventory', 'Documentación del Proyecto/inventory'),
        @('Documentación del Proyecto/analytics', 'Documentación del Proyecto/analytics'),
        @('Documentación del Proyecto/integracion-ia', 'Documentación del Proyecto/integracion-ia'),
        @('Documentación del Proyecto/cheat-sheets', 'Documentación del Proyecto/cheat-sheets'),
        @('Documentación del Proyecto/observabilidad', 'Documentación del Proyecto/observabilidad'),
        @('Documentación del Proyecto/resiliencia', 'Documentación del Proyecto/resiliencia'),
        @('Documentación del Proyecto/GUIA-', 'Documentación del Proyecto/GUIA-'),
        @('Documentación del Proyecto/ANEXO-', 'Documentación del Proyecto/ANEXO-'),
        @('Documentación del Proyecto/ARQUITECTURA', 'Documentación del Proyecto/ARQUITECTURA'),
        @('Documentación del Proyecto/INTEGRACION-', 'Documentación del Proyecto/INTEGRACION-'),
        @('Documentación del Proyecto/TEORIA-', 'Documentación del Proyecto/TEORIA-'),
        @('Documentación del Proyecto/ShopDemo.postman', 'Documentación del Proyecto/ShopDemo.postman'),
        @('Documentación del Proyecto/README', 'Documentación del Proyecto/README'),
        @('├── docs/', '├── Documentación del Proyecto/'),
        @('Documentación del Proyecto/ |', 'Documentación del Proyecto/ |'),
        @('Source/scripts/docs/', 'Source/scripts/docs/'),
        @('Documentación', 'Documentación'),
        @("Join-Path `$RepoRoot 'docs'", "Join-Path `$RepoRoot 'Documentación'"),
        @("Join-Path `$Root 'docs\", "Join-Path `$Root 'Documentación\"),
        @("Join-Path `$root 'docs'", "Join-Path `$root 'Documentación'")
    )

    foreach ($p in $pairs) {
        $text = $text.Replace($p[0], $p[1])
    }

    $text = $text.Replace($ScriptsDocsPlaceholder, 'Source/scripts/docs/')

    while ($text.Contains('Documentación del Proyecto/')) {
        $text = $text.Replace('Documentación del Proyecto/', 'Documentación del Proyecto/')
    }

    return $text
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$changed = 0
$extensions = @('.md', '.yml', '.yaml', '.ps1', '.py', '.mdc', '.json', '.slnx', '.csproj', '.html', '.env.example')

Get-ChildItem -LiteralPath $RepoRoot -Recurse -File | Where-Object {
    $extensions -contains $_.Extension -and
    $_.FullName -notmatch '\\node_modules\\|\\bin\\|\\obj\\|\\.vs\\|\\\.git\\'
} | ForEach-Object {
    $c = [IO.File]::ReadAllText($_.FullName)
    $n = Invoke-FixText $c
    if ($n -ne $c) {
        [IO.File]::WriteAllText($_.FullName, $n, $utf8NoBom)
        $script:changed++
        Write-Host "Updated: $($_.FullName)"
    }
}

Write-Host "Files changed: $changed"
