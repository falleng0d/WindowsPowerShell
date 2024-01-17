$cmd = Get-CimInstance Win32_Process -Filter "name = 'AutoHotkey.exe' and CommandLine like '%virtual-desktop-enhancer%'"
if (-not $cmd ) { 
    Start-Process `
        -WindowStyle Minimized `
        -FilePath "C:\Program Files\AutoHotkey\AutoHotkey.exe" `
        -WorkingDirectory "C:\usr\virtual-desktop-enhancer\" `
        "C:\usr\virtual-desktop-enhancer\virtual-desktop-enhancer.ahk" 
}
