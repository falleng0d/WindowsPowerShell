Get-ChildItem -Path C:\XboxGames -Recurse -Force | ForEach-Object -Process {
    $ACL = Get-Acl -Path $PSItem.FullName;
    Set-Acl -Path $PSItem.FullName -AclObject $ACL;
}

$path = "C:\XboxGames\Aliens- Fireteam Elite\Content\Endeavor\Binaries\WinGDK\Endeavor-WinGDK-Shipping.exe"
$acl = Get-Acl C:\usr
Set-Acl $path $acl