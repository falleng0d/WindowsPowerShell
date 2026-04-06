function Test-ConsoleHost {
    if (($host.Name -match 'consolehost')) { $true }
    Else { $false }
}

function Enter-Admin {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerb', '')]
    param()

    Start-Process -Verb RunAs (Get-Process -Id $PID).Path
}

function Is-InteractiveAndVisible {
    # language=cs
    Add-Type @'
using System;
using System.Runtime.InteropServices;

public class Utils
{
    [DllImport("kernel32.dll")]
    private static extern uint GetFileType(IntPtr hFile);

    [DllImport("kernel32.dll")]
    private static extern IntPtr GetStdHandle(int nStdHandle);

    public static bool IsInteractiveAndVisible
    {
        get
        {
            return Environment.UserInteractive &&
                GetFileType(GetStdHandle(-10)) == 2 &&   // STD_INPUT_HANDLE is FILE_TYPE_CHAR
                GetFileType(GetStdHandle(-11)) == 2 &&   // STD_OUTPUT_HANDLE
                GetFileType(GetStdHandle(-12)) == 2;     // STD_ERROR_HANDLE
        }
    }
}
'@

    return [Utils]::IsInteractiveAndVisible
}
