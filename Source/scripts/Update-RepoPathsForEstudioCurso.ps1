param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

$NewFolder = 'Documentación de Estudio del Curso'

function Invoke-FixText([string]$text) {
    $pairs = @(
        @('../../../../Documentación del Proyecto/DocumentaciÃ³n de Estudio del Curso/', "../../../../$NewFolder/"),
        @('../../../Documentación del Proyecto/DocumentaciÃ³n de Estudio del Curso/', "../../../$NewFolder/"),
        @('../../Documentación del Proyecto/DocumentaciÃ³n de Estudio del Curso/', "../../$NewFolder/"),
        @('../Documentación del Proyecto/DocumentaciÃ³n de Estudio del Curso/', "../$NewFolder/"),
        @('Documentación del Proyecto/DocumentaciÃ³n de Estudio del Curso/', "$NewFolder/"),
        @('Documentación\teoria-entrevistas\', "$NewFolder\"),
        @('I:\Curso\ShopDemo\Documentación del Proyecto\teoria-entrevistas\', "I:\Curso\ShopDemo\$NewFolder\"),
        @('I:\Curso\ShopDemo\Documentación del Proyecto\DocumentaciÃ³n de Estudio del Curso/', "I:\Curso\ShopDemo/$NewFolder/"),
        @('ShopDemo\Documentación del Proyecto\teoria-entrevistas\', "ShopDemo\$NewFolder\"),
        @('ShopDemo/Documentación del Proyecto/DocumentaciÃ³n de Estudio del Curso/', "ShopDemo/$NewFolder/"),
        @('../../../../../DocumentaciÃ³n de Estudio del Curso/', "../../../../../$NewFolder/"),
        @('../../../../DocumentaciÃ³n de Estudio del Curso/', "../../../../$NewFolder/"),
        @('../../../DocumentaciÃ³n de Estudio del Curso/', "../../../$NewFolder/"),
        @('../../DocumentaciÃ³n de Estudio del Curso/', "../../$NewFolder/"),
        @('DocumentaciÃ³n de Estudio del Curso/', "$NewFolder/"),
        @("Join-Path `$Root 'Documentación\teoria-entrevistas", "Join-Path `$Root '$NewFolder"),
        @("Join-Path `$Root 'Documentación del Proyecto/teoria-entrevistas", "Join-Path `$Root '$NewFolder"),
        @('globs: Documentación del Proyecto/DocumentaciÃ³n de Estudio del Curso/**', "globs: $NewFolder/**"),
        @('globs: Documentación\teoria-entrevistas\**', "globs: $NewFolder/**")
    )

    foreach ($p in $pairs) {
        $text = $text.Replace($p[0], $p[1])
    }

    while ($text.Contains("$NewFolder/$NewFolder/")) {
        $text = $text.Replace("$NewFolder/$NewFolder/", "$NewFolder/")
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
