<#
.SYNOPSIS
    Creates one or more prefixes in Netbox IPAM module.

.DESCRIPTION
    Creates new IP prefixes in Netbox IPAM module. Supports both single prefix
    creation with individual parameters and bulk creation via pipeline input.

    For bulk operations, use the -BatchSize parameter to control how many
    prefixes are sent per API request. This significantly improves performance
    when creating many prefixes.

.PARAMETER Prefix
    The IP prefix in CIDR notation (e.g., '10.0.0.0/24').

.PARAMETER Status
    Status of the prefix. Defaults to 'Active'.

.PARAMETER Tenant
    The tenant ID for the prefix.

.PARAMETER Role
    The role ID for the prefix.

.PARAMETER IsPool
    Whether this prefix is a pool from which child prefixes can be allocated.

.PARAMETER Description
    A description of the prefix.

.PARAMETER Site
    The site ID where this prefix is used.

.PARAMETER VRF
    The VRF ID for this prefix.

.PARAMETER VLAN
    The VLAN ID associated with this prefix.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER InputObject
    Pipeline input for bulk operations. Each object should contain
    the required property: Prefix.

.PARAMETER BatchSize
    Number of prefixes to create per API request in bulk mode.
    Default: 50, Range: 1-1000

.PARAMETER Force
    Skip confirmation prompts for bulk operations.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBIIPAM Prefix -Prefix "10.0.0.0/24" -Status "active" -Site 1

    Creates a single prefix.

.EXAMPLE
    $prefixes = 1..50 | ForEach-Object {
        [PSCustomObject]@{Prefix="10.$_.0.0/24"; Status="active"; Site=1}
    }
    $prefixes | New-NBIIPAM Prefix -BatchSize 50 -Force

    Creates 50 prefixes in bulk using a single API call.

.EXAMPLE
    Import-Csv subnets.csv | New-NBIIPAM Prefix -BatchSize 100 -Force

    Bulk import prefixes from a CSV file.

.LINK
    https://netbox.readthedocs.io/en/stable/models/ipam/prefix/
#>

function New-NBIPAMPrefix {
    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'Low',
        DefaultParameterSetName = 'Single')]
    [OutputType([PSCustomObject])]
    param(
        # Single mode parameters
        [Parameter(ParameterSetName = 'Single', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Prefix,

        [Parameter(ParameterSetName = 'Single')]
        [object]$Status = 'Active',

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Tenant,

        [Parameter(ParameterSetName = 'Single')]
        [object]$Role,

        [Parameter(ParameterSetName = 'Single')]
        [bool]$IsPool,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Description,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Site,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$VRF,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$VLAN,

        [Parameter(ParameterSetName = 'Single')]
        [hashtable]$Custom_Fields,

        # Bulk mode parameters
        [Parameter(ParameterSetName = 'Bulk', Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$InputObject,

        [Parameter(ParameterSetName = 'Bulk')]
        [ValidateRange(1, 1000)]
        [int]$BatchSize = 100,

        [Parameter(ParameterSetName = 'Bulk')]
        [switch]$Force,

        # Common parameters
        [Parameter()]
        [switch]$Raw
    )

    begin {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'prefixes'))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ParameterSetName -eq 'Bulk') {
            $bulkItems = [System.Collections.ArrayList]::new()
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Single') {
            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

            if ($PSCmdlet.ShouldProcess($Prefix, 'Create new Prefix')) {
                InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
            }
        }
        else {
            # Bulk mode - collect items
            if ($InputObject) {
                $item = @{}
                foreach ($prop in $InputObject.PSObject.Properties) {
                    $key = $prop.Name.ToLower()
                    $value = $prop.Value

                    # Handle property name mappings
                    switch ($key) {
                        'ispool' { $key = 'is_pool' }
                        'custom_fields' { $key = 'custom_fields' }
                    }

                    $item[$key] = $value
                }
                [void]$bulkItems.Add([PSCustomObject]$item)
            }
        }
    }

    end {
        if ($PSCmdlet.ParameterSetName -eq 'Bulk' -and $bulkItems.Count -gt 0) {
            $target = "$($bulkItems.Count) prefix(es)"

            if ($Force -or $PSCmdlet.ShouldProcess($target, 'Create prefixes (bulk)')) {
                Write-Verbose "Processing $($bulkItems.Count) prefixes in bulk mode with batch size $BatchSize"

                $result = Send-NBBulkRequest -URI $URI -Items $bulkItems.ToArray() -Method POST `
                    -BatchSize $BatchSize -ShowProgress -ActivityName 'Creating prefixes'

                # Output succeeded items to pipeline
                foreach ($item in $result.Succeeded) {
                    Write-Output $item
                }

                # Write errors for failed items
                foreach ($failure in $result.Failed) {
                    Write-Error "Failed to create prefix: $($failure.Error)" -TargetObject $failure.Item
                }

                # Write summary
                if ($result.HasErrors) {
                    Write-Warning $result.GetSummary()
                }
                else {
                    Write-Verbose $result.GetSummary()
                }
            }
        }
    }
}
