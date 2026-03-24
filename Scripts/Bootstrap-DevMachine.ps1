#Requires -RunAsAdministrator
# $env:NONINTERACTIVE = "true"; irm https://raw.githubusercontent.com/falleng0d/WindowsPowerShell/refs/heads/PowerShell7/Scripts/Bootstrap-DevMachine.ps1 | iex

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$NonInteractive = $false
)

if ($env:NONINTERACTIVE -eq "true") {
    $NonInteractive = $true
}

function Remove-ItemToRecycleBin($Path) {
    Add-Type -AssemblyName Microsoft.VisualBasic

    $item = Get-Item -Path $Path -ErrorAction SilentlyContinue
    if ($item -eq $null) {
        Write-Error("'{0}' not found" -f $Path)
    } else {
        $fullpath=$item.FullName
        Write-Verbose ("Moving '{0}' to the Recycle Bin" -f $fullpath)
        if (Test-Path -Path $fullpath -PathType Container) {
            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($fullpath,'OnlyErrorDialogs','SendToRecycleBin')
        } else {
            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($fullpath,'OnlyErrorDialogs','SendToRecycleBin')
        }
    }
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

function Install-RequiredApps {
    if (-not (Confirm-Step "Install Required Apps (Git, VSCode)")) {
        Write-Output "Skipping required apps installation..."
        return
    }

    choco install -y git oh-my-posh ripgrep make jq yq fzf tldr vscode JetbrainsMono `
        nerd-fonts-JetBrainsMono winrar winscp windirstat vlc vcredist-all vagrant `
        unzip terraform rustdesk xyplorer mobaxterm notepad4 LinkShellExtension Lazydocker `
        lazygit klogg keypirinha gimp gh firefox grep go jcpicker jnv just ffmpeg everything `
        dbeaver deno dngrep bun bat awscli awk autohotkey 1password docker-desktop ctop
    winget install --id GitHub.cli --accept-source-agreements
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
if (-not $NonInteractive) {
    Write-Output "Interactive mode enabled - you will be asked before each step."
}

# Verify administrator privileges before proceeding
Assert-Administrator

Set-PSRepository PSGallery -InstallationPolicy Trusted
Set-UnrestrictedExecutionPolicy

Install-RequiredApps

Install-WindowsTerminal
Install-WindowsDebloater

Write-Output "System bootstrap process completed."
