function Test-ConsoleHost {
    if (($host.Name -match 'consolehost')) { $true }
    Else { $false }
}
function Invoke-Script-Uri {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptUri
    )
    $script = (New-Object System.Net.WebClient).DownloadString($ScriptUri)
    Invoke-Expression $script
}
function Relaunch-Admin { Start-Process -Verb RunAs (Get-Process -Id $PID).Path }
function Edit-Profile { code ($PROFILE.CurrentUserAllHosts -replace "[^\\]*.ps1$","") }
function Get-Properties {
    param ([Parameter(Position = 0, ValueFromPipeline = $True)]$obj)
    Format-List -Property * -InputObject $obj
}
function Reload-Profile {
    . $profile
}

function New-File {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Path
    )

    if (Test-Path -Path $Path) {
        (Get-Item -Path $Path).LastWriteTime = Get-Date
    } else {
        New-Item -ItemType File -Path $Path
    }
}

function CDBack { Set-Location .. }

# Creates a new scratch file on the scratch directory and opens it in
# idea editor. Accepts a file extension as a parameter. Names it "scratch-0000.ext"
# where 0000 is the next available number.
$scratchDirectory = "C:\Projects\scratch"
function New-Scratch {
    param(
        [Parameter()]
        [string]$Extension = "md"
    )

    if (-not (Test-Path -Path $scratchDirectory)) {
        New-Item -ItemType Directory -Path $scratchDirectory
    }

    $Extension = "." + $Extension.TrimStart(".")
    $counter = 0
    do {
        $fileName = "scratch-{0:D4}{1}" -f $counter, $Extension
        $filePath = Join-Path -Path $scratchDirectory -ChildPath $fileName
        $counter++
    } while (Test-Path -Path $filePath)

    New-Item -ItemType File -Path $filePath
    idea $filePath
}

function New-Symbolic-Link($target, $link) {
    New-Item -Path $link -ItemType SymbolicLink -Value $target
}

function New-Hard-Link($target, $link) {
    New-Item -Path $link -ItemType HardLink -Value $target
}

Export-ModuleMember -Function Test-ConsoleHost
Export-ModuleMember -Function Edit-Profile
Export-ModuleMember -Function Get-Properties
Export-ModuleMember -Function Relaunch-Admin
Export-ModuleMember -Function Invoke-Script-Uri
Export-ModuleMember -Function Reload-Profile
Export-ModuleMember -Function New-File
Export-ModuleMember -Function CDBack
Export-ModuleMember -Function New-Scratch
Export-ModuleMember -Function New-Symbolic-Link
Export-ModuleMember -Function New-Hard-Link
