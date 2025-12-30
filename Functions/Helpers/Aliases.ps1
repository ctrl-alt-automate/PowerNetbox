# Backwards compatibility aliases for renamed functions
# These aliases maintain compatibility with scripts using the old Add-* naming convention

Set-Alias -Name Add-NBDDCIM Interface -Value New-NBDDCIM Interface
Set-Alias -Name Add-NBDDCIM InterfaceConnection -Value New-NBDDCIM InterfaceConnection
Set-Alias -Name Add-NBDDCIM Front Port -Value New-NBDDCIM Front Port
Set-Alias -Name Add-NBDDCIM Rear Port -Value New-NBDDCIM Rear Port
Set-Alias -Name Add-NBVVirtual MachineInterface -Value New-NBVVirtual MachineInterface

# Export aliases
Export-ModuleMember -Alias Add-NBDDCIM Interface, Add-NBDDCIM InterfaceConnection, Add-NBDDCIM Front Port, Add-NBDDCIM Rear Port, Add-NBVVirtual MachineInterface
