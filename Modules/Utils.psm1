function Test-ConsoleHost {
    if (($host.Name -match 'consolehost')) { $true }
    Else { $false }  
}
function Invoke-Script-Uri {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptUri
    )
    $script = (New-Object System.Net.WebClient).DownloadString($ScriptUri)
    Invoke-Expression $script
}
function Relaunch-Admin { Start-Process -Verb RunAs (Get-Process -Id $PID).Path }
function Edit-Profile { code ($PROFILE.CurrentUserAllHosts -replace "[^\\]*.ps1$","") }
function Get-Properties {
    param ([Parameter(Position = 0, ValueFromPipeline = $True)]$obj)
    Format-List -Property * -InputObject $obj
}
function Reload-Profile {
    . $profile
}

Export-ModuleMember -Function Test-ConsoleHost
Export-ModuleMember -Function Edit-Profile
Export-ModuleMember -Function Get-Properties
Export-ModuleMember -Function Relaunch-Admin
Export-ModuleMember -Function Invoke-Script-Uri
Export-ModuleMember -Function Reload-Profile
