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

function Install-VcRedistributables {
    Install-Module -Name VcRedist -RequiredVersion 4.0.460 -Force
    Import-Module -Name VcRedist
    Save-VcRedist -VcList (Get-VcList -Release (2015, 2017, 2019, 2022))
    Install-VcRedist -VcList (Get-VcList -Release (2015, 2017, 2019, 2022))
    Remove-Item -Recurse 2015
    Remove-Item -Recurse 2017
    Remove-Item -Recurse 2019
    Remove-Item -Recurse 2022
}

function Install-RequiredApps {
    if (-not (Confirm-Step "Install Required Apps (Git, VSCode)")) {
        Write-Output "Skipping required apps installation..."
        return
    }

    choco install git oh-my-posh ripgrep make jq yq fzf tldr vscode winrar `
        winscp windirstat vlc vagrant unzip terraform rustdesk mobaxterm `
        notepad4 LinkShellExtension Lazydocker lazygit klogg gimp gh `
        firefox grep go jcpicker jnv just ffmpeg everything dbeaver deno dngrep `
        bun bat awscli awk autohotkey ctop rsync restic systeminformer plantuml `
        powershell-core powertoys mitmproxy rust
    choco install roboto.font JetbrainsMono nerd-fonts-JetBrainsMono opensans `
        fantasque-sans.font Inconsolata
}

function Install-Extras {
    if (-not (Confirm-Step "Install Extra Apps (1Password, Tailscale, etc.)")) {
        Write-Output "Skipping extra apps installation..."
        return
    }

    choco install libreoffice-fresh 1password docker-desktop tailscale speedcrunch `
        ditto xyplorer keypirinha cursor picpick
    winget install --accept-source-agreements Canva.Affinity JetBrains.Toolbox `
        ntwind.windowspace NGWIN.PicPick

    # downlod https://www.smoothscroll.net/win/download/SmoothScroll_Setup.exe
    Invoke-WebRequest -Uri "https://www.smoothscroll.net/win/download/SmoothScroll_Setup.exe" -OutFile "$env:TEMP\SmoothScroll_Setup.exe"
    # install smooth scroll
    Start-Process -FilePath "$env:TEMP\SmoothScroll_Setup.exe" -ArgumentList "/S" -Wait
}

function Install-Node {
    if (-not (Confirm-Step "Install Node.js")) {
        Write-Output "Skipping Node.js installation..."
        return
    }

    choco install nvs
    refreshenv

    nvs add 22
    nvs add 24
    nvs link 24
}

function Install-NodePackages {
    if (-not (Confirm-Step "Install global Node.js packages (npm, pnpm, bun)")) {
        Write-Output "Skipping global Node.js packages installation..."
        return
    }

    npm install -g npm@latest
    npm install -g pnpm yarn npm opencode-ai '@kilocode/cli' `
        typescript-language-server typescript ts-node tsx prettier `
        rev-dep lnai '@tailwindcss/language-server' '@augmentcode/auggie' `
        '@openai/codex' '@google/gemini-cli' vercel next
}

function Install-Pyenv {
    if (-not (Confirm-Step "Install pyenv-win")) {
        Write-Output "Skipping pyenv-win installation..."
        return
    }

    Invoke-WebRequest -UseBasicParsing -Uri `
        "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1" `
         -OutFile "./install-pyenv-win.ps1"
    & "./install-pyenv-win.ps1"
    refreshenv
    pyenv update
}

function Install-Python {
    if (-not (Confirm-Step "Install Python versions with pyenv")) {
        Write-Output "Skipping Python installation..."
        return
    }

    pyenv install 3.12
    pyenv global 3.12
    python -m pip install --upgrade pip

    pyenv install 3.14
    pyenv global 3.14
    python -m pip install --upgrade pip
}

function Install-PythonPackages {
    if (-not (Confirm-Step "Install global Python packages (pipx)")) {
        Write-Output "Skipping global Python packages installation..."
        return
    }

    pip install pyright pylint black isort flake8 mypy autopep8 pipenv poetry `
        ruff uv setuptools
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

Install-VcRedistributables
Install-WindowsTerminal

Install-Node; refreshenv
Install-NodePackages

Install-Pyenv; refreshenv
Install-Python
Install-PythonPackages

Install-RequiredApps
Install-Extras

Install-WindowsDebloater

Write-Output "System bootstrap process completed."
