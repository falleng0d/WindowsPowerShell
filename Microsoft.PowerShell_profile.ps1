#requires -version 2.0

using namespace System.Management.Automation
using namespace System.Management.Automation.Language

# Check if the console output supports virtual terminal processing or it's redirected
$isNonInteractive = ([Environment]::GetCommandLineArgs() -like '*-NonInteractive*'  `
                        -or [Environment]::GetCommandLineArgs() -like '*-File*' `
                        -or -not $host.UI.SupportsVirtualTerminal) `
                     -and -not ([Environment]::GetCommandLineArgs() -like '*powershell-integration.ps1*') `

$profileFolder = $profile.CurrentUserAllHosts -replace "\\[^\\]*.ps1$",""
$profileFolderName = $profile.CurrentUserAllHosts -replace "[^\\]*.ps1$","" | Split-Path -Leaf

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

$Modules = $PROFILE.CurrentUserAllHosts -replace "[^\\]*.ps1$","Modules"

Import-Module -Name $Modules\VariableDefinitions.psm1
Import-Module -Name $Modules\Utils.psm1 -DisableNameChecking
Import-Module -Name $Modules\AliasDefinitions.psm1
Import-Module -Name $Modules\Read-Files.psm1 -DisableNameChecking
Import-Module -Name $Modules\RemoveNodeModules.psm1

#Variables
New-Variable -Name doc -Value "$home\Documents" `
    -Description "My documents library. Profile created" `
    -Option ReadOnly -Scope "Global" -ErrorAction 'Ignore'
New-Variable -Name psdir -Value "$profileFolder" `
    -Description "Power shell directory" `
    -Option ReadOnly -Scope "Global" -ErrorAction 'Ignore'
New-Variable -Name tpath -Value "$profileFolder\Transcripts" `
    -Option ReadOnly -ErrorAction 'Ignore'
New-Variable -Name history -Value ((Get-PSReadlineOption).HistorySavePath) `
    -Option ReadOnly -ErrorAction 'Ignore'

# Provides easy access to the scripts in the Scripts folder.
# The full path of a script can be accessed as `$Scripts.ScriptName`
$_scriptFiles = Get-ChildItem -Path "$psdir\Scripts" -Recurse -Include *.ps1
$scriptPaths = @{}
foreach ($script in $_scriptFiles) {
    $scriptName = $script.BaseName
    $scriptPath = $script.FullName
    $scriptPaths[$scriptName] = $scriptPath
}
$Scripts = New-Object PSObject -Property $scriptPaths
$Global:Scripts = $Scripts

if (!(Test-Path variable:backupHome)) {
    new-variable -name backupHome -value "$profileFolder\profileBackup" `
        -Description "Folder for profile backups. Profile created" `
        -Option ReadOnly -Scope "Global"
}

# PS_Drives
if (-not (Get-PSDrive -Name Mod -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name Mod -Root ($env:PSModulePath -split ';')[0] `
        -PSProvider FileSystem -ErrorAction SilentlyContinue | Out-Null
}

function Add-Path($Path) {
    $Path = [Environment]::GetEnvironmentVariable("PATH", "Machine") + [IO.Path]::PathSeparator + $Path
    [Environment]::SetEnvironmentVariable( "Path", $Path, "Machine" )
}

function Get-Path() {
    [Environment]::GetEnvironmentVariable("PATH", "Machine")
}

Function Replace-InvalidFileCharacters {
    Param ($stringIn,
        $replacementChar)

    # Replace-InvalidFileCharacters "my?string"
    # Replace-InvalidFileCharacters (get-date).tostring()

    $stringIN -replace "[$( [System.IO.Path]::GetInvalidFileNameChars() )]", $replacementChar
}

Function Get-TranscriptName {
    $date = Get-Date -format s
    "{0}.{1}.{2}.txt" -f "PowerShell_Transcript", $env:COMPUTERNAME,
    (rifc -stringIn $date.ToString() -replacementChar "-")
}

Function Get-WebPage {
    Param($url)
    # Get-WebPage -url (Get-CmdletFwLink get-process)
    (New-Object -ComObject shell.application).open($url)
}

Function Get-ForwardLink {
    Param($cmdletName)
    # Get-WebPage -url (Get-CmdletFwLink get-process)
    (Get-Command $cmdletName).helpuri

}

<# Function BackUp-Profile {
    Param([string]$destination = $backupHome)
    if (!(test-path $destination))
    { New-Item -Path $destination -ItemType directory -force | out-null }

    $date = Get-Date -Format s
    $backupName = "{0}.{1}.{2}.{3}" -f $env:COMPUTERNAME, $env:USERNAME,
        (rifc -stringIn $date.ToString() -replacementChar "-"),
        (Split-Path -Path $PROFILE -Leaf)

    copy-item -path $profile -destination "$destination\$backupName" -force
} #>

Filter Scrub {
    <#
    .Synopsis
        Clean input strings
    .Description
        This command is designed to take string input and scrub the data, filtering
        out blank lines and removing leading and trailing spaces. The default behavior
        is to write the object to the pipeline, however you can use -PropertyName to
        add a property name value. If you use this parameter, the assumption is that
        contents of the text file are a single item like a computer name.
    .Example
        PS C:\> get-content c:\work\computers.txt | scrub | foreach { get-wmiobject win32_operatingsystem -comp $_}
    .Example
        PS C:\> get-content c:\work\computers.txt | scrub -PropertyName computername | test-connection
    #>

    [cmdletbinding()]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [string[]]$InputObject,
        [string]$PropertyName
    )

    #filter out blank lines
    $InputObject | where { $_ -match "\w+" } |
    ForEach-Object {
        #trim off trailing and leading spaces
        $clean = $_.Trim()
        if ($PropertyName) {
            #create a customobject property
            New-Object -TypeName PSObject -Property @{$PropertyName = $clean }
        }
        else {
            #write the clean object to the pipeline
            $clean
        }
    } #foreach

} #close Scrub

Function Get-EnumValues {
    # get-enumValues -enum "System.Diagnostics.Eventing.Reader.StandardEventLevel"
    Param([string]$enum)
    $enumValues = @{}
    [enum]::getvalues([type]$enum) |
    ForEach-Object {
        $enumValues.add($_, $_.value__)
    }
    $enumValues
}

Function Get-PropOrNull {
    param($thing, [string]$prop)
    Try {
        $thing.$prop
    }
    Catch {
    }
}

function Get-AttrsToArray {
    param (
        $item
    )
    $attobj = $item.Attributes
    $attrs = $attobj.ToString().Split(",").Trim()
    $attrs
}

function hh {
    $find = $args
    Write-Host "Finding in full history using {`$_ -like `"*$find*`"}"
    cat (Get-PSReadlineOption).HistorySavePath | ? { $_ -like
        "*$find*" } | Get-Unique | fzf
}

function List-Dir-Numbered {
    $a = @(Get-ChildItem)
    for ($i = 0; $i -le ($a.length - 1); $i += 1) {
        "$($i): $($a[$i].Name)"
    }
}

function Set-DropboxIgnored {
    param (
        [Parameter(Mandatory = $true)] [string]$Pattern,
        [string]$RootPath = "$home\Dropbox",
        [Parameter(Mandatory = $false)] [switch]$Test = $false,
        [Parameter(Mandatory = $false)] [switch]$EnableSync = $false,
        [Parameter(Mandatory = $false)] [switch]$IncludeFiles = $false,
        [Parameter(Mandatory = $false)] [switch]$IncludeDirectories = $false
    )

    foreach ($item in Get-ChildItem -Attributes Directory, Archive $RootPath) {
        #Write-Host "$($item.Name) $($item.Attributes) $($item -is [System.IO.FileInfo])"
        $attrs = Get-AttrsToArray $item
        $marchedDir = ($item -is [System.IO.DirectoryInfo]) -and ($IncludeDirectories -eq $true)
        $marchedFile = ($item -is [System.IO.FileInfo]) -and ($IncludeFiles -eq $true)
        if ($item.Name -match $Pattern -and ($marchedDir -or $marchedFile)) {
            Write-Host -ForegroundColor Green "Matched $($item.FullName)"
            if ($Test -eq $false) {
                if ($EnableSync -eq $false) {
                    Write-Host -ForegroundColor Red "Stopped syncing $($item.FullName)"
                    Set-Content -LiteralPath $item.FullName -Stream com.dropbox.ignored -Value 1
                }
                else {
                    Write-Host -ForegroundColor Yellow "Started syncing $($item.Name)"
                    Clear-Content -LiteralPath $item.FullName -Stream com.dropbox.ignored
                }
            }
            else {
                if ($EnableSync -eq $false) {
                    Write-Host -ForegroundColor Red "Stopped syncing $($item.FullName)"
                }
                else {
                    Write-Host -ForegroundColor Yellow "Started syncing $($item.Name)"
                }
            }
        }
        else {
            if ($item -is [System.IO.DirectoryInfo]) {
                #Write-Host "Going into $($item.FullName)"
                Set-DropboxIgnored -Pattern $Pattern -RootPath $item.FullName -EnableSync:$EnableSync -Test:$Test -IncludeFiles:$IncludeFiles -IncludeDirectories:$IncludeDirectories
            }
        }
    }
}

Function Join-ffmpegMp4 {
    param (
        [Parameter(
            ValueFromPipeline = $true
        )]
        [ValidateScript({
                $_.Name -match '\.mp4'
            })]
        [System.IO.FileInfo[]]$Files,
        [System.IO.DirectoryInfo]$TempFolder,
        [System.IO.FileInfo]$OutputFile
    )
    Begin {
        [string[]]$outFiles = @()
    }
    Process {
        foreach ($file in $Files) {
            # Create all the tmp files
            $tmpFile = "$($TempFolder.FullName)$($file.BaseName).ts"
            & ffmpeg -y -i "$($file.FullName)" -c copy -bsf:v h264_mp4toannexb -f mpegts $tmpFile -v quiet
            [string[]]$outFiles += $tmpFile
        }
    }
    End {
        # Join them
        $concatString = "concat:" + ($outFiles -join '|')
        & ffmpeg -f mpegts -i $concatString -c copy -bsf:a aac_adtstoasc $OutputFile -v quiet
        # Clean up
        foreach ($file in $outFiles) {
            Remove-Item $file -Force
        }
    }
}

function Enable-Hotspot {
    $connectionProfile = [Windows.Networking.Connectivity.NetworkInformation, Windows.Networking.Connectivity, ContentType = WindowsRuntime]::GetInternetConnectionProfile()
    $tetheringManager = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager, Windows.Networking.NetworkOperators, ContentType = WindowsRuntime]::CreateFromConnectionProfile($connectionProfile)

    # Check whether Mobile Hotspot is enabled
    $tetheringManager.TetheringOperationalState

    if (-not $val -match 'On') {
        # Start Mobile Hotspot
        Await ($tetheringManager.StartTetheringAsync()) ([Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult])
    }
}

function Disable-Hotspot {
    $connectionProfile = [Windows.Networking.Connectivity.NetworkInformation, Windows.Networking.Connectivity, ContentType = WindowsRuntime]::GetInternetConnectionProfile()
    $tetheringManager = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager, Windows.Networking.NetworkOperators, ContentType = WindowsRuntime]::CreateFromConnectionProfile($connectionProfile)

    # Check whether Mobile Hotspot is enabled
    $tetheringManager.TetheringOperationalState

    if ($val -match 'On') {
        # Stop Mobile Hotspot
        Await ($tetheringManager.StopTetheringAsync()) ([Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult])
    }
}

function Set-PathVariable {
    param (
        [Parameter(Mandatory = $false)] [string]$AddPath,
        [Parameter(Mandatory = $false)] [string]$RemovePath
    )
    $regexPaths = @()
    if ($PSBoundParameters.Keys -contains 'AddPath') {
        $regexPaths += [regex]::Escape($AddPath)
    }

    if ($PSBoundParameters.Keys -contains 'RemovePath') {
        $regexPaths += [regex]::Escape($RemovePath)
    }

    $arrPath = $env:Path -split ';'
    foreach ($path in $regexPaths) {
        $arrPath = $arrPath | Where-Object { $_ -notMatch "^$path\\?" }
    }
    $env:Path = ($arrPath + $addPath) -join ';'
}

function Copy-Fast {
    param (
        [Parameter(Mandatory = $true)] [string]$Source,
        [Parameter(Mandatory = $true)] [string]$Destination
    )

    robocopy $Source $Destination /E /Z /R:5 /W:5 /NP /MT:8
}

function Show-Notification {
    [cmdletbinding()]
    Param (
        [string]
        $ToastTitle,
        [string]
        [parameter(ValueFromPipeline)]
        $ToastText
    )

    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
    $Template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)

    $RawXml = [xml] $Template.GetXml()
    ($RawXml.toast.visual.binding.text | where { $_.id -eq "1" }).AppendChild($RawXml.CreateTextNode($ToastTitle)) > $null
    ($RawXml.toast.visual.binding.text | where { $_.id -eq "2" }).AppendChild($RawXml.CreateTextNode($ToastText)) > $null

    $SerializedXml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $SerializedXml.LoadXml($RawXml.OuterXml)

    $Toast = [Windows.UI.Notifications.ToastNotification]::new($SerializedXml)
    $Toast.Tag = "PowerShell"
    $Toast.Group = "PowerShell"
    $Toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(1)

    $Notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("PowerShell")
    $Notifier.Show($Toast);
}

#Commands

# If (tch) {
#     Start-Transcript -Path (Join-Path -Path $tpath -ChildPath $(Get-TranscriptName))
# }

# BackUp-Profile
function Get-Tree($Path, $Include = '*') {
    @(Get-Item $Path -Include $Include -Force) +
        (Get-ChildItem $Path -Recurse -Include $Include -Force) |
    sort pspath -Descending -unique
}

function Remove-Tree($Path, $Include = '*') {
    Get-Tree $Path $Include | Remove-Item -force -recurse
}

function Stop-Process-Gracefully {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProcessName
    )

    $process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    if ($process) {
        # Stop the process gracefully
        Write-Output $process | Foreach-Object { $_.CloseMainWindow() | Out-Null } | stop-process -force
        foreach ($p in $process) {
            $p.CloseMainWindow()
            Write-Output "Closing window for $($p.ProcessName)"
            Stop-Process -Id $p.Id -ErrorAction SilentlyContinue
            Write-Output "Stopped $($p.ProcessName)"
        }
    } else {
        Write-Output "$ProcessName is not running"
    }
}

function RecreateLinkInteractive {
	param (
		[string]$FileName
	)

	$filePaths = Search-Everything -Global $FileName

	# If $filePaths is not a array, make it one
	if ($filePaths -isnot [array]) {
		$filePaths = @($filePaths)
	}

	Write-Output "Found $($filePaths.Count) paths for $FileName"
	Write-Output "Paths found:"
	$filePaths | ForEach-Object { Write-Output $_ }

	# Select the first path
	$filePath = $filePaths[0]

	# Ask the user if he wants to recreate the link
	$answer = Read-Host "Do you want to recreate $($filePath)? (Y/n)"
	if ($answer -ne "n" -or $answer -ne "N") {
        # Copy the filename without extension to the clipboard
	    $noextension = $FileName.Replace(".lnk", "")
	    $noextension | Set-Clipboard
	    Write-Output "Copied $noextension to the clipboard"

        # Open the old link for recreation
		Invoke-Item $filePath

        # Delete existing links
	    foreach ($filePath in $filePaths) {
            Write-Output "Deleting $($filePath)"
		    Remove-Item $filePath
	    }
	}
}

function RecreateLinksInteractive {
	cd $env:USERPROFILE\Desktop

	$fileNames = rg -e 'Chrome' --glob '*.lnk' -aw --crlf --max-depth 1 --files-with-matches
	foreach ($filename in $fileNames) {
		Write-Output "Recreating links for $filename"
		RecreateLinksInteractive "$filename"
	}
}

if ($isNonInteractive -eq $false) {
    Import-Module -Name $Modules\AutoComplete.psm1 -DisableNameChecking -Force
    refreshenv | out-null
    oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/json.omp.json" | Invoke-Expression | out-null
}

if ($env:TERM_PROGRAM -eq "kiro") { . "$(kiro --locate-shell-integration-path pwsh)" }
