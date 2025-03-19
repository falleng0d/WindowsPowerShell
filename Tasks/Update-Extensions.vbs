Option Explicit

Dim WshShell
Set WshShell = CreateObject("WScript.Shell")

' Run windsurf extension update
WshShell.Run "windsurf --update-extensions", 0, true

' Run VS Code extension update
WshShell.Run "code --update-extensions", 0, true

' Run VS Code Insiders extension update
WshShell.Run "code-insiders --update-extensions", 0, true

' Upgrade VS Code Insiders to latest version
WshShell.Run "choco upgrade vscode-insiders", 0, true
