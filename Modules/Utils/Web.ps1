function Invoke-Script-Uri {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptUri
    )
    $script = (New-Object System.Net.WebClient).DownloadString($ScriptUri)
    Invoke-Expression $script
}

function Get-VsCodeExtension {
    param (
        [Parameter(Mandatory = $true)]
        [String]$extensionName
    )

    begin {
        $body = @{
            filters = ,@{
                criteria = ,@{
                    filterType = 7
                    value = $null
                }
            }
            flags = 1712
        }
    }
    process {
        write-verbose "getting $($extensionName)"
        $response = try {
            $body.filters[0].criteria[0].value = $extensionName
            $Query = $body | ConvertTo-JSON -Depth 4
            (Invoke-WebRequest -Uri "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery?api-version=6.0-preview" -ErrorAction Stop -Body $Query -Method Post -ContentType "application/json")
        }
        catch [System.Net.WebException] {
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
        [Parameter(Mandatory = $true)]
        [String]$URL
    )

    $request = [System.Net.WebRequest]::Create($url)
    $request.AllowAutoRedirect = $false
    $response = $request.GetResponse()

    If ($response.StatusCode -eq "Found") {
        $response.GetResponseHeader("Location")
    }
}

function wget {
    param (
        [Parameter(Mandatory = $true)]
        [String]$URL
    )

    $FileName = [System.IO.Path]::GetFileName((Get-RedirectedUrl $URL))

    Write-Host Downloading $FileName from $URL

    Invoke-WebRequest -Uri $URL -OutFile $FileName
}
