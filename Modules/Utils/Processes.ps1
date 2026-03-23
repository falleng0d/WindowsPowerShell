function Stop-ProcessGracefully {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProcessName
    )

    $process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    if ($process) {
        Write-Output $process | ForEach-Object { $_.CloseMainWindow() | Out-Null } | Stop-Process -Force
        foreach ($p in $process) {
            $p.CloseMainWindow()
            Write-Output "Closing window for $($p.ProcessName)"
            Stop-Process -Id $p.Id -ErrorAction SilentlyContinue
            Write-Output "Stopped $($p.ProcessName)"
        }
    }
    else {
        Write-Output "$ProcessName is not running"
    }
}
