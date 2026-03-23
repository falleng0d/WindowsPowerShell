#Aliases
Set-Alias -Name ep -Value Edit-Profile | out-null
Set-Alias -Name tch -Value Test-ConsoleHost | out-null
Set-Alias -Name gfl -Value Get-ForwardLink | out-null
Set-Alias -Name gwp -Value Get-WebPage | out-null
Set-Alias -Name rifc -Value Replace-InvalidFileCharacters | out-null
Set-Alias -Name gev -Value Get-EnumValues | out-null
Set-Alias -Name props -Value Get-Properties | Out-Null
Set-Alias -Name cde -Value Set-LocationFuzzyEverything
Set-Alias -Name paste -Value Get-Clipboard
Set-Alias psadmin Relaunch-Admin
Set-Alias sudo Relaunch-Admin
Set-Alias k kubectl
Set-Alias ln New-Symbolic-Link
Set-Alias lh New-Hard-Link

Set-Alias -Name scratch -Value New-Scratch
Set-Alias -Name touch -Value New-File
Set-Alias -Name rpp -Value Reload-Profile

function Set-ParentLocation { Set-Location .. }
Set-Alias -Name '..' -Value Set-ParentLocation

Export-ModuleMember -Function Set-ParentLocation
Export-ModuleMember -Alias *
