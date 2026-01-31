<#
.SYNOPSIS
    Removes a CIMRackRole from Netbox D module.

.DESCRIPTION
    Removes a CIMRackRole from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMRackRole

    Returns all CIMRackRole objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMRackRole {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Rack Role"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete rack role')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','rack-roles',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
