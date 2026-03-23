#requires -version 2.0

# Check if the console output supports virtual terminal processing or it's redirected
$isNonInteractive = ($args -like '*-NonInteractive*'  `
                         -or $args -like '*-File*' `
                         -or -not $host.UI.SupportsVirtualTerminal) `
                      -and -not ($args -like '*powershell-integration.ps1*') `

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

Import-Module -Name Profile

if ($isNonInteractive -eq $true) {
    return
}

if (!(Test-Path variable:backupHome)) {
    new-variable -name backupHome -value "$profileFolder\profileBackup" `
        -Description "Folder for profile backups. Profile created" `
        -Option ReadOnly -Scope "Global"
}


#Initialize-PSDrives
#Initialize-ScriptPaths

Import-Module -Name AutoComplete
refreshenv | out-null
oh-my-posh init pwsh --config "$PSScriptRoot\theme.omp.json" | Invoke-Expression | out-null

if ($env:TERM_PROGRAM -eq "kiro") { . "$(kiro --locate-shell-integration-path pwsh)" }
