Set oShell = CreateObject("Wscript.Shell") 
Dim strArgs
strArgs = "cmd /c Start-Apps.bat"
oShell.Run strArgs, 0, false

'Dim strArgs2
'strArgs2 = "cmd /c Start-RemoteControl.bat"
'oShell.Run strArgs2, 0, false
