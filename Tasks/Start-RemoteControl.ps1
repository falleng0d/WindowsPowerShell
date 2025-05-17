if (-not (Get-Process -Name remotecontrol -ErrorAction silentlycontinue))
 {
    Start-Process -FilePath "C:\Program Files\remotecontrol\remotecontrol.exe"

    # wait for process to start
    while (-not (Get-Process -Name remotecontrol -ErrorAction silentlycontinue)) {
        Start-Sleep -Milliseconds 100
    }

    # wait for window to be created
    while (-not (Get-Process -Name remotecontrol -ErrorAction silentlycontinue).MainWindowTitle) {
        Start-Sleep -Milliseconds 100
    }

    # minimize window
    Get-Process -Name remotecontrol | Set-WindowState -State MINIMIZE
}
