[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    
    [Parameter(Mandatory = $false)]
    [switch]$Dry
)

function Get-NodeModulesPaths {
    param (
        [string]$StartPath
    )
    
    # Get all node_modules folders
    $nodeModulesFolders = Get-ChildItem -Path $StartPath -Filter "node_modules" -Directory -Recurse
    
    # Filter out nested node_modules
    $rootNodeModules = $nodeModulesFolders | Where-Object {
        $parent = $_.FullName
        while ($parent = Split-Path $parent) {
            if ((Split-Path $parent -Leaf) -eq "node_modules") {
                return $false
            }
        }
        return $true
    }
    
    return $rootNodeModules
}

# Resolve the full path
$FullPath = Resolve-Path $Path

# Get root node_modules folders
$foldersToDelete = Get-NodeModulesPaths -StartPath $FullPath

# Display what will be deleted
Write-Host "Found $($foldersToDelete.Count) root node_modules folders:"
$foldersToDelete | ForEach-Object {
    Write-Host "- $($_.FullName)"
}

if ($Dry) {
    Write-Host "`nDry run complete. No folders were deleted."
    exit
}

# Confirm before deletion
$confirmation = Read-Host "`nDo you want to proceed with deletion? (y/N)"
if ($confirmation -ne "y") {
    Write-Host "Operation cancelled."
    exit
}

# Delete the folders
$foldersToDelete | ForEach-Object {
    $folderPath = $_.FullName
    try {
        Remove-Item -Path $folderPath -Recurse -Force
        Write-Host "Deleted: $folderPath"
    }
    catch {
        Write-Error "Failed to delete: $folderPath"
        Write-Error $_.Exception.Message
    }
}

Write-Host "`nCleanup completed!"