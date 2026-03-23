function Edit-Profile {
    code ($PROFILE.CurrentUserAllHosts -replace "[^\\]*.ps1$","")
}

function Import-Profile {
    . $profile
}

# Creates a new scratch file on the scratch directory and opens it in
# idea editor. Accepts a file extension as a parameter. Names it "scratch-0000.ext"
# where 0000 is the next available number.
$scratchDirectory = "C:\Projects\scratch"
function New-Scratch {
    param(
        [Parameter()]
        [string]$Extension = "md"
    )

    if (-not (Test-Path -Path $scratchDirectory)) {
        New-Item -ItemType Directory -Path $scratchDirectory
    }

    $Extension = "." + $Extension.TrimStart(".")
    $counter = 0
    do {
        $fileName = "scratch-{0:D4}{1}" -f $counter, $Extension
        $filePath = Join-Path -Path $scratchDirectory -ChildPath $fileName
        $counter++
    } while (Test-Path -Path $filePath)

    New-Item -ItemType File -Path $filePath
    idea $filePath
}
