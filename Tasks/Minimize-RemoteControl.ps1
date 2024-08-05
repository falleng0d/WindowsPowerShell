# wait for window to be created
while (-not (Get-Process -Name remotecontrol -ErrorAction silentlycontinue).MainWindowTitle) {
    Start-Sleep -Milliseconds 100
}

# minimize window
Get-Process -Name remotecontrol | Set-WindowState -State MINIMIZE