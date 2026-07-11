param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

$EstudioPlaceholder = 'DocumentaciÃ³n de Estudio del Curso'
$NewFolder = 'Documentación del Proyecto'

function Invoke-FixText([string]$text) {
    $text = $text.Replace('Documentación de Estudio del Curso', $EstudioPlaceholder)

    $pairs = @(
        @('../../../../Documentación del Proyecto/', "../../../../$NewFolder/"),
        @('../../../Documentación del Proyecto/', "../../../$NewFolder/"),
        @('../../Documentación del Proyecto/', "../../$NewFolder/"),
        @('../Documentación del Proyecto/', "../$NewFolder/"),
        @('Documentación del Proyecto/', "$NewFolder/"),
        @('..\..\..\..\Documentación del Proyecto\', "..\..\..\..\$NewFolder\"),
        @('..\..\..\Documentación del Proyecto\', "..\..\..\$NewFolder\"),
        @('..\..\Documentación del Proyecto\', "..\..\$NewFolder\"),
        @('..\Documentación del Proyecto\', "..\$NewFolder\"),
        @('\Documentación del Proyecto\', "\$NewFolder\"),
        @('I:\Curso\ShopDemo\Documentación del Proyecto\', "I:\Curso\ShopDemo\$NewFolder\"),
        @('I:\Curso\ShopDemo\Documentación del Proyecto/', "I:\Curso\ShopDemo/$NewFolder/"),
        @('ShopDemo\Documentación del Proyecto\', "ShopDemo\$NewFolder\"),
        @('ShopDemo/Documentación del Proyecto/', "ShopDemo/$NewFolder/"),
        @('| `Documentación del Proyecto/` |', "| ``$NewFolder/` |"),
        @('REPO_ROOT / "Documentación del Proyecto"', "REPO_ROOT / `"$NewFolder`""),
        @("REPO_ROOT / 'Documentación del Proyecto'", "REPO_ROOT / '$NewFolder'"),
        @('DocumentaciÃ³n del Proyecto/', "$NewFolder/"),
        @('Documentación del Proyecto\', "$NewFolder\")
    )

    foreach ($p in $pairs) {
        $text = $text.Replace($p[0], $p[1])
    }

    $text = $text.Replace($EstudioPlaceholder, 'Documentación de Estudio del Curso')

    while ($text.Contains("$NewFolder/$NewFolder/")) {
        $text = $text.Replace("$NewFolder/$NewFolder/", "$NewFolder/")
    }
    while ($text.Contains("$NewFolder\$NewFolder\")) {
        $text = $text.Replace("$NewFolder\$NewFolder\", "$NewFolder\")
    }

    return $text
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$changed = 0
$extensions = @('.md', '.yml', '.yaml', '.ps1', '.py', '.mdc', '.json', '.slnx', '.html', '.env.example')

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
