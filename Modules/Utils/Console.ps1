function Test-ConsoleHost {
    if (($host.Name -match 'consolehost')) { $true }
    Else { $false }
}

function Enter-Admin {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerb', '')]
    param()

    Start-Process -Verb RunAs (Get-Process -Id $PID).Path
}
