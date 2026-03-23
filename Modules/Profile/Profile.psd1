@{
    RootModule = 'Profile.psm1'
    ModuleVersion = '1.0.0'
    GUID = '3afd5057-c8d9-4487-a1b8-7520632f9f43'
    Author = 'mateus.junior <mateus@matj.dev>'
    CompanyName = 'Unknown'
    Copyright = '(c) matj.dev. All rights reserved.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Set-ParentLocation',
        'Initialize-ScriptPaths',
        'Initialize-PSDrives'
    )
    CmdletsToExport = @()
    VariablesToExport = @(
        'doc',
        'psdir',
        'tpath',
        'history'
    )
    AliasesToExport = '*'
}
