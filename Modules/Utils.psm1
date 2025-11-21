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

function Get-VsCodeExtension {
    param (
        [Parameter(Mandatory=$true)]
        [String]$extensionName
    )
    
    begin {
        $body=@{
            filters = ,@{
            criteria =,@{
                    filterType=7
                    value = $null
                }
            }
            flags = 1712
        }
    }
    process {
        write-verbose "getting $($extensionName)"
        $response =  try {
            $body.filters[0].criteria[0].value = $extensionName
            $Query =  $body|ConvertTo-JSON -Depth 4
            (Invoke-WebRequest -Uri "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery?api-version=6.0-preview" -ErrorAction Stop -Body $Query -Method Post -ContentType "application/json")
        } catch [System.Net.WebException] {
            Write-Verbose "An exception was caught: $($_.Exception.Message)"
            $_.Exception.Response
        }
        $statusCodeInt = [int]$response.StatusCode

        if ($statusCodeInt -ge 400) {
            Write-Warning "API Error :  $($response.StatusDescription)"
            return
        }
        $ObjResults = ($response.Content | ConvertFrom-Json).results

        If ($ObjResults.resultMetadata.metadataItems.count -ne 1) {
            Write-Warning "Extension not found"
            return
        }

        $extension = $ObjResults.extensions

        $publisher = $extension.publisher.publisherName
        $extensionName = $extension.extensionName
        $version = $extension.versions[0].version

        $uri = "$($extension.Versions[0].assetUri)/Microsoft.VisualStudio.Services.VSIXPackage"
        Invoke-WebRequest -uri $uri -OutFile "$publisher.$extensionName.$version.VSIX"
    }
}

function Get-RedirectedUrl {
    param (
        [Parameter(Mandatory=$true)]
        [String]$URL
    )

    $request = [System.Net.WebRequest]::Create($url)
    $request.AllowAutoRedirect=$false
    $response=$request.GetResponse()

    If ($response.StatusCode -eq "Found")
    {
        $response.GetResponseHeader("Location")
    }
}

function wget {
    param (
        [Parameter(Mandatory=$true)]
        [String]$URL
    )

    $FileName = [System.IO.Path]::GetFileName((Get-RedirectedUrl $URL))

    Write-Host Downloading $FileName from $URL

    Invoke-WebRequest -Uri $URL -OutFile $FileName
}

function export {
    <#
    .SYNOPSIS
    Mimics the bash export command to set environment variables.

    .DESCRIPTION
    Sets environment variables in PowerShell using bash-style syntax.
    Supports formats like: export VAR=VALUE or export VAR="VALUE"

    .PARAMETER Expression
    The variable assignment expression (e.g., "VAR=VALUE" or "VAR='VALUE'")

    .EXAMPLE
    export PATH=/usr/local/bin:$PATH
    export NODE_ENV=production
    export API_KEY="secret123"
    #>
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Expression
    )

    # Parse the expression to extract variable name and value
    if ($Expression -match '^([a-zA-Z_][a-zA-Z0-9_]*)=(.*)$') {
        $varName = $matches[1]
        $varValue = $matches[2]

        # Remove surrounding quotes if present
        if ($varValue -match '^[''"](.*)[''""]$') {
            $varValue = $matches[1]
        }

        # Set the environment variable
        [System.Environment]::SetEnvironmentVariable($varName, $varValue, [System.EnvironmentVariableTarget]::Process)

        # Also set it in the current session's env: drive for immediate access
        Set-Item -Path "env:$varName" -Value $varValue

        Write-Verbose "Set environment variable: $varName = $varValue"
    } else {
        Write-Error "Invalid export syntax. Use: export VAR=VALUE"
    }
}

function Update-NpmDependencies {
    param (
        [Parameter(Mandatory=$false)]
        [String]$PackageJsonPath = 'package.json',
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('npm', 'yarn', 'bun')]
        [String]$PackageManager = 'npm',
        
        [Parameter(Mandatory=$false)]
        [Switch]$SkipDevDependencies
    )

    if (-not (Test-Path -Path $PackageJsonPath)) {
        Write-Error "Package.json file not found at path: $PackageJsonPath"
        return
    }

    # Get dependencies from package.json
    $packageJson = Get-Content $PackageJsonPath | ConvertFrom-Json
    
    $hasDependencies = $packageJson.dependencies -and $packageJson.dependencies.PSObject.Properties.Name.Count -gt 0
    $hasDevDependencies = $packageJson.devDependencies -and $packageJson.devDependencies.PSObject.Properties.Name.Count -gt 0
    
    if (-not $hasDependencies -and (-not $hasDevDependencies -or $SkipDevDependencies)) {
        Write-Warning "No dependencies found in package.json"
        return
    }
    
    Write-Host "- Updating dependencies using $PackageManager..." -ForegroundColor Blue

    # Update regular dependencies
    if ($hasDependencies) {
        $dependencies = $packageJson.dependencies.PSObject.Properties.Name
        
        Write-Host "Updating regular dependencies..." -ForegroundColor Cyan
        foreach ($dep in $dependencies) {
            Write-Host "Updating $dep..." -ForegroundColor Yellow
            
            switch ($PackageManager) {
                'npm' { npm install "$dep@latest" }
                'yarn' { yarn add "$dep@latest" }
                'bun' { bun add "$dep@latest" }
            }
        }
    }
    
    # Update dev dependencies
    if ($hasDevDependencies -and -not $SkipDevDependencies) {
        $devDependencies = $packageJson.devDependencies.PSObject.Properties.Name
        
        Write-Host "Updating dev dependencies..." -ForegroundColor Cyan
        foreach ($dep in $devDependencies) {
            Write-Host "Updating $dep..." -ForegroundColor Yellow
            
            switch ($PackageManager) {
                'npm' { npm install "$dep@latest" --save-dev }
                'yarn' { yarn add "$dep@latest" --dev }
                'bun' { bun add "$dep@latest" --development }
            }
        }
    }

    Write-Host "- Dependencies updated successfully!" -ForegroundColor Green
    
    switch ($PackageManager) {
        'npm' { npm install }
        'yarn' { yarn install }
        'bun' { bun install }
    }
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
Export-ModuleMember -Function Get-VsCodeExtension
Export-ModuleMember -Function Get-RedirectedUrl
Export-ModuleMember -Function wget
Export-ModuleMember -Function Update-NpmDependencies
Export-ModuleMember -Function export