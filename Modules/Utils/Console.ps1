function Test-ConsoleHost {
    if (($host.Name -match 'consolehost')) { $true }
    Else { $false }
}

function Relaunch-Admin {
    Start-Process -Verb RunAs (Get-Process -Id $PID).Path
}
