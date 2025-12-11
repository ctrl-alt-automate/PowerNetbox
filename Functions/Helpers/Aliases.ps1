# Backwards compatibility aliases for renamed functions
# These aliases maintain compatibility with scripts using the old Add-* naming convention

Set-Alias -Name Add-NBDCIMInterface -Value New-NBDCIMInterface
Set-Alias -Name Add-NBDCIMInterfaceConnection -Value New-NBDCIMInterfaceConnection
Set-Alias -Name Add-NBDCIMFrontPort -Value New-NBDCIMFrontPort
Set-Alias -Name Add-NBDCIMRearPort -Value New-NBDCIMRearPort
Set-Alias -Name Add-NBVirtualMachineInterface -Value New-NBVirtualMachineInterface

# Export aliases
Export-ModuleMember -Alias Add-NBDCIMInterface, Add-NBDCIMInterfaceConnection, Add-NBDCIMFrontPort, Add-NBDCIMRearPort, Add-NBVirtualMachineInterface
