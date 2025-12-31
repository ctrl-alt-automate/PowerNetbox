<#
.SYNOPSIS
    Creates a new virtualization cluster type in Netbox.

.DESCRIPTION
    Creates a new cluster type in the Netbox virtualization module.
    Cluster types define the virtualization technology (e.g., VMware vSphere, KVM, Hyper-V).

.PARAMETER Name
    The name of the cluster type.

.PARAMETER Slug
    URL-friendly unique identifier. If not provided, will be auto-generated from name.

.PARAMETER Description
    A description of the cluster type.

.PARAMETER Tags
    Array of tag IDs to assign to this cluster type.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVirtualizationClusterType -Name "VMware vSphere" -Slug "vmware-vsphere"

    Creates a new cluster type for VMware vSphere.

.EXAMPLE
    New-NBVirtualizationClusterType -Name "Proxmox VE" -Description "Open source virtualization platform"

    Creates a new cluster type with auto-generated slug.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/clustertype/
#>
function New-NBVirtualizationClusterType {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$Slug,

        [string]$Description,

        [uint64[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Virtualization Cluster Type"
        # Auto-generate slug from name if not provided
        if (-not $PSBoundParameters.ContainsKey('Slug')) {
            $PSBoundParameters['Slug'] = ($Name -replace '\s+', '-').ToLower()
        }

        $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'cluster-types'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create cluster type')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
