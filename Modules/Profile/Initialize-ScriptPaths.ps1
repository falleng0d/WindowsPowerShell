function Initialize-ScriptPaths {
    $scriptsDirectory = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Scripts'
    $scriptFiles = Get-ChildItem -Path $scriptsDirectory -Recurse -Include '*.ps1'
    $scriptPaths = @{}

    foreach ($script in $scriptFiles) {
        $scriptPaths[$script.BaseName] = $script.FullName
    }

    $Global:Scripts = New-Object PSObject -Property $scriptPaths
}
