#Requires -RunAsAdministrator
# $env:NONINTERACTIVE = "true"; irm https://raw.githubusercontent.com/falleng0d/WindowsPowerShell/refs/heads/PowerShell7/Scripts/Bootstrap.ps1 | iex

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$NonInteractive = $false
)

if ($env:NONINTERACTIVE -eq "true") {
    $NonInteractive = $true
}

function Confirm-Step {
    param(
        [string]$StepName
    )

    if ($NonInteractive) {
        return $true
    }

    $choice = Read-Host "Do you want to execute '$StepName'? (Y/n)"
        return $choice -eq '' -or $choice.ToLower() -eq 'y'
}

function Set-UnrestrictedExecutionPolicy {
    if (-not (Confirm-Step "Set Execution Policy to Unrestricted")) {
        Write-Output "Skipping execution policy change..."
        return
    }

    if ((Get-ExecutionPolicy) -ne "Unrestricted") {
        Write-Output "Setting execution policy to unrestricted..."
        Set-ExecutionPolicy unrestricted
    } else {
        Write-Output "Execution policy is already unrestricted."
    }
}

function Install-Chocolatey {
    if (-not (Confirm-Step "Install Chocolatey")) {
        Write-Output "Skipping Chocolatey installation..."
        return
    }

    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Output "Installing Chocolatey..."
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

        Write-Output "Enabling global confirmation for chocolatey..."
        choco feature enable -n allowGlobalConfirmation
    } else {
        Write-Output "Chocolatey is already installed."
    }
}

function Install-RequiredApps {
    if (-not (Confirm-Step "Install Required Apps (Git, VSCode)")) {
        Write-Output "Skipping required apps installation..."
        return
    }

    choco install git oh-my-posh ripgrep make jq yq tldr
}

function Install-OpenSSH {
    if (-not (Confirm-Step "Install OpenSSH Client and Server")) {
        Write-Output "Skipping OpenSSH installation..."
        return
    }

    $sshClient = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Client*'
    $sshServer = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'

    if ($sshClient.State -ne "Installed") {
        Write-Output "Installing OpenSSH Client..."
        Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
    } else {
        Write-Output "OpenSSH Client is already installed."
    }

    if ($sshServer.State -ne "Installed") {
        Write-Output "Installing OpenSSH Server..."
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    } else {
        Write-Output "OpenSSH Server is already installed."
    }
}

function Configure-SSHService {
    if (-not (Confirm-Step "Configure SSH Service")) {
        Write-Output "Skipping SSH service configuration..."
        return
    }

    $sshd = Get-Service sshd -ErrorAction SilentlyContinue
    if ($sshd.Status -ne 'Running') {
        Write-Output "Starting SSH service..."
        Start-Service sshd
    } else {
        Write-Output "SSH service is already running."
    }

    if ($sshd.StartType -ne 'Automatic') {
        Write-Output "Setting SSH service to start automatically..."
        Set-Service -Name sshd -StartupType 'Automatic'
    } else {
        Write-Output "SSH service is already set to start automatically."
    }
}

function Configure-SSHFirewallRule {
    if (-not (Confirm-Step "Configure SSH Firewall Rule")) {
        Write-Output "Skipping firewall rule configuration..."
        return
    }

    if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
        Write-Output "Creating firewall rule 'OpenSSH-Server-In-TCP'..."
        New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    } else {
        Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' already exists."
    }
}

function Install-WindowsTerminal {
    if (-not (Confirm-Step "Install Windows Terminal")) {
        Write-Output "Skipping Windows Terminal installation..."
        return
    }

    if (!(Get-Command wt -ErrorAction SilentlyContinue)) {
        Write-Output "Installing Windows Terminal..."
        winget install Microsoft.WindowsTerminal --accept-source-agreements
    } else {
        Write-Output "Windows Terminal is already installed."
    }
}

function Install-WindowsDebloater {
    if (-not (Confirm-Step "Install and Run Windows10Debloater")) {
        Write-Output "Skipping Windows10Debloater..."
        return
    }

    $debloaterPath = "~/Downloads/Windows10Debloater"
    if (!(Test-Path $debloaterPath)) {
        Write-Output "Downloading Windows10Debloater..."
        Set-Location ~/Downloads
        git clone https://github.com/Sycnex/Windows10Debloater
        Set-Location Windows10Debloater
    } else {
        Write-Output "Windows10Debloater already exists."
        Set-Location $debloaterPath
    }
    Write-Output "Starting Windows10DebloaterGUI..."
    .\Windows10DebloaterGUI.ps1
}

function Disable-PowerShellTelemetry {
    if (-not (Confirm-Step "Disable PowerShell Telemetry")) {
        Write-Output "Skipping PowerShell telemetry disablement..."
        return
    }

    Write-Output "Disabling PowerShell telemetry..."
    $variables = [ordered]@{
        POWERSHELL_CLI_TELEMETRY_OPTOUT = "1"
        POWERSHELL_TELEMETRY_OPTOUT     = "1"
        POWERSHELL_UPDATECHECK          = "Off"
        POWERSHELL_UPDATECHECK_OPTOUT   = "1"
        DOTNET_CLI_TELEMETRY_OPTOUT     = "1"
        DOTNET_TELEMETRY_OPTOUT         = "1"
        COMPlus_EnableDiagnostics       = "0"
    }
    foreach ($target in "User","Machine") {
        write-Host "Target: $target" -foregroundcolor cyan
        foreach ($key in $variables.Keys) {
            write-Host "  $key = $($variables.$Key)"
            [Environment]::SetEnvironmentVariable($key,$variables.$Key, $target)
        }
    }
}

function Install-WinGetModule {
    if (-not (Confirm-Step "Install WinGet PowerShell Module")) {
        Write-Output "Skipping WinGet PowerShell module installation..."
        return
    }

    if (-not (Get-Module -Name Microsoft.WinGet.Client -ListAvailable)) {
        Write-Host "Installing WinGet PowerShell module..."
        if (-not (Get-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue)) {
            Write-Host "Installing NuGet package provider..."
            Install-PackageProvider -Name NuGet -Force -Confirm:$False | Out-Null
            Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
            Write-Host "Using Repair-WinGetPackageManager cmdlet to bootstrap WinGet..."
            Repair-WinGetPackageManager -AllUsers
        } else {
            Write-Host "NuGet package provider is already installed."
        }
    } else {
        Write-Host "WinGet PowerShell module is already installed."
    }
}


function Assert-Administrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Error "This script must be run as Administrator. Please restart PowerShell as Administrator and try again."
        exit 1
    }
    Write-Output "Running with Administrator privileges."
}


function Install-Profile {
    if (-not (Confirm-Step "Install PowerShell Profile")) {
        Write-Output "Skipping PowerShell profile installation..."
        return
    }

    Write-Output "Installing PowerShell profile..."
    $documentsDir = [Environment]::GetFolderPath("MyDocuments")
    $profilePath = "$documentsDir\WindowsPowerShell"

    if (Test-Path $profilePath) {
        Write-Output "Existing PowerShell profile found. Moving to trash..."
        Remove-Item -Path $profilePath -Recurse -Force
    } else {
        Write-Output "No existing PowerShell profile found."
    }

    git clone https://github.com/falleng0d/WindowsPowerShell $profilePath

    $powerShell7Path = "$documentsDir\PowerShell"
    if (Test-Path $powerShell7Path) {
        Write-Output "Existing PowerShell 7 profile found. Moving to trash..."
        Remove-Item -Path $powerShell7Path -Recurse -Force
    } else {
        Write-Output "No existing PowerShell 7 profile found."
    }

    cd $profilePath
    git worktree add -b PowerShell7 $powerShell7Path
    cd -

    . $profile
}

function Install-ProfileModules {
    if (-not (Confirm-Step "Install PowerShell Profile Modules")) {
        Write-Output "Skipping PowerShell profile modules installation..."
        return
    }

    Write-Output "Installing PowerShell profile modules..."

    Install-Module Pscx -Scope CurrentUser -AllowClobber
    Install-Module PSReadLine -RequiredVersion 2.1.0
    Install-Module PSEverything
    Install-Module -Name PSFzf
    Install-Module -Name Recycle
    Install-Module posh-git -Force
    Import-Module Get-GitHubSubFolderOrFile

    Invoke-RestMethod get.scoop.sh | Invoke-Expression

    $modulesPath = $PROFILE.CurrentUserAllHosts -replace "[^\\]*.ps1$","Modules\"

    Get-GitHubSubFolderOrFile -gitUrl "https://github.com/BornToBeRoot/PowerShell" -repoPathToExtract "Module/LazyAdmin" -destPath $modulesPath

    . ([Scriptblock]::Create((New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/BornToBeRoot/PowerShell/master/Scripts/OptimizePowerShellStartup.ps1")))
}

# Main execution flow
Write-Output "Starting system bootstrap process..."
if (-not $NonInteractive) {
    Write-Output "Interactive mode enabled - you will be asked before each step."
}

# Verify administrator privileges before proceeding
Assert-Administrator

Set-PSRepository PSGallery -InstallationPolicy Trusted
Set-UnrestrictedExecutionPolicy
Disable-PowerShellTelemetry

Install-WinGetModule
Install-Chocolatey

Import-Module C:\ProgramData\chocolatey\helpers\chocolateyProfile.psm1
Install-RequiredApps
refreshenv

Install-Profile
Install-ProfileModules

Install-OpenSSH
Configure-SSHService
Configure-SSHFirewallRule

Install-WindowsTerminal
Install-WindowsDebloater

Write-Output "System bootstrap process completed."
