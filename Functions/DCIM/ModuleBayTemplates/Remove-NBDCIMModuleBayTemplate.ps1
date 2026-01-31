<#
.SYNOPSIS
    Removes a CIMModuleBayTemplate from Netbox D module.

.DESCRIPTION
    Removes a CIMModuleBayTemplate from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMModuleBayTemplate

    Returns all CIMModuleBayTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMModuleBayTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Module Bay Template"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete module bay template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','module-bay-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
