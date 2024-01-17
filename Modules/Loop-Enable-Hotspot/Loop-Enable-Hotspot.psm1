Import-Module "../Async/Async.psm1"
function Loop-Enable-Hotspot {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)] [switch]$test = $false
    )

    $connectionProfile = [Windows.Networking.Connectivity.NetworkInformation, Windows.Networking.Connectivity, ContentType = WindowsRuntime]::GetInternetConnectionProfile()

    $tetheringManager = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager, Windows.Networking.NetworkOperators, ContentType = WindowsRuntime]::CreateFromConnectionProfile($connectionProfile)

    if ($Test -eq $true) { Write-Output "Tethering is started" }
    
     # Loops forever
    do {
        if ($Test -eq $true) { 
            Write-Output "TetheringOperationalState: " ($tetheringManager.TetheringOperationalState)
        }

        # Check whether Mobile Hotspot is enabled
        if (-not ($tetheringManager.TetheringOperationalState -match 'On')) {
            # Start Mobile Hotspot
            Start-Sleep 10
            if ($Test -eq $true) { Write-Output "Enabling hotspot..." }
            Await ($tetheringManager.StartTetheringAsync()) ([Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult])
        }
        
        Start-Sleep 3
    } while ($true)
}
