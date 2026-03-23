#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$AskBeforeExecuting
)

function Confirm-Step {
    param(
        [string]$StepName
    )
    if ($AskBeforeExecuting) {
        $choice = Read-Host "Do you want to execute '$StepName'? (Y/n)"
        return $choice -eq '' -or $choice.ToLower() -eq 'y'
    }
    return $true
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

    $appsToInstall = @{
        'git' = 'git'
        'Code' = 'vscode'
    }

    foreach ($app in $appsToInstall.GetEnumerator()) {
        if (!(Get-Command $app.Key -ErrorAction SilentlyContinue)) {
            Write-Output "Installing $($app.Value)..."
            choco install $app.Value
        } else {
            Write-Output "$($app.Value) is already installed."
        }
    }
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
        winget install Microsoft.WindowsTerminal
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
    }
    Write-Output "Starting Windows10DebloaterGUI..."
    .\Windows10DebloaterGUI.ps1
}

function Create-OhMyPoshThemeLink {
    if (-not (Confirm-Step "Create Oh My Posh Theme Link")) {
        Write-Output "Skipping Oh My Posh theme link creation..."
        return
    }

    if (-not $env:POSH_THEMES_PATH) {
        Write-Output "POSH_THEMES_PATH environment variable is not set. Oh My Posh may not be installed."
        return
    }

    if (-not (Test-Path $env:POSH_THEMES_PATH)) {
        Write-Output "Creating Oh My Posh themes directory..."
        New-Item -ItemType Directory -Path $env:POSH_THEMES_PATH -Force | Out-Null
    }

    $sourceFile = Join-Path $PSScriptRoot "json.omp.json"
    $destinationFile = Join-Path $env:POSH_THEMES_PATH "json.omp.json"

    if (-not (Test-Path $sourceFile)) {
        Write-Error "Source theme file not found at: $sourceFile"
        return
    }

    if (Test-Path $destinationFile) {
        Write-Output "Removing existing theme file at: $destinationFile"
        Remove-Item -Path $destinationFile -Force
    }

    Write-Output "Creating hard link from $sourceFile to $destinationFile"
    New-Item -ItemType HardLink -Path $destinationFile -Target $sourceFile -Force
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

function Assert-Administrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Error "This script must be run as Administrator. Please restart PowerShell as Administrator and try again."
        exit 1
    }
    Write-Output "Running with Administrator privileges."
}

# Main execution flow
Write-Output "Starting system bootstrap process..."
if ($AskBeforeExecuting) {
    Write-Output "Interactive mode enabled - you will be asked before each step."
}

# Verify administrator privileges before proceeding
Assert-Administrator

Set-UnrestrictedExecutionPolicy
Disable-PowerShellTelemetry
Install-Chocolatey
Install-RequiredApps
Install-OpenSSH
Configure-SSHService
Configure-SSHFirewallRule
Install-WindowsTerminal
Create-OhMyPoshThemeLink
Install-WindowsDebloater

Write-Output "System bootstrap process completed."
