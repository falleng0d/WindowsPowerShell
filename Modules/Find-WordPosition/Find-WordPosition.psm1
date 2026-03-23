function Find-WordPosition {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$SearchTerm,
        
        [Parameter(Mandatory=$true, Position=1)]
        [string]$FilePath,
        
        [Parameter(Mandatory=$false)]
        [switch]$CaseInsensitive = $false
    )

    # Validate that the file exists
    if (-not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        exit 1
    }

    # Escape special characters in the search term for regex
    $EscapedSearchTerm = [regex]::Escape($SearchTerm)

    # Build the awk command with optional case insensitive flag
    $AwkCommand = if (!$CaseInsensitive) {
        @'
/\<{0}\>/ {{
    match($0, /\<{0}\>/)
    if(RSTART > 0) {{
        print ":"NR":"RSTART":"$0
    }}
}}
'@ -f $EscapedSearchTerm
    } else {
        @'
BEGIN{{IGNORECASE=1}}
/\<{0}\>/ {{
    match($0, /\<{0}\>/)
    if(RSTART > 0) {{
        print ":"NR":"RSTART":"$0
    }}
}}
'@ -f $EscapedSearchTerm
    }

    # Execute the awk command
    try {
        awk $AwkCommand $FilePath
    } catch {
        Write-Error "Error executing awk command: $_"
        exit 1
    }
}

Export-ModuleMember -Function Find-WordPosition