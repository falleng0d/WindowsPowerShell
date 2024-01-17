function Get-GitHubSubFolderOrFile {
    param (
        [string]$gitUrl,
        [string]$repoPathToExtract,
        [string]$destPath
    )

    # Extract user and repo from the provided GitHub URL
    $userRepoRegex = 'https://github.com/(?<user>[^/]+)/(?<repo>[^/]+)'
    if ($gitUrl -match $userRepoRegex) {
        $user = $matches['user']
        $repo = $matches['repo']
        Write-Output "Extracted user: $user and repo: $repo"
    } else {
        Write-Error "Invalid GitHub URL"
        return
    }

    # Ensure the destination directory exists
    if (-not (Test-Path $destPath)) {
        New-Item -ItemType Directory -Force -Path $destPath | Out-Null
        Write-Output "Created destination directory: $destPath"
    } else {
        Write-Output "Destination directory already exists: $destPath"
    }

    # Construct the API URL for the content
    $apiContentUrl = "https://api.github.com/repos/$user/$repo/contents/$repoPathToExtract"
    Write-Output "API URL for content constructed: $apiContentUrl"

    try {
        # Get the content from the GitHub API
        $headers = @{
            Accept = 'application/vnd.github.v3+json'
        }
        $content = Invoke-RestMethod -Uri $apiContentUrl -Headers $headers -ErrorAction Stop
        Write-Output "Content retrieved from GitHub API."

        # Check if it's a file or a directory
        foreach ($item in $content) {
            $itemPath = Join-Path $destPath $item.name
            if ($item.type -eq 'dir') {
                # Recursively call the function for directories
                Get-GitHubSubFolderOrFile -gitUrl $gitUrl -repoPathToExtract $item.path -destPath $itemPath
            } elseif ($item.type -eq 'file') {
                # Download the file content
                $fileContent = Invoke-RestMethod -Uri $item.download_url -Headers $headers -ErrorAction Stop
                [System.IO.File]::WriteAllText($itemPath, $fileContent)
                Write-Output "File saved to: $itemPath"
            }
        }
    } catch {
        Write-Error "Failed to retrieve content from GitHub API: $_"
        return
    }
}
