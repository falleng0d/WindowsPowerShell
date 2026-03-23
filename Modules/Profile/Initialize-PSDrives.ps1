function Initialize-PSDrives {
    if (-not (Get-PSDrive -Name Mod -ErrorAction SilentlyContinue)) {
        New-PSDrive -Name Mod -Root ($env:PSModulePath -split ';')[0] `
            -PSProvider FileSystem -ErrorAction SilentlyContinue | Out-Null
    }
}
