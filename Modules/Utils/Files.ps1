function Get-Properties {
    param ([Parameter(Position = 0, ValueFromPipeline = $True)]$obj)
    Format-List -Property * -InputObject $obj
}

function New-File {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path
    )

    if (Test-Path -Path $Path) {
        (Get-Item -Path $Path).LastWriteTime = Get-Date
    }
    else {
        New-Item -ItemType File -Path $Path
    }
}

function CDBack {
    Set-Location ..
}
