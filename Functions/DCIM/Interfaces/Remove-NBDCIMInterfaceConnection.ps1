<#
.SYNOPSIS
    Removes a DCIM InterfaceConnection from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM InterfaceConnection from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMInterfaceConnection

    Deletes a DCIM InterfaceConnection object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function Remove-NBDCIMInterfaceConnection {
    [CmdletBinding(ConfirmImpact = 'High',
                   SupportsShouldProcess = $true)]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing DCIM Interface Connection"
        foreach ($ConnectionID in $Id) {
            if ($Force -or $PSCmdlet.ShouldProcess("Interface Connection ID $ConnectionID", "REMOVE")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'interface-connections', $ConnectionID))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}
