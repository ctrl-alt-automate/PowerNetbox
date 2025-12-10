
function New-NetboxVirtualMachine {
    [CmdletBinding(ConfirmImpact = 'low',
        SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [uint64]$Site,

        [uint64]$Cluster,

        [uint64]$Tenant,

        [object]$Status = 'Active',

        [uint64]$Role,

        [uint64]$Platform,

        [uint16]$vCPUs,

        [uint64]$Memory,

        [uint64]$Disk,

        [uint64]$Primary_IP4,

        [uint64]$Primary_IP6,

        [hashtable]$Custom_Fields,

        [string]$Comments
    )

    #    $ModelDefinition = $script:NetboxConfig.APIDefinition.definitions.WritableVirtualMachineWithConfigContext

    #    # Validate the status against the APIDefinition
    #    if ($ModelDefinition.properties.status.enum -inotcontains $Status) {
    #        throw ("Invalid value [] for Status. Must be one of []" -f $Status, ($ModelDefinition.properties.status.enum -join ', '))
    #    }

    #$PSBoundParameters.Status = ValidateVirtualizationChoice -ProvidedValue $Status -VirtualMachineStatus

    # Note: In Netbox 4.x, Site is optional. A VM requires either a Cluster or can be standalone.
    $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'virtual-machines'))

    $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

    $URI = BuildNewURI -Segments $URIComponents.Segments

    if ($PSCmdlet.ShouldProcess($name, 'Create new Virtual Machine')) {
        InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters
    }
}




