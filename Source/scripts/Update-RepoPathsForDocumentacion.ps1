param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

$ScriptsDocsPlaceholder = 'Source/scripts/docs/'
$DocsFolder = 'Documentación_Del_Proyecto'

function Invoke-FixText([string]$text) {
    $text = $text.Replace('Source/scripts/docs/', $ScriptsDocsPlaceholder)

    $pairs = @(
        @('../../../../Documentación_Del_Proyecto/', '../../../../Documentación_Del_Proyecto/'),
        @('../../../Documentación_Del_Proyecto/', '../../../Documentación_Del_Proyecto/'),
        @('../../Documentación_Del_Proyecto/', '../../Documentación_Del_Proyecto/'),
        @('../Documentación_Del_Proyecto/', '../Documentación_Del_Proyecto/'),
        @('..\..\..\..\Documentación_Del_Proyecto\', '..\..\..\..\Documentación_Del_Proyecto\'),
        @('..\..\..\Documentación_Del_Proyecto\', '..\..\..\Documentación_Del_Proyecto\'),
        @('..\..\Documentación_Del_Proyecto\', '..\..\Documentación_Del_Proyecto\'),
        @('..\Documentación_Del_Proyecto\', '..\Documentación_Del_Proyecto\'),
        @('\Documentación_Del_Proyecto\', '\Documentación_Del_Proyecto\'),
        @('(Documentación_Del_Proyecto/', '(Documentación_Del_Proyecto/'),
        @('](Documentación_Del_Proyecto/', '](Documentación_Del_Proyecto/'),
        @('- Documentación_Del_Proyecto/', '- Documentación_Del_Proyecto/'),
        @('| `Documentación_Del_Proyecto/', '| `Documentación_Del_Proyecto/'),
        @('`Documentación_Del_Proyecto/', '`Documentación_Del_Proyecto/'),
        @('"Documentación_Del_Proyecto/', '"Documentación_Del_Proyecto/'),
        @("'Documentación_Del_Proyecto/", "'Documentación_Del_Proyecto/"),
        @('I:\Curso\ShopDemo\Documentación_Del_Proyecto\', 'I:\Curso\ShopDemo\Documentación_Del_Proyecto\'),
        @('I:\Curso\ShopDemo\Documentación_Del_Proyecto/', 'I:\Curso\ShopDemo\Documentación_Del_Proyecto/'),
        @('ShopDemo\Documentación_Del_Proyecto\', 'ShopDemo\Documentación_Del_Proyecto\'),
        @('ShopDemo/Documentación_Del_Proyecto/', 'ShopDemo/Documentación_Del_Proyecto/'),
        @('| `Documentación_Del_Proyecto/` |', '| `Documentación_Del_Proyecto/` |'),
        @('Documentación_Del_Proyecto/despliegue', 'Documentación_Del_Proyecto/despliegue'),
        @('Documentación_Del_Proyecto/teoria-entrevistas', 'Documentación_De_Estudio_Del_Curso'),
        @('Documentación_Del_Proyecto/catalog', 'Documentación_Del_Proyecto/catalog'),
        @('Documentación_Del_Proyecto/orders', 'Documentación_Del_Proyecto/orders'),
        @('Documentación_Del_Proyecto/inventory', 'Documentación_Del_Proyecto/inventory'),
        @('Documentación_Del_Proyecto/analytics', 'Documentación_Del_Proyecto/analytics'),
        @('Documentación_Del_Proyecto/integracion-ia', 'Documentación_Del_Proyecto/integracion-ia'),
        @('Documentación_Del_Proyecto/cheat-sheets', 'Documentación_Del_Proyecto/cheat-sheets'),
        @('Documentación_Del_Proyecto/observabilidad', 'Documentación_Del_Proyecto/observabilidad'),
        @('Documentación_Del_Proyecto/resiliencia', 'Documentación_Del_Proyecto/resiliencia'),
        @('Documentación_Del_Proyecto/GUIA-', 'Documentación_Del_Proyecto/GUIA-'),
        @('Documentación_Del_Proyecto/ANEXO-', 'Documentación_Del_Proyecto/ANEXO-'),
        @('Documentación_Del_Proyecto/ARQUITECTURA', 'Documentación_Del_Proyecto/ARQUITECTURA'),
        @('Documentación_Del_Proyecto/INTEGRACION-', 'Documentación_Del_Proyecto/INTEGRACION-'),
        @('Documentación_Del_Proyecto/TEORIA-', 'Documentación_Del_Proyecto/TEORIA-'),
        @('Documentación_Del_Proyecto/ShopDemo.postman', 'Documentación_Del_Proyecto/ShopDemo.postman'),
        @('Documentación_Del_Proyecto/README', 'Documentación_Del_Proyecto/README'),
        @('├── docs/', '├── Documentación_Del_Proyecto/'),
        @('Documentación_Del_Proyecto/ |', 'Documentación_Del_Proyecto/ |'),
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

    while ($text.Contains('Documentación_Del_Proyecto/')) {
        $text = $text.Replace('Documentación_Del_Proyecto/', 'Documentación_Del_Proyecto/')
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
