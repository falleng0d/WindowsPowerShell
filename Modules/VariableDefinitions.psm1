#Variables
New-Variable -Name doc -Value "$home\Documents" `
    -Description "My documents library. Profile created" `
    -Option ReadOnly -Scope "Global" -ErrorAction 'Ignore'
# ... (other variables would be defined here)

Export-ModuleMember -Variable *