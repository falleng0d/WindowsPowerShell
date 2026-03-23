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
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Expression
    )

    if ($Expression -match '^([a-zA-Z_][a-zA-Z0-9_]*)=(.*)$') {
        $varName = $matches[1]
        $varValue = $matches[2]

        if ($varValue -match '^[''\"](.*)[''\"]$') {
            $varValue = $matches[1]
        }

        [System.Environment]::SetEnvironmentVariable($varName, $varValue, [System.EnvironmentVariableTarget]::Process)
        Set-Item -Path "env:$varName" -Value $varValue

        Write-Verbose "Set environment variable: $varName = $varValue"
    }
    else {
        Write-Error "Invalid export syntax. Use: export VAR=VALUE"
    }
}
