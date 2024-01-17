if (-not (Get-Process -Name TaskLayout64 -ErrorAction silentlycontinue )){ 
    Start-Process "C:\Program Files\TaskLayout\TaskLayout64.exe"
}
