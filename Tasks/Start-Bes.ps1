if (-not (Get-Process -Name bes -ErrorAction silentlycontinue )) {
    Start-Process -WindowStyle Minimized -FilePath "C:\tools\BES_1.7.8\BES.exe" -ArgumentList @('"C:\Program Files (x86)\Mobile Mouse\Mobile Mouse.exe"','-a','65;5;1')
}
