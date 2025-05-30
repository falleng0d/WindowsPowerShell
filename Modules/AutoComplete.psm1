$Modules = $PROFILE.CurrentUserAllHosts -replace "[^\\]*.ps1$","Modules"

Function Test-CommandExists {
    Param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "stop"

    try {
        if(Get-Command $command) {
            return $true
        }
    }
    Catch {
        return $false
    }
    Finally {
        $ErrorActionPreference=$oldPreference
    }
}

try {
    Set-PSReadLineOption -PredictionSource History
} catch {
    return
}

Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

try {
    Set-PsFzfOption -TabExpansion
    # replace 'Ctrl+t' and 'Ctrl+r' with your preferred bindings:
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
} catch {
    Write-Output "PsFzf not installed"
}

#Set-PSReadLineKeyHandler -Key Alt+d -Function ShellKillWord
# Set-PSReadLineKeyHandler -Key Alt+Backspace -Function ShellBackwardKillWord
# Set-PSReadLineKeyHandler -Key Ctrl+Backspace -Function ShellBackwardKillWord
Set-PSReadLineKeyHandler -Key Ctrl+h -Function ShellBackwardKillWord
Set-PSReadLineKeyHandler -Key Alt+Backspace -Function BackwardKillWord
Set-PSReadLineKeyHandler -key Enter -Function ValidateAndAcceptLine
#Set-PSReadLineKeyHandler -Key Alt+b -Function ShellBackwardWord
#Set-PSReadLineKeyHandler -Key Alt+f -Function ShellForwardWord
#Set-PSReadLineKeyHandler -Key Alt+B -Function SelectShellBackwardWord
#Set-PSReadLineKeyHandler -Key Alt+F -Function SelectShellForwardWord


# This key handler shows the entire or filtered history using Out-GridView. The
# typed text is used as the substring pattern for filtering. A selected command
# is inserted to the command line without invoking. Multiple command selection
# is supported, e.g. selected by Ctrl + Click.
Set-PSReadLineKeyHandler -Key F7 `
                         -BriefDescription History `
                         -LongDescription 'Show command history' `
                         -ScriptBlock {
    $pattern = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$pattern, [ref]$null)
    if ($pattern)
    {
        $pattern = [regex]::Escape($pattern)
    }

    $history = [System.Collections.ArrayList]@(
        $last = ''
        $lines = ''
        foreach ($line in [System.IO.File]::ReadLines((Get-PSReadLineOption).HistorySavePath))
        {
            if ($line.EndsWith('`'))
            {
                $line = $line.Substring(0, $line.Length - 1)
                $lines = if ($lines)
                {
                    "$lines`n$line"
                }
                else
                {
                    $line
                }
                continue
            }

            if ($lines)
            {
                $line = "$lines`n$line"
                $lines = ''
            }

            if (($line -cne $last) -and (!$pattern -or ($line -match $pattern)))
            {
                $last = $line
                $line
            }
        }
    )
    $history.Reverse()

    $command = $history | Out-GridView -Title History -PassThru
    if ($command)
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert(($command -join "`n"))
    }
}

# F2 for help on the command line - naturally
Set-PSReadLineKeyHandler -Key F2 `
                         -BriefDescription CommandHelp `
                         -LongDescription "Open the help window for the current command" `
                         -ScriptBlock {
    param($key, $arg)

    $ast = $null
    $tokens = $null
    $errors = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

    $commandAst = $ast.FindAll( {
        $node = $args[0]
        $node -is [CommandAst] -and
            $node.Extent.StartOffset -le $cursor -and
            $node.Extent.EndOffset -ge $cursor
        }, $true) | Select-Object -Last 1

    if ($commandAst -ne $null)
    {
        $commandName = $commandAst.GetCommandName()
        if ($commandName -ne $null)
        {
            $command = $ExecutionContext.InvokeCommand.GetCommand($commandName, 'All')
            if ($command -is [AliasInfo])
            {
                $commandName = $command.ResolvedCommandName
            }

            if ($commandName -ne $null)
            {
                Get-Help $commandName -ShowWindow
            }
        }
    }
}

# `ForwardChar` accepts the entire suggestion text when the cursor is at the end of the line.
# This custom binding makes `RightArrow` behave similarly - accepting the next word instead of the entire suggestion text.
Set-PSReadLineKeyHandler -Key RightArrow `
                         -BriefDescription ForwardCharAndAcceptNextSuggestionWord `
                         -LongDescription "Move cursor one character to the right in the current editing line and accept the next word in suggestion when it's at the end of current editing line" `
                         -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($cursor -lt $line.Length) {
        [Microsoft.PowerShell.PSConsoleReadLine]::ForwardChar($key, $arg)
    } else {
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptNextSuggestionWord($key, $arg)
    }
}

Set-PSReadLineKeyHandler -Key End `
                         -BriefDescription EndOfLineAndAcceptSuggestion `
						 -LongDescription "Move cursor to the end of the current editing line and accept the suggestion full when it's at the end of current editing line" `
                         -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($cursor -lt $line.Length) {
        [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine($key, $arg)
    } else {
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptSuggestion($key, $arg)
    }
}

# If kubectl is available, enable kubectl completion
if (Test-CommandExists kubectl) {
    Import-Module -Name $Modules\KubeCompletion.psm1 -DisableNameChecking
}

# if aws-cli is available, enable aws-cli completion
if (Test-CommandExists aws) {
    Register-ArgumentCompleter -Native -CommandName aws -ScriptBlock {
        param($commandName, $wordToComplete, $cursorPosition)
            $env:COMP_LINE=$wordToComplete
            if ($env:COMP_LINE.Length -lt $cursorPosition){
                $env:COMP_LINE=$env:COMP_LINE + " "
            }
            $env:COMP_POINT=$cursorPosition
            aws_completer.exe | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            }
            Remove-Item Env:\COMP_LINE
            Remove-Item Env:\COMP_POINT
    }
}

if (Test-CommandExists gh) {
    Invoke-Expression -Command $(gh completion -s powershell | Out-String)
}
