function Get-HotspotTetheringManager {
    Add-Type -AssemblyName System.Runtime.WindowsRuntime -ErrorAction SilentlyContinue

    $networkInformationType = [type]::GetType('Windows.Networking.Connectivity.NetworkInformation, Windows, ContentType=WindowsRuntime', $false)
    $tetheringManagerType = [type]::GetType('Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager, Windows, ContentType=WindowsRuntime', $false)

    if (-not $networkInformationType -or -not $tetheringManagerType) {
        throw 'Mobile Hotspot APIs are not available in this PowerShell session.'
    }

    $connectionProfile = $networkInformationType::GetInternetConnectionProfile()
    if (-not $connectionProfile) {
        throw 'No active internet connection profile was found.'
    }

    $tetheringManagerType::CreateFromConnectionProfile($connectionProfile)
}

function Wait-WinRtAsyncOperation {
    param(
        [Parameter(Mandatory = $true)]
        $Operation,

        [Parameter(Mandatory = $true)]
        [type]$ResultType
    )

    Add-Type -AssemblyName System.Runtime.WindowsRuntime -ErrorAction SilentlyContinue

    $asTaskMethod = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
            $_.Name -eq 'AsTask' -and
            $_.IsGenericMethod -and
            $_.GetParameters().Count -eq 1 -and
            $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
        } | Select-Object -First 1)

    if (-not $asTaskMethod) {
        throw 'Unable to convert WinRT async operation to a .NET task.'
    }

    $task = $asTaskMethod.MakeGenericMethod($ResultType).Invoke($null, @($Operation))
    $task.Wait(-1) | Out-Null
    $task.Result
}

function Enable-Hotspot {
    $tetheringManager = Get-HotspotTetheringManager
    $state = $tetheringManager.TetheringOperationalState.ToString()

    if ($state -notmatch 'On') {
        $operationResultType = [type]::GetType('Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult, Windows, ContentType=WindowsRuntime', $false)
        if (-not $operationResultType) {
            throw 'Mobile Hotspot result APIs are not available in this PowerShell session.'
        }

        Wait-WinRtAsyncOperation -Operation ($tetheringManager.StartTetheringAsync()) -ResultType $operationResultType
    }
}

function Disable-Hotspot {
    $tetheringManager = Get-HotspotTetheringManager
    $state = $tetheringManager.TetheringOperationalState.ToString()

    if ($state -match 'On') {
        $operationResultType = [type]::GetType('Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult, Windows, ContentType=WindowsRuntime', $false)
        if (-not $operationResultType) {
            throw 'Mobile Hotspot result APIs are not available in this PowerShell session.'
        }

        Wait-WinRtAsyncOperation -Operation ($tetheringManager.StopTetheringAsync()) -ResultType $operationResultType
    }
}
