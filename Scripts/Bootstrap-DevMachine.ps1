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
    if (-not (Confirm-Step "Install Visual C++ Redistributables")) {
        Write-Output "Skipping Visual C++ Redistributables installation..."
        return
    }

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
    if (Confirm-Step "Install Required Apps (Git, VSCode)") {
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
        ditto xyplorer keypirinha
    winget install --accept-source-agreements Canva.Affinity JetBrains.Toolbox `
        ntwind.windowspace NGWIN.PicPick MacType.MacType
}

function Clone-TaskSchedulerRepository {
    if (-not (Confirm-Step "Clone TaskScheduler repository")) {
        Write-Output "Skipping TaskScheduler repository clone..."
        return
    }

    $targetPath = "C:\Users\falleng0d\Documents\TaskScheduler"
    if (Test-Path $targetPath) {
        Write-Output "TaskScheduler repository already exists at '$targetPath'."
        return
    }

    Write-Output "Cloning TaskScheduler repository to '$targetPath'..."
    git clone https://github.com/falleng0d/TaskScheduler $targetPath
}

function Install-MacTypeSettings {
    if (-not (Confirm-Step "Install MacType settings")) {
        Write-Output "Skipping MacType settings installation..."
        return
    }

    $macTypePath = "C:\Program Files\MacType"
    if (Test-Path $macTypePath) {
        $shouldReplace = $true
        if (-not $NonInteractive) {
            $choice = Read-Host "MacType settings already exist at '$macTypePath'. Replace them? (y/N)"
            $shouldReplace = $choice.ToLower() -eq 'y'
        }

        if (-not $shouldReplace) {
            Write-Output "Keeping existing MacType settings."
            return
        }

        Remove-Item -Path $macTypePath -Recurse -Force
    }

    New-Item -ItemType Directory -Path $macTypePath -Force | Out-Null
    Get-GitHubSubFolderOrFile -gitUrl "https://github.com/falleng0d/WindowsPowerShell" -repoPathToExtract "Scripts/MacType" -destPath $macTypePath
}

function Install-KeypirinhaSettings {
    if (-not (Confirm-Step "Install Keypirinha settings")) {
        Write-Output "Skipping Keypirinha settings installation..."
        return
    }

    $keypirinhaPath = Join-Path $env:APPDATA "Keypirinha"
    if (Test-Path $keypirinhaPath) {
        $shouldReplace = $true
        if (-not $NonInteractive) {
            $choice = Read-Host "Keypirinha settings already exist at '$keypirinhaPath'. Replace them? (y/N)"
            $shouldReplace = $choice.ToLower() -eq 'y'
        }

        if (-not $shouldReplace) {
            Write-Output "Keeping existing Keypirinha settings."
            return
        }

        Remove-Item -Path $keypirinhaPath -Recurse -Force
    }

    New-Item -ItemType Directory -Path $keypirinhaPath -Force | Out-Null
    Get-GitHubSubFolderOrFile -gitUrl "https://github.com/falleng0d/WindowsPowerShell" -repoPathToExtract "Scripts/Keypirinha" -destPath $keypirinhaPath
}

function Install-PicPickSettings {
    if (-not (Confirm-Step "Install PicPick settings")) {
        Write-Output "Skipping PicPick settings installation..."
        return
    }

    $picPickPath = Join-Path $env:APPDATA "picpick"
    if (Test-Path $picPickPath) {
        $shouldReplace = $true
        if (-not $NonInteractive) {
            $choice = Read-Host "PicPick settings already exist at '$picPickPath'. Replace them? (y/N)"
            $shouldReplace = $choice.ToLower() -eq 'y'
        }

        if (-not $shouldReplace) {
            Write-Output "Keeping existing PicPick settings."
            return
        }

        Remove-Item -Path $picPickPath -Recurse -Force
    }

    New-Item -ItemType Directory -Path $picPickPath -Force | Out-Null
    Get-GitHubSubFolderOrFile -gitUrl "https://github.com/falleng0d/WindowsPowerShell" -repoPathToExtract "Scripts/PicPick" -destPath $picPickPath

    $jinjaData = @{
        env = @{
            USERPROFILE = $env:USERPROFILE
        }
    }

    Get-ChildItem -Path $picPickPath -Filter "*.j2" -File | ForEach-Object {
        $templateContent = Get-Content -Path $_.FullName -Raw
        $renderedContent = Invoke-Jinja -Template $templateContent -Data $jinjaData
        $outputPath = $_.FullName -replace '\.j2$', ''
        [System.IO.File]::WriteAllText($outputPath, $renderedContent)
        Remove-Item -Path $_.FullName -Force
        Write-Output "Rendered template: $outputPath"
    }
}

function Install-SmoothScroll {
    $smoothScrollInstallRoot = Join-Path $env:LOCALAPPDATA "SmoothScroll"
    $smoothScrollExe = Get-ChildItem -Path $smoothScrollInstallRoot -Filter "SmoothScroll.exe" -Recurse -File -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($smoothScrollExe) {
        Write-Output "SmoothScroll is already installed."
        return
    }

    if (-not (Confirm-Step "Install SmoothScroll")) {
        Write-Output "Skipping SmoothScroll installation..."
        return
    }

    $installerPath = Join-Path $env:TEMP "SmoothScroll_Setup.exe"
    Write-Output "Downloading SmoothScroll installer..."
    Invoke-WebRequest -Uri "https://www.smoothscroll.net/win/download/SmoothScroll_Setup.exe" -OutFile $installerPath

    Write-Output "Launching SmoothScroll installer..."
    Start-Process -FilePath $installerPath -ArgumentList "/SILENT"
}

function Install-HandyPlus {
    $handyPlusExe = Join-Path $env:LOCALAPPDATA "HandyPlus\handy.exe"
    if (Test-Path $handyPlusExe) {
        Write-Output "HandyPlus is already installed."
        return
    }

    if (-not (Confirm-Step "Install HandyPlus")) {
        Write-Output "Skipping HandyPlus installation..."
        return
    }

    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/falleng0d/HandyPlus/releases/latest"
    $asset = $release.assets | Where-Object {
        $_.name -match '^HandyPlus_.*_x64-setup\.exe$'
    } | Select-Object -First 1

    if (-not $asset) {
        throw "Could not find a HandyPlus x64 installer asset in the latest release."
    }

    $installerPath = Join-Path $env:TEMP $asset.name
    Write-Output "Downloading HandyPlus installer $($asset.name)..."
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $installerPath

    Write-Output "Launching HandyPlus installer..."
    Start-Process -FilePath $installerPath -Wait -ArgumentList "/S"
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
    if (-not (Confirm-Step "Install global Python packages (pip)")) {
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
refreshenv

Install-VcRedistributables
Install-WindowsTerminal

Install-Node; refreshenv
Install-NodePackages

Install-Pyenv; refreshenv
Install-Python
Install-PythonPackages

Install-RequiredApps
Install-Extras
Install-SmoothScroll
Install-HandyPlus

Install-Module -Name PSJinja

Install-KeypirinhaSettings
Install-PicPickSettings
Install-MacTypeSettings

keypirinha

Clone-TaskSchedulerRepository

Install-WindowsDebloater

Write-Output "System bootstrap process completed."
