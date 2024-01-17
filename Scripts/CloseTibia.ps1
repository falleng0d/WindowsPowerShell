# close obs64 if it is running

Try {
    (Get-Process -Name obs64 -ErrorAction silentlycontinue).Kill()
} Catch {
    Write-Host "obs64 is not running"
}


# close client if it is running
Try {
    (Get-Process -Name client -ErrorAction silentlycontinue).Kill()
} Catch {
    Write-Host "Tibia is not running"
}

# close remotecontrol if it is running
