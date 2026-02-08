<#
.SYNOPSIS
    Removes a IPAM Prefix from Netbox IPAM module.

.DESCRIPTION
    Removes a IPAM Prefix from Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBIPAMPrefix

    Deletes an IPAM Prefix object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBIPAMPrefix {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing IPAM Prefix"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete prefix')) {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'prefixes', $Id))
            $URI = BuildNewURI -Segments $Segments
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
