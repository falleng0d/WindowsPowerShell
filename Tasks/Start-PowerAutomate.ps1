if (-not (Get-Process -Name PAD.Console.Host -ErrorAction silentlycontinue )) {
    Start-Process `
        -WindowStyle Hidden `
        -FilePath "C:\Program Files (x86)\Power Automate Desktop\PAD.Console.Host.exe"
    # wait for process to start
    while (-not (Get-Process -Name PAD.Console.Host -ErrorAction silentlycontinue)) {
        Start-Sleep -Milliseconds 100
    }
    # wait for window to be created
    while (-not (Get-Process -Name PAD.Console.Host -ErrorAction silentlycontinue).MainWindowTitle) {
        Start-Sleep -Milliseconds 100
    }
    $process = Get-Process -Name PAD.Console.Host -ErrorAction silentlycontinue
    $process.CloseMainWindow()
}
