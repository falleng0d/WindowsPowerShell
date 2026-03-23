function Edit-Profile {
    code ($PROFILE.CurrentUserAllHosts -replace "[^\\]*.ps1$","")
}

function Import-Profile {
    . $profile
}
