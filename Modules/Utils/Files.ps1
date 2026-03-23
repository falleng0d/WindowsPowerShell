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

function BackUp-Profile {
    Param([string]$destination = $backupHome)
    if (!(Test-Path $destination)) {
        New-Item -Path $destination -ItemType directory -Force | Out-Null
    }

    $date = Get-Date -Format s
    $backupName = "{0}.{1}.{2}.{3}" -f $env:COMPUTERNAME, $env:USERNAME,
    (Replace-InvalidFileCharacters -stringIn $date.ToString() -replacementChar "-"),
    (Split-Path -Path $PROFILE -Leaf)

    Copy-Item -Path $profile -Destination "$destination\$backupName" -Force
}

function Copy-Fast {
    param (
        [Parameter(Mandatory = $true)] [string]$Source,
        [Parameter(Mandatory = $true)] [string]$Destination
    )

    robocopy $Source $Destination /E /Z /R:5 /W:5 /NP /MT:8
}

function CDBack {
    Set-Location ..
}
