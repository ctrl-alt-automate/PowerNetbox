<#
.SYNOPSIS
    Creates a new Circuit in Netbox C module.

.DESCRIPTION
    Creates a new Circuit in Netbox C module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBCircuit

    Creates a new Circuit object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function New-NBCircuit {
    [CmdletBinding(ConfirmImpact = 'Low',
        SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CID,

        [Parameter(Mandatory = $true)]
        [uint64]$Provider,

        [Parameter(Mandatory = $true)]
        [uint64]$Type,

        [ValidateSet('active', 'planned', 'provisioning', 'offline', 'deprovisioning', 'decommissioned')]
        [string]$Status = 'active',

        [string]$Description,

        [uint64]$Tenant,

        [string]$Termination_A,

        [datetime]$Install_Date,

        [string]$Termination_Z,

        [ValidateRange(0, 2147483647)]
        [uint64]$Commit_Rate,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Circuit"
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuits'))
        $Method = 'POST'

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($Force -or $PSCmdlet.ShouldProcess($CID, 'Create new circuit')) {
            InvokeNetboxRequest -URI $URI -Method $Method -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
