function hh {
    $find = $args
    Write-Host "Finding in full history using {`$_ -like `"*$find*`"}"
    Get-Content (Get-PSReadlineOption).HistorySavePath | Where-Object { $_ -like "*$find*" } | Get-Unique | fzf
}
