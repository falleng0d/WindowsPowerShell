Install-Module Pscx -Scope CurrentUser -AllowClobber
Install-Module PSReadLine -RequiredVersion 2.1.0
Install-Module PSEverything
Install-Module -Name PSFzf
Install-Module -Name Recycle
Invoke-RestMethod get.scoop.sh | Invoke-Expression
scoop install https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/oh-my-posh.json

# install module to profile
Import-Module Get-GitHubSubFolderOrFile

$modulesPath = $PROFILE.CurrentUserAllHosts -replace "[^\\]*.ps1$","Modules\"

Get-GitHubSubFolderOrFile -gitUrl "https://github.com/BornToBeRoot/PowerShell" -repoPathToExtract "Module/LazyAdmin" -destPath $modulesPath

. ([Scriptblock]::Create((New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/BornToBeRoot/PowerShell/master/Scripts/OptimizePowerShellStartup.ps1")))
