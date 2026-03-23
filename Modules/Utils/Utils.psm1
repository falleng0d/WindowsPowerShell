param()

. $PSScriptRoot\Console.ps1
. $PSScriptRoot\Profile.ps1
. $PSScriptRoot\Files.ps1
. $PSScriptRoot\Paths.ps1
. $PSScriptRoot\Text.ps1
. $PSScriptRoot\History.ps1
. $PSScriptRoot\Directory.ps1
. $PSScriptRoot\Dropbox.ps1
. $PSScriptRoot\Media.ps1
. $PSScriptRoot\Network.ps1
. $PSScriptRoot\Notifications.ps1
. $PSScriptRoot\Processes.ps1
. $PSScriptRoot\Symbolic-Links.ps1
. $PSScriptRoot\Web.ps1
. $PSScriptRoot\Environment.ps1

$exportModuleMemberParams = @{
    Function = @(
        'Test-ConsoleHost',
        'Edit-Profile',
        'Get-Properties',
        'Relaunch-Admin',
        'Add-Path',
        'Get-Path',
        'Invoke-Script-Uri',
        'Get-WebPage',
        'Get-ForwardLink',
        'Reload-Profile',
        'New-File',
        'BackUp-Profile',
        'Copy-Fast',
        'CDBack',
        'New-Scratch',
        'Replace-InvalidFileCharacters',
        'Get-TranscriptName',
        'Scrub',
        'Get-EnumValues',
        'Get-PropOrNull',
        'hh',
        'List-Dir-Numbered',
        'Get-Tree',
        'Remove-Tree',
        'Get-AttrsToArray',
        'Set-DropboxIgnored',
        'Join-ffmpegMp4',
        'Enable-Hotspot',
        'Disable-Hotspot',
        'Set-PathVariable',
        'Show-Notification',
        'Stop-Process-Gracefully',
        'New-Symbolic-Link',
        'New-Hard-Link',
        'Get-VsCodeExtension',
        'Get-RedirectedUrl',
        'wget',
        'export'
    )
}

