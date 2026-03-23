function Repair-InvalidFileCharacters {
    Param (
        $stringIn,
        $replacementChar
    )

    $stringIn -replace "[$([System.IO.Path]::GetInvalidFileNameChars())]", $replacementChar
}

function Get-TranscriptName {
    $date = Get-Date -format s
    "{0}.{1}.{2}.txt" -f "PowerShell_Transcript", $env:COMPUTERNAME,
    (Repair-InvalidFileCharacters -stringIn $date.ToString() -replacementChar "-")
}

filter Scrub {
    [cmdletbinding()]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [string[]]$InputObject,
        [string]$PropertyName
    )

    $InputObject | Where-Object { $_ -match "\w+" } |
    ForEach-Object {
        $clean = $_.Trim()
        if ($PropertyName) {
            New-Object -TypeName PSObject -Property @{$PropertyName = $clean }
        }
        else {
            $clean
        }
    }
}

function Get-EnumValues {
    Param([string]$enum)
    $enumValues = @{}
    [enum]::GetValues([type]$enum) |
    ForEach-Object {
        $enumValues.Add($_, $_.value__)
    }
    $enumValues
}

function Get-PropOrNull {
    param($thing, [string]$prop)
    try {
        $thing.$prop
    }
    catch {
    }
}
