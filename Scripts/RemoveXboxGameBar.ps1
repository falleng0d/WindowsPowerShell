Get-AppxPackage | select-string xbox
Remove-AppxPackage 

dism /online /get-provisionedappxpackages | select-string packagename | select-string xbox | ForEach-Object {$_.Line.Split(':')[1]}

dism /online /remove-provisionedappxpackage /packagename:

Remove-AppxPackage Microsoft.XboxGameOverlay_1.54.4001.0_x64__8wekyb3d8bbwe
Remove-AppxPackage Microsoft.XboxGamingOverlay_5.822.6271.0_x64__8wekyb3d8bbwe


