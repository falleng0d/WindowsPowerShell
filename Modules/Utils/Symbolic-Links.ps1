function New-Symbolic-Link($target, $link) {
    New-Item -Path $link -ItemType SymbolicLink -Value $target
}

function New-Hard-Link($target, $link) {
    New-Item -Path $link -ItemType HardLink -Value $target
}
