<#
.SYNOPSIS
    Updates an existing irtualMachineInterface in Netbox V module.

.DESCRIPTION
    Updates an existing irtualMachineInterface in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVirtualMachineInterface

    Updates an existing Virtual Machine Interface object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function Set-NBVirtualMachineInterface {
    [CmdletBinding(ConfirmImpact = 'Medium',
                   SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$MAC_Address,

        [uint16]$MTU,

        [string]$Description,

        [boolean]$Enabled,

        [uint64]$Virtual_Machine,

        [switch]$Force,

        [switch]$Raw
    )

    begin {

    }

    process {
        foreach ($VMI_ID in $Id) {
            Write-Verbose "Updating VM Interface ID $VMI_ID"

            $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'interfaces', $VMI_ID))

            if ($Force -or $pscmdlet.ShouldProcess("VM Interface ID $VMI_ID", "Set")) {
                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH -Raw:$Raw
            }
        }
    }

    end {

    }
}