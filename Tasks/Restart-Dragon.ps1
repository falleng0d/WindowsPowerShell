$processNames = @(
    "natspeak",
    "loggerservice",
    "dragonbar",
    "dgnuiasvr_x64",
    "dgnuiasvr",
    "dgnsvc",
    "dgnria_nmhost"
)

# stops all processes
$processNames | ForEach-Object {
    Stop-Process-Gracefully -ProcessName $_
}



