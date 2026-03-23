#requires -version 2.0

using namespace System.Management.Automation
using namespace System.Management.Automation.Language

# Check if the console output supports virtual terminal processing or it's redirected
$isNonInteractive = ($args -like '*-NonInteractive*'  `
                         -or $args -like '*-File*' `
                         -or -not $host.UI.SupportsVirtualTerminal) `
                      -and -not ($args -like '*powershell-integration.ps1*') `

$profileFolder = $profile.CurrentUserAllHosts -replace "\\[^\\]*.ps1$", ""
$profileFolderName = $profile.CurrentUserAllHosts -replace "[^\\]*.ps1$", "" |
        Split-Path -Leaf

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

# Provides easy access to the scripts in the Scripts folder.
# The full path of a script can be accessed as `$Scripts.ScriptName`
$_scriptFiles = Get-ChildItem -Path "$PSScriptRoot\Scripts" -Recurse -Include *.ps1
$scriptPaths = @{}
foreach ($script in $_scriptFiles) {
    $scriptName = $script.BaseName
    $scriptPath = $script.FullName
    $scriptPaths[$scriptName] = $scriptPath
}
$Scripts = New-Object PSObject -Property $scriptPaths
$Global:Scripts = $Scripts

if (!(Test-Path variable:backupHome)) {
    new-variable -name backupHome -value "$profileFolder\profileBackup" `
        -Description "Folder for profile backups. Profile created" `
        -Option ReadOnly -Scope "Global"
}

# PS_Drives
if (-not (Get-PSDrive -Name Mod -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name Mod -Root ($env:PSModulePath -split ';')[0] `
        -PSProvider FileSystem -ErrorAction SilentlyContinue | Out-Null
}

if ($isNonInteractive -eq $false) {
    Import-Module -Name AutoComplete
    refreshenv | out-null
    oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/json.omp.json" |
            Invoke-Expression | out-null
}

if ($env:TERM_PROGRAM -eq "kiro") { . "$(kiro --locate-shell-integration-path pwsh)" }
