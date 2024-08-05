@echo off

setlocal enabledelayedexpansion

set _CSV=ToStart.csv
set _SkipFirstLine=1

set _Minimize=""
set _Process=""
set _WorkingDir=""
set _Args=""
set _Path=""

for /f "skip=%_SkipFirstLine% tokens=1-5 delims=," %%a in (%_CSV%) do (
    set _Minimize=%%a
    set _Process=%%b
    set _WorkingDir=%%c
    set _Args=%%d
    set _Path=%%e
    
    if !_Args! == 0 set _Args=""

    echo Minimize=!_Minimize!
    echo Process=!_Process!
    echo WorkingDir=!_WorkingDir!
    echo Args=!_Args!
    echo Path=!_Path!

    if !_Args! == "" (
        echo tasklist
        tasklist /FI "IMAGENAME eq !_Process!" | findstr /C:!_Process! > nul
    ) else (
        echo tasklist findstr
        tasklist /FI "IMAGENAME eq !_Process!" /V | findstr /C:!_Args! > nul
    )
    
    if errorlevel 1 (
        cd %USERPROFILE%
        if !_Minimize! == 1 (
            if !_WorkingDir! == "" (
                echo start "" /I /B /MIN "!_Path!" !_Args!
                start "" /I /B /MIN "!_Path!" !_Args!
            ) else (
                cd !_WorkingDir!
                echo cd !_WorkingDir!
                echo start "" /I /B /MIN "!_Path!" !_Args!
                start "" /I /B /MIN "!_Path!" !_Args!
            )
        ) else (
            echo start "" /I /B "!_Path!" !_Args!
            start "" /I /B "!_Path!" !_Args!
        )
    )

    echo.
)
