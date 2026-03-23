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
