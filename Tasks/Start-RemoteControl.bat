@echo off

set _Process=remotecontrol.exe

tasklist /FI "IMAGENAME eq %_Process%" /V | findstr /C:%_Process% > nul
if errorlevel 1 (
    cd C:\Users\falleng0d\Dropbox\Projects\remotecontrol\build\windows\x64\runner\Release
    explorer remotecontrol.exe
    cd /d %~dp0
    powershell -NoLogo -NonInteractive -NoProfile -File Minimize-RemoteControl.ps1
)
