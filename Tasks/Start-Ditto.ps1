if (-not (Get-Process -Name ditto -ErrorAction silentlycontinue )){ 
    Start-Process -WindowStyle Minimized -FilePath "C:\Program Files\Ditto\Ditto.exe"
}
