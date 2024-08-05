Imports System.Management

Sub Main()
    Dim searcher As New ManagementObjectSearcher("root\CIMV2", "SELECT * FROM Win32_Process WHERE Name = 'AutoHotkey.exe' AND CommandLine LIKE '%virtual-desktop-enhancer%'")

    For Each queryObj As ManagementObject In searcher.Get()
        Console.WriteLine("-----------------------------------")
        Console.WriteLine("Win32_Process instance")
        Console.WriteLine("-----------------------------------")
        Console.WriteLine("CommandLine: {0}", queryObj("CommandLine"))
    Next
End Sub