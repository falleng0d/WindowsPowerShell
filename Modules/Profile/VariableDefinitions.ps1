#Variables
New-Variable -Name doc -Value "$home\Documents" `
    -Description "My documents library. Profile created" `
    -Option ReadOnly -Scope "Global" -ErrorAction 'Ignore'
New-Variable -Name psdir -Value "$profileFolder" `
    -Description "Power shell directory" `
    -Option ReadOnly -Scope "Global" -ErrorAction 'Ignore'
New-Variable -Name tpath -Value "$profileFolder\Transcripts" `
    -Option ReadOnly -ErrorAction 'Ignore'
New-Variable -Name history -Value ((Get-PSReadlineOption).HistorySavePath) `
    -Option ReadOnly -ErrorAction 'Ignore'
# ... (other variables would be defined here)

Export-ModuleMember -Variable *
