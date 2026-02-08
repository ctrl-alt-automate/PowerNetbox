<#
.SYNOPSIS
    Removes a DCIM ModuleBayTemplate from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM ModuleBayTemplate from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMModuleBayTemplate

    Deletes a DCIM ModuleBayTemplate object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMModuleBayTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
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
