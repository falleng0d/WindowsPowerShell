function New-SymbolicLink($target, $link) {
    New-Item -Path $link -ItemType SymbolicLink -Value $target
}

function New-HardLink($target, $link) {
    New-Item -Path $link -ItemType HardLink -Value $target
}
