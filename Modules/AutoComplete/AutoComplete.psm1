param()

. $PSScriptRoot\Show-HistoryKeyHandler.ps1
. $PSScriptRoot\Show-CommandHelpKeyHandler.ps1
. $PSScriptRoot\Forward-CharAndAcceptNextSuggestionWord.ps1
. $PSScriptRoot\End-OfLineAndAcceptSuggestion.ps1

Function Test-CommandExists {
    Param ($command)

    if(Get-Command -ErrorAction Stop $command) {
        return $true
    }
}

# Works only if the console output supports virtual terminal processing and is not redirected
try {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
} catch {
    return
}

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
Set-PSReadLineKeyHandler -key Enter -Function AcceptLine
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
                         -ScriptBlock { Show-HistoryKeyHandler }

# F2 for help on the command line - naturally
Set-PSReadLineKeyHandler -Key F2 `
                         -BriefDescription CommandHelp `
                         -LongDescription "Open the help window for the current command" `
                         -ScriptBlock {
    param($key, $arg)
    Show-CommandHelpKeyHandler -key $key -arg $arg
}

# `ForwardChar` accepts the entire suggestion text when the cursor is at the end of the line.
# This custom binding makes `RightArrow` behave similarly - accepting the next word instead of the entire suggestion text.
Set-PSReadLineKeyHandler -Key RightArrow `
                         -BriefDescription ForwardCharAndAcceptNextSuggestionWord `
                         -LongDescription "Move cursor one character to the right in the current editing line and accept the next word in suggestion when it's at the end of current editing line" `
                         -ScriptBlock {
    param($key, $arg)
    Invoke-ForwardCharAndAcceptNextSuggestionWordKeyHandler -key $key -arg $arg
}

Set-PSReadLineKeyHandler -Key End `
                         -BriefDescription EndOfLineAndAcceptSuggestion `
						 -LongDescription "Move cursor to the end of the current editing line and accept the suggestion full when it's at the end of current editing line" `
                         -ScriptBlock {
    param($key, $arg)
    Invoke-EndOfLineAndAcceptSuggestionKeyHandler -key $key -arg $arg
}

# If kubectl is available, enable kubectl completion
if (Test-CommandExists kubectl) {
    . $PSScriptRoot\KubeCompletion.ps1
}

# if aws-cli is available, enable aws-cli completion
if (Test-CommandExists aws) {
    . $PSScriptRoot\AwsCompletion.ps1
}

if (Test-CommandExists gh) {
    Invoke-Expression -Command $(gh completion -s powershell | Out-String)
}
