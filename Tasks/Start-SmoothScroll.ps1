if (-not (Get-Process -Name SmoothScroll -ErrorAction silentlycontinue )){ 
    Start-Process -WindowStyle Minimized -FilePath "C:\Users\falleng0d\AppData\Local\SmoothScroll\app-1.2.4.0\SmoothScroll.exe"
}
