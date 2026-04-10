#Requires -RunAsAdministrator
# $env:NONINTERACTIVE = "true"; irm https://raw.githubusercontent.com/falleng0d/WindowsPowerShell/refs/heads/PowerShell7/Scripts/Bootstrap.ps1 | iex

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$NonInteractive = $false,

    [Parameter()]
    [string[]]$Install
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

function Invoke-InstallStep {
    param(
        [Parameter(Mandatory)]
        [string]$StepName,

        [Parameter(Mandatory)]
        [scriptblock]$Action
    )

    if ($Install -contains 'All' -or $Install -contains $StepName) {
        Write-Output "Running install step: $StepName"
        & $Action
    }
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

    choco install git oh-my-posh ripgrep make jq yq tldr fzf
    winget install --id GitHub.cli --accept-source-agreements
}

function Install-OpenSSH {
    if (-not (Confirm-Step "Install OpenSSH Client and Server")) {
        Write-Output "Skipping OpenSSH installation..."
        return
    }

    $sshClient = Get-WindowsCapability -Online |
            Where-Object Name -like 'OpenSSH.Client*'
    $sshServer = Get-WindowsCapability -Online |
            Where-Object Name -like 'OpenSSH.Server*'

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

    New-ItemProperty -Name DefaultShell -Value "C:\Program Files\PowerShell\7\pwsh.exe" -Path "HKLM:\SOFTWARE\OpenSSH" -PropertyType String -Force

    # comment AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys out of sshd_config to allow administrators to use authorized_keys for key-based authentication
    $sshdConfigPath = "C:\ProgramData\ssh\sshd_config"
    if (Test-Path $sshdConfigPath) {
        $sshdConfigContent = Get-Content $sshdConfigPath
        if ($sshdConfigContent -match "^\s*AuthorizedKeysFile\s+__PROGRAMDATA__/ssh/administrators_authorized_keys") {
            Write-Output "Commenting out 'AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys' in sshd_config..."
            $updatedContent = $sshdConfigContent -replace "^\s*AuthorizedKeysFile\s+__PROGRAMDATA__/ssh/administrators_authorized_keys", "# AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys"
            Set-Content -Path $sshdConfigPath -Value $updatedContent
        } else {
            Write-Output "'AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys' is already commented out in sshd_config."
        }
    } else {
        Write-Output "sshd_config not found at $sshdConfigPath. Skipping configuration of AuthorizedKeysFile."
    }

    winget install "Microsoft.OpenSSH.Preview" --accept-source-agreements

    Sleep -Milliseconds 1000

    $service = Get-Service sshd -ErrorAction SilentlyContinue
    if ($service -ne $null) {
        if ($service.Status -ne 'Running') {
            Write-Output "Starting SSH service..."
            Start-Service sshd
        } else {
            Stop-Service sshd
            Start-Service sshd
        }
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

function Disable-ClaudeCodeTelemetry {
    if (-not (Confirm-Step "Disable ClaudeCode Telemetry")) {
        Write-Output "Skipping ClaudeCode telemetry disablement..."
        return
    }

    Write-Output "Disabling ClaudeCode telemetry..."
    $variables = [ordered]@{
        CLAUDE_CODE_ACCOUNT_UUID="11111111-1111-1111-1111-111111111111"
        CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY="1"
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"
        CLAUDE_CODE_ORGANIZATION_UUID="00000000-0000-0000-0000-000000000000"
        CLAUDE_CODE_USER_EMAIL="root@anthropic.com"
        DISABLE_ERROR_REPORTING="1"
        DISABLE_FEEDBACK_COMMAND="1"
        DISABLE_TELEMETRY="1"
        VERCEL_PLUGIN_TELEMETRY="off"
    }
    foreach ($target in "User","Machine") {
        write-Host "Target: $target" -foregroundcolor cyan
        foreach ($key in $variables.Keys) {
            if (-not [Environment]::GetEnvironmentVariable($key, $target)) {
                [Environment]::SetEnvironmentVariable($key, $variables.$Key, $target)
                write-Host "  $key = $($variables.$Key)"
            }
        }
        }
}

function Install-WinGetModule {
    if (-not (Confirm-Step "Install WinGet PowerShell Module")) {
        Write-Output "Skipping WinGet PowerShell module installation..."
        return
    }

    if (-not (Get-Command -ErrorAction SilentlyContinue winget)) {
        Write-Host "Installing NuGet package provider..."
        Install-PackageProvider -Name NuGet -Force -Confirm:$False
        Write-Host "Installing WinGet PowerShell module..."
        Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery
        Write-Host "Using Repair-WinGetPackageManager cmdlet to bootstrap WinGet..."
        Repair-WinGetPackageManager -AllUsers
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
        Remove-ItemToRecycleBin -Path $profilePath
    } else {
        Write-Output "No existing PowerShell profile found."
    }

    mkdir -p $profilePath
    git clone https://github.com/falleng0d/WindowsPowerShell $profilePath

    $powerShell7Path = "$documentsDir\PowerShell"
    if (Test-Path $powerShell7Path) {
        Write-Output "Existing PowerShell 7 profile found. Moving to trash..."
        Remove-ItemToRecycleBin -Path $powerShell7Path
    } else {
        Write-Output "No existing PowerShell 7 profile found."
    }

    $pwd = Get-Location
    cd $profilePath
    git fetch origin PowerShell7
    git worktree add -b PowerShell7 $powerShell7Path
    cd $pwd
}

function Install-ProfileModules {
    if (-not (Confirm-Step "Install PowerShell Profile Modules")) {
        Write-Output "Skipping PowerShell profile modules installation..."
        return
    }

    Write-Output "Installing PowerShell profile modules..."

    Set-PSRepository PSGallery -InstallationPolicy Trusted

    Install-Module Pscx -Scope CurrentUser -AllowClobber
    Install-Module PSReadLine -RequiredVersion 2.1.0
    Install-Module PSEverything
    Install-Module -Name PSFzf
    Import-Module Get-GitHubSubFolderOrFile

    $modulesPath = $PROFILE.CurrentUserAllHosts -replace "[^\\]*.ps1$","Modules\"
    $lazyAdminModulePath = Join-Path $modulesPath "LazyAdmin"
    mkdir -p $lazyAdminModulePath

    Get-GitHubSubFolderOrFile -gitUrl "https://github.com/BornToBeRoot/PowerShell" -repoPathToExtract "Module/LazyAdmin" -destPath $lazyAdminModulePath

    $optimizePowerShellStartupScript = (New-Object System.Net.WebClient).DownloadString(
            "https://raw.githubusercontent.com/BornToBeRoot/PowerShell/master/Scripts/OptimizePowerShellStartup.ps1")
    $optimizePowerShellStartupScript = $optimizePowerShellStartupScript `
        -replace 'Write-Host -Object "Press any key.*"\r?\n', ''
    $optimizePowerShellStartupScript = $optimizePowerShellStartupScript `
        -replace '\[void\]\$host\.UI\.RawUI\.ReadKey\("NoEcho,IncludeKeyDown"\)', ''
    . ([Scriptblock]::Create($optimizePowerShellStartupScript)) | Out-Null
}

if (-not $Install -and $NonInteractive) {
    $Install = @('All')
}

if ($Install) {
    Write-Output "Starting system bootstrap process..."
    if (-not $NonInteractive) {
        Write-Output "Interactive mode enabled - you will be asked before each step."
    }

    $validInstallSteps = @(
        'AdminCheck',
        'SetExecutionPolicy',
        'DisablePowerShellTelemetry',
        'DisableClaudeCodeTelemetry',
        'WinGetModule',
        'Chocolatey',
        'RequiredApps',
        'Profile',
        'ProfileModules',
        'LoadProfile',
        'OpenSSH',
        'SSHService',
        'SSHFirewallRule',
        'All'
    )

    $unknownInstallSteps = $Install | Where-Object { $_ -notin $validInstallSteps }
    if ($unknownInstallSteps) {
        throw "Unknown install step(s): $($unknownInstallSteps -join ', '). Valid values are: $($validInstallSteps -join ', ')"
    }

    Write-Output "Running install step: AdminCheck"
    Assert-Administrator

    Invoke-InstallStep 'SetExecutionPolicy' { Set-UnrestrictedExecutionPolicy }
    Invoke-InstallStep 'DisablePowerShellTelemetry' { Disable-PowerShellTelemetry }
    Invoke-InstallStep 'DisableClaudeCodeTelemetry' { Disable-ClaudeCodeTelemetry }

    Invoke-InstallStep 'WinGetModule' { Install-WinGetModule }
    Invoke-InstallStep 'Chocolatey' { Install-Chocolatey }

    Invoke-InstallStep 'RequiredApps' { Import-Module C:\ProgramData\chocolatey\helpers\chocolateyProfile.psm1; Install-RequiredApps; refreshenv }

    Invoke-InstallStep 'Profile' { Install-Profile }
    Invoke-InstallStep 'ProfileModules' { Install-ProfileModules }
    Invoke-InstallStep 'LoadProfile' { . $profile }

    Invoke-InstallStep 'OpenSSH' { Install-OpenSSH }
    Invoke-InstallStep 'SSHService' { Configure-SSHService }
    Invoke-InstallStep 'SSHFirewallRule' { Configure-SSHFirewallRule }

    Write-Output "System bootstrap process completed."
}
