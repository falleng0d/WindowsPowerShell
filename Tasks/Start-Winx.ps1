if (-not (Get-Process -Name winxcorners -ErrorAction silentlycontinue )) 
{
    Start-Process -WindowStyle Minimized -FilePath "C:\Program Files\WinXCorners\WinXCorners.exe"
}
