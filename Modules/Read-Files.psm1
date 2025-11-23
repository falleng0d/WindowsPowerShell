function Read-File {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [int]$MaxTokens = 5000,
        [Parameter(Mandatory = $false)]
        [int]$StartLine = 1,
        [Parameter(Mandatory = $false)]
        [int]$EndLine = 0
    )

    $originalPath = $Path
    # convert path slashes to unix style
    $Path = $Path -replace "\\", "/"

    $fileExists = Test-Path -Path $Path
    if (-not $fileExists) {
        Write-Host "File not found: $Path"
        return
    }

    $totalLines = Measure-Object -Line $Path | Select-Object -ExpandProperty Lines
    $relativePath = ''
    $printPath = $Path

    try {
        if ([System.IO.Path]::IsPathRooted($originalPath)) {
            $currentDir = (Get-Location).ProviderPath
            $absolutePath = [System.IO.Path]::GetFullPath($originalPath)
            $relativePath = Resolve-Path -Path $absolutePath -Relative
            $relativePath = $relativePath -replace "\\", "/"
            $printPath = $relativePath
        }
    } catch {}

    $result = $(rg --color=never --heading --line-number --crlf ".*" $Path)

    if ($StartLine -gt 1) {
        if ($EndLine -gt 0) {
            $result = $result | Select-Object -Skip ($StartLine - 1) -First ($EndLine - $StartLine + 1)
        } else {
            $result = $result | Select-Object -Skip ($StartLine - 1)
        }
    } else {
        if ($EndLine -gt 0) {
            $result = $result | Select-Object -First $EndLine
        }
    }

    $truncatedResult = $(echo $result | token-trimmer --truncate $MaxTokens)
    $totalResultLines = $result | Measure-Object -Line | Select-Object -ExpandProperty Lines
    $truncatedResultLines = $truncatedResult | Measure-Object -Line | Select-Object -ExpandProperty Lines
    $truncatedLines = $totalResultLines - $truncatedResultLines
    $lastLineNumber = $startLine + $truncatedResultLines - 1

    if ($truncatedLines -gt 0) {
        echo "$printPath [$StartLine-$lastLineNumber] (truncated $truncatedLines lines due to token limit)"
    } else {
        echo "$printPath [$StartLine-$lastLineNumber]"
    }

    echo $truncatedResult
}

function Read-Files {
    param (
        [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
        [string[]]$Paths,
        [Parameter(Mandatory = $false)]
        [int]$MaxTokens = 5000,
        [Parameter(Mandatory = $false)]
        [int]$StartLine = 1,
        [Parameter(Mandatory = $false)]
        [int]$EndLine = 0
    )

    foreach ($Path in $Paths) {
        try {
            Read-File -Path $Path -MaxTokens $MaxTokens -StartLine $StartLine -EndLine $EndLine
        } catch {
            Write-Host "Error reading ${Path}: $_"
        }
    }
}


Set-Alias -Name catx -Value Read-Files
Set-Alias -Name view -Value Read-Files

Export-ModuleMember -Alias *

Export-ModuleMember -Function Read-File
Export-ModuleMember -Function Read-Files
