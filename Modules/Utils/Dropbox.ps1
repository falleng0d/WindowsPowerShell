function Get-AttrsToArray {
    param (
        $item
    )
    $attobj = $item.Attributes
    $attrs = $attobj.ToString().Split(",").Trim()
    $attrs
}

function Set-DropboxIgnored {
    param (
        [Parameter(Mandatory = $true)] [string]$Pattern,
        [string]$RootPath = "$home\Dropbox",
        [Parameter(Mandatory = $false)] [switch]$Test = $false,
        [Parameter(Mandatory = $false)] [switch]$EnableSync = $false,
        [Parameter(Mandatory = $false)] [switch]$IncludeFiles = $false,
        [Parameter(Mandatory = $false)] [switch]$IncludeDirectories = $false
    )

    foreach ($item in Get-ChildItem -Attributes Directory, Archive $RootPath) {
        $attrs = Get-AttrsToArray $item
        $marchedDir = ($item -is [System.IO.DirectoryInfo]) -and ($IncludeDirectories -eq $true)
        $marchedFile = ($item -is [System.IO.FileInfo]) -and ($IncludeFiles -eq $true)
        if ($item.Name -match $Pattern -and ($marchedDir -or $marchedFile)) {
            Write-Host -ForegroundColor Green "Matched $($item.FullName)"
            if ($Test -eq $false) {
                if ($EnableSync -eq $false) {
                    Write-Host -ForegroundColor Red "Stopped syncing $($item.FullName)"
                    Set-Content -LiteralPath $item.FullName -Stream com.dropbox.ignored -Value 1
                }
                else {
                    Write-Host -ForegroundColor Yellow "Started syncing $($item.Name)"
                    Clear-Content -LiteralPath $item.FullName -Stream com.dropbox.ignored
                }
            }
            else {
                if ($EnableSync -eq $false) {
                    Write-Host -ForegroundColor Red "Stopped syncing $($item.FullName)"
                }
                else {
                    Write-Host -ForegroundColor Yellow "Started syncing $($item.Name)"
                }
            }
        }
        else {
            if ($item -is [System.IO.DirectoryInfo]) {
                Set-DropboxIgnored -Pattern $Pattern -RootPath $item.FullName -EnableSync:$EnableSync -Test:$Test -IncludeFiles:$IncludeFiles -IncludeDirectories:$IncludeDirectories
            }
        }
    }
}
