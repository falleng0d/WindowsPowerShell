function RemoveNodeModules {
    param(
        [switch]$Dry,
        [switch]$Lockfiles
    )

    $scriptPath = $PSScriptRoot
    if (-not $scriptPath) {
        $scriptPath = Get-Location
    }

    $lockfilePatterns = @("package-lock.json", "yarn.lock", "bun.lock", "bun.lockb", "pnpm-lock.yaml", "deno.lock")

    $allNodeModules = Get-ChildItem -Path $scriptPath -Directory -Recurse -Filter "node_modules" -ErrorAction SilentlyContinue
    $nodeModulesFolders = $allNodeModules | Where-Object {
        ($_.FullName -split [regex]::Escape([System.IO.Path]::DirectorySeparatorChar) | Where-Object { $_ -eq "node_modules" }).Count -eq 1
    }

    $lockfileList = @()
    if ($Lockfiles) {
        foreach ($pattern in $lockfilePatterns) {
            $foundFiles = Get-ChildItem -Path $scriptPath -File -Recurse -Filter $pattern -ErrorAction SilentlyContinue
            $filteredFiles = $foundFiles | Where-Object {
                $pathParts = $_.FullName -split [regex]::Escape([System.IO.Path]::DirectorySeparatorChar)
                $pathParts -notcontains "node_modules"
            }
            $lockfileList += $filteredFiles
        }
    }

    if ($nodeModulesFolders.Count -eq 0 -and (-not $Lockfiles -or $lockfileList.Count -eq 0)) {
        Write-Host "No node_modules folders found."
        if ($Lockfiles) {
            Write-Host "No lockfiles found."
        }
        exit 0
    }

    function Get-RelativePath {
        param($fullPath)
        return $fullPath.Replace($scriptPath, '.').TrimStart('.').TrimStart([System.IO.Path]::DirectorySeparatorChar)
    }

    if ($nodeModulesFolders.Count -gt 0) {
        Write-Host "Found $($nodeModulesFolders.Count) node_modules folder(s):"
        $nodeModulesFolders | ForEach-Object { Write-Host "  $(Get-RelativePath $_.FullName)" }
    }

    if ($Lockfiles -and $lockfileList.Count -gt 0) {
        Write-Host "`nFound $($lockfileList.Count) lockfile(s):"
        $lockfileList | ForEach-Object { Write-Host "  $(Get-RelativePath $_.FullName)" }
    }

    if ($Dry) {
        Write-Host "`nDry run complete. No files or folders were deleted."
        exit 0
    }

    $confirmation = Read-Host "`nDo you want to delete these? (Y/n)"
    if ($confirmation -eq 'n' -or $confirmation -eq 'N') {
        Write-Host "Operation cancelled."
        exit 0
    }

    foreach ($folder in $nodeModulesFolders) {
        $relativePath = Get-RelativePath $folder.FullName
        try {
            Remove-Item -Path $folder.FullName -Recurse -Force -ErrorAction Stop
            Write-Host "Deleted: $relativePath" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to delete: $relativePath" -ForegroundColor Red
            Write-Host "Error: $_" -ForegroundColor Red
        }
    }

    if ($Lockfiles) {
        foreach ($file in $lockfileList) {
            $relativePath = Get-RelativePath $file.FullName
            try {
                Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                Write-Host "Deleted: $relativePath" -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to delete: $relativePath" -ForegroundColor Red
                Write-Host "Error: $_" -ForegroundColor Red
            }
        }
    }

    Write-Host "`nDone."
}

Export-ModuleMember -Function RemoveNodeModules
