
#Module Browser Begin
#Version: 1.0.0
Add-Type -Path 'C:\Program Files (x86)\Microsoft Module Browser\ModuleBrowser.dll'
$moduleBrowser = $psISE.CurrentPowerShellTab.VerticalAddOnTools.Add('Module Browser', [ModuleBrowser.Views.MainView], $true)
$psISE.CurrentPowerShellTab.VisibleVerticalAddOnTools.SelectedAddOnTool = $moduleBrowser
#Module Browser End

&"$home\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"

# function prompt {
#     $(if (Test-Path variable:/PSDebugContext) { '[DBG]: ' }
#       else { '' }) + $(Get-Location) +
#         $(if ($NestedPromptLevel -ge 1) { '>>' }) + '> '
# }