Option Explicit

Dim WshShell
Set WshShell = CreateObject("WScript.Shell")

' Run windsurf extension update
WshShell.Run "windsurf --update-extensions", 0, true

' Run VS Code extension update
WshShell.Run "code --update-extensions", 0, true
