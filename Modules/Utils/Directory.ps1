function Get-DirNumbered {
    [Diagnostics.CodeAnalysis.SupressMessageAttribute('PSUseApprovedVerb', '')]
    $a = @(Get-ChildItem)
    for ($i = 0; $i -le ($a.length - 1); $i += 1) {
        "$($i): $($a[$i].Name)"
    }
}

function Get-Tree($Path = '.', $Include = '*') {
    @(Get-Item $Path -Include $Include -Force) +
        (Get-ChildItem $Path -Recurse -Include $Include -Force) |
    Sort-Object pspath -Descending -Unique
}

# function Remove-Tree($Path, $Include = '*') {
#     Get-Tree $Path $Include | Remove-Item -Force -Recurse
# }
