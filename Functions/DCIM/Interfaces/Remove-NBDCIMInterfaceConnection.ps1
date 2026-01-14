<#
.SYNOPSIS
    Removes a CIMInterfaceConnection from Netbox D module.

.DESCRIPTION
    Removes a CIMInterfaceConnection from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMInterfaceConnection

    Returns all CIMInterfaceConnection objects.

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

        [switch]$Force
    )

    begin {

    }

    process {
        Write-Verbose "Removing D CI MI nt er fa ce Co nn ec ti on"
        foreach ($ConnectionID in $Id) {
            $CurrentConnection = Get-NBDCIMInterfaceConnection -Id $ConnectionID -ErrorAction Stop

            if ($Force -or $pscmdlet.ShouldProcess("Connection ID $($ConnectionID.Id)", "REMOVE")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'interface-connections', $CurrentConnection.Id))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Method DELETE
            }
        }
    }

    end {

    }
}
