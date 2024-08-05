Set oShell = CreateObject("Wscript.Shell") 
Dim strArgs
strArgs = "cmd /c Start-Ditto.bat"
oShell.Run strArgs, 0, false

Imports System.Management
