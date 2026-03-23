function Add-Path($Path) {
    $Path = [Environment]::GetEnvironmentVariable("PATH", "Machine") + [IO.Path]::PathSeparator + $Path
    [Environment]::SetEnvironmentVariable("Path", $Path, "Machine")
}

function Get-Path() {
    [Environment]::GetEnvironmentVariable("PATH", "Machine")
}

function Set-PathVariable {
    param (
        [Parameter(Mandatory = $false)] [string]$AddPath,
        [Parameter(Mandatory = $false)] [string]$RemovePath
    )
    $regexPaths = @()
    if ($PSBoundParameters.Keys -contains 'AddPath') {
        $regexPaths += [regex]::Escape($AddPath)
    }

    if ($PSBoundParameters.Keys -contains 'RemovePath') {
        $regexPaths += [regex]::Escape($RemovePath)
    }

    $arrPath = $env:Path -split ';'
    foreach ($path in $regexPaths) {
        $arrPath = $arrPath | Where-Object { $_ -notMatch "^$path\\?" }
    }
    $env:Path = ($arrPath + $addPath) -join ';'
}
