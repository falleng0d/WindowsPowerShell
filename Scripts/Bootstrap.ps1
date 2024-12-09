# Check and set execution policy if needed
if ((Get-ExecutionPolicy) -ne "Unrestricted") {
    Write-Output "Setting execution policy to unrestricted..."
    Set-ExecutionPolicy unrestricted
} else {
    Write-Output "Execution policy is already unrestricted."
}

# Install chocolatey if not already installed
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Chocolatey..."
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    Write-Output "Enabling global confirmation for chocolatey..."
    choco feature enable -n allowGlobalConfirmation
} else {
    Write-Output "Chocolatey is already installed."
}

# Install apps if not present
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

# Install OpenSSH if not present
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

# Configure SSH service
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

# Configure firewall rule
if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
    Write-Output "Creating firewall rule 'OpenSSH-Server-In-TCP'..."
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
} else {
    Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' already exists."
}

# Install Windows Terminal if not present
if (!(Get-Command wt -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Windows Terminal..."
    winget install Microsoft.WindowsTerminal
} else {
    Write-Output "Windows Terminal is already installed."
}

# Debloat Windows (this step requires manual intervention)
$debloaterPath = "~/Downloads/Windows10Debloater"
if (!(Test-Path $debloaterPath)) {
    Write-Output "Downloading Windows10Debloater..."
    Set-Location ~/Downloads
    git clone https://github.com/Sycnex/Windows10Debloater
    Set-Location Windows10Debloater
    Write-Output "Starting Windows10DebloaterGUI. Please make your selections in the GUI."
    .\Windows10DebloaterGUI.ps1
} else {
    .\Windows10DebloaterGUI.ps1
}