<#
.SYNOPSIS
    Removes a DCIM Module BayTemplate from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM Module BayTemplate from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDDCIM Module BayTemplate

    Returns all DCIM Module BayTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDDCIM Module BayTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM ModuleB ay Te mp la te"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete module bay template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','module-bay-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
