#Aliases
Set-Alias -Name ep -Value Edit-Profile | Out-Null
Set-Alias -Name tch -Value Test-ConsoleHost | Out-Null
Set-Alias -Name gfl -Value Get-ForwardLink | Out-Null
Set-Alias -Name gwp -Value Get-WebPage | Out-Null
Set-Alias -Name rifc -Value Replace-InvalidFileCharacters | Out-Null
Set-Alias -Name gev -Value Get-EnumValues | Out-Null
Set-Alias -Name props -Value Get-Properties | Out-Null
Set-Alias -Name cde -Value Set-LocationFuzzyEverything
Set-Alias -Name paste -Value Get-Clipboard
Set-Alias -Name psadmin -Value Relaunch-Admin | Out-Null
Set-Alias -Name sudo -Value Relaunch-Admin | Out-Null
Set-Alias k kubectl
Set-Alias -Name ln -Value New-Symbolic-Link | Out-Null
Set-Alias -Name lh -Value New-Hard-Link | Out-Null
Set-Alias -Name scratch -Value New-Scratch | Out-Null
Set-Alias -Name touch -Value New-File | Out-Null
Set-Alias -Name rpp -Value Reload-Profile | Out-Null

function Set-ParentLocation { Set-Location .. }
Set-Alias -Name '..' -Value Set-ParentLocation

Export-ModuleMember -Function Set-ParentLocation
Export-ModuleMember -Alias *
