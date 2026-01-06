#
# ScenarioTestHelper.psm1
#
# Shared utilities for PowerNetbox Scenario Tests.
# Manages test data import/cleanup using the TestData Python scripts.
#

# Module-scope variables
$script:TestDataPath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) ".." | Join-Path -ChildPath "TestData"

# Test environments loaded from environment variables for security
# Required env vars per environment:
#   NETBOX_449_HOST, NETBOX_449_TOKEN
#   NETBOX_449_ZWQG_HOST, NETBOX_449_ZWQG_TOKEN
#   NETBOX_437_HOST, NETBOX_437_TOKEN
#   NETBOX_450_HOST, NETBOX_450_TOKEN
$script:TestEnvironments = @{
    '4.4.9' = @{
        Hostname = $env:NETBOX_449_HOST
        Token    = $env:NETBOX_449_TOKEN
        Scheme   = 'https'
    }
    '4.4.9-zwqg' = @{
        Hostname = $env:NETBOX_449_ZWQG_HOST
        Token    = $env:NETBOX_449_ZWQG_TOKEN
        Scheme   = 'https'
    }
    '4.3.7' = @{
        Hostname = $env:NETBOX_437_HOST
        Token    = $env:NETBOX_437_TOKEN
        Scheme   = 'https'
    }
    '4.5.0' = @{
        Hostname = $env:NETBOX_450_HOST
        Token    = $env:NETBOX_450_TOKEN
        Scheme   = 'https'
    }
}

# Current test session state
$script:CurrentEnvironment = $null
$script:TestDataImported = $false

function Get-ScenarioTestDataPath {
    <#
    .SYNOPSIS
        Returns the path to the TestData directory.
    #>
    return $script:TestDataPath
}

function Get-ScenarioEnvironments {
    <#
    .SYNOPSIS
        Returns available test environments.
    #>
    return $script:TestEnvironments.Keys
}

function Connect-ScenarioTest {
    <#
    .SYNOPSIS
        Connects to a Netbox test environment for scenario testing.

    .PARAMETER Environment
        The Netbox version to connect to (4.3.7, 4.4.9, or 4.5.0).

    .EXAMPLE
        Connect-ScenarioTest -Environment '4.4.9'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('4.3.7', '4.4.9', '4.4.9-zwqg', '4.5.0')]
        [string]$Environment
    )

    $config = $script:TestEnvironments[$Environment]
    if (-not $config) {
        throw "Environment '$Environment' not found"
    }

    # Validate environment variables are set
    if (-not $config.Hostname -or -not $config.Token) {
        $envPrefix = switch ($Environment) {
            '4.4.9'      { 'NETBOX_449' }
            '4.4.9-zwqg' { 'NETBOX_449_ZWQG' }
            '4.3.7'      { 'NETBOX_437' }
            '4.5.0'      { 'NETBOX_450' }
        }
        throw "Environment variables not set for '$Environment'. Required: ${envPrefix}_HOST and ${envPrefix}_TOKEN"
    }

    $secureToken = ConvertTo-SecureString -String $config.Token -AsPlainText -Force
    $credential = [PSCredential]::new('api', $secureToken)

    $connectParams = @{
        Hostname             = $config.Hostname
        Credential           = $credential
        Scheme               = $config.Scheme
        SkipCertificateCheck = $true
    }

    Connect-NBAPI @connectParams

    # Verify connection
    $version = Get-NBVersion
    if (-not $version) {
        throw "Failed to connect to Netbox $Environment"
    }

    $script:CurrentEnvironment = $Environment
    Write-Verbose "Connected to Netbox $($version.'netbox-version') ($Environment)"

    return $version
}

function Import-ScenarioTestData {
    <#
    .SYNOPSIS
        Imports test data to the current Netbox environment using the Python import script.

    .PARAMETER Environment
        The Netbox version to import data to. Defaults to current environment.

    .PARAMETER Force
        Skip confirmation and cleanup before import.

    .EXAMPLE
        Import-ScenarioTestData -Environment '4.4.9'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateSet('4.3.7', '4.4.9', '4.4.9-zwqg', '4.5.0')]
        [string]$Environment = $script:CurrentEnvironment,

        [switch]$Force
    )

    if (-not $Environment) {
        throw "No environment specified. Use Connect-ScenarioTest first or provide -Environment"
    }

    $importScript = Join-Path $script:TestDataPath "import_testdata.py"
    if (-not (Test-Path $importScript)) {
        throw "Import script not found: $importScript"
    }

    # Clean up first if Force is specified
    if ($Force) {
        Remove-ScenarioTestData -Environment $Environment -Confirm:$false
    }

    if ($PSCmdlet.ShouldProcess("Netbox $Environment", "Import test data")) {
        Push-Location $script:TestDataPath
        try {
            $result = python3 $importScript $Environment 2>&1
            $exitCode = $LASTEXITCODE

            if ($exitCode -ne 0) {
                Write-Warning "Import script returned exit code $exitCode"
                Write-Warning ($result -join "`n")
                return $false
            }

            Write-Verbose ($result -join "`n")
            $script:TestDataImported = $true
            return $true
        }
        finally {
            Pop-Location
        }
    }
}

function Remove-ScenarioTestData {
    <#
    .SYNOPSIS
        Removes all PNB-Test data from the current Netbox environment.

    .PARAMETER Environment
        The Netbox version to clean up. Defaults to current environment.

    .EXAMPLE
        Remove-ScenarioTestData -Environment '4.4.9'
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [ValidateSet('4.3.7', '4.4.9', '4.4.9-zwqg', '4.5.0')]
        [string]$Environment = $script:CurrentEnvironment
    )

    if (-not $Environment) {
        throw "No environment specified. Use Connect-ScenarioTest first or provide -Environment"
    }

    $cleanupScript = Join-Path $script:TestDataPath "cleanup_testdata.py"
    if (-not (Test-Path $cleanupScript)) {
        throw "Cleanup script not found: $cleanupScript"
    }

    if ($PSCmdlet.ShouldProcess("Netbox $Environment", "Remove all PNB-Test data")) {
        Push-Location $script:TestDataPath
        try {
            $result = python3 $cleanupScript $Environment 2>&1
            $exitCode = $LASTEXITCODE

            if ($exitCode -ne 0) {
                Write-Warning "Cleanup script returned exit code $exitCode"
                Write-Warning ($result -join "`n")
                return $false
            }

            Write-Verbose ($result -join "`n")
            $script:TestDataImported = $false
            return $true
        }
        finally {
            Pop-Location
        }
    }
}

function Test-ScenarioTestData {
    <#
    .SYNOPSIS
        Checks if test data is present in the current Netbox environment.

    .DESCRIPTION
        Looks for PNB-Test prefixed objects to verify test data exists.
        Uses Query parameter for partial matching (wildcards don't work with Name parameter).
    #>
    [CmdletBinding()]
    param()

    $prefix = Get-TestPrefix

    # Check for test sites using Query (supports partial matching)
    $sites = Get-NBDCIMSite -Query $prefix -Limit 1
    if ($sites) {
        return $true
    }

    # Check for test tenants using Query
    $tenants = Get-NBTenant -Query $prefix -Limit 1
    if ($tenants) {
        return $true
    }

    return $false
}

function Get-TestPrefix {
    <#
    .SYNOPSIS
        Returns the test object prefix used by scenario tests.
    #>
    return "PNB-Test"
}

function Assert-ScenarioTestDataExists {
    <#
    .SYNOPSIS
        Ensures test data exists, importing if necessary.

    .PARAMETER Environment
        The Netbox version to check/import.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('4.3.7', '4.4.9', '4.4.9-zwqg', '4.5.0')]
        [string]$Environment
    )

    # Connect if not already connected
    if ($script:CurrentEnvironment -ne $Environment) {
        Connect-ScenarioTest -Environment $Environment
    }

    # Check if data exists
    if (-not (Test-ScenarioTestData)) {
        Write-Verbose "Test data not found, importing..."
        Import-ScenarioTestData -Environment $Environment -Force
    }

    # Verify import succeeded
    if (-not (Test-ScenarioTestData)) {
        throw "Failed to verify test data exists after import"
    }

    return $true
}

# Helper function to get test objects by type
function Get-ScenarioTestObjects {
    <#
    .SYNOPSIS
        Gets test objects of a specific type.

    .PARAMETER ObjectType
        The type of objects to retrieve (e.g., 'Site', 'Device', 'Prefix').

    .DESCRIPTION
        Uses Query parameter for functions that support it (most do).
        Falls back to client-side filtering with Where-Object for functions
        that don't have Query or need more complex matching.

    .EXAMPLE
        Get-ScenarioTestObjects -ObjectType 'Device'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet(
            'Site', 'Device', 'DeviceType', 'DeviceRole', 'Manufacturer', 'Platform',
            'Rack', 'RackRole', 'RackType', 'Location', 'Region', 'SiteGroup',
            'Interface', 'Cable', 'FrontPort', 'RearPort',
            'Prefix', 'Address', 'VLAN', 'VLANGroup', 'VRF', 'Aggregate', 'RIR', 'Role',
            'Tenant', 'TenantGroup', 'Contact', 'ContactRole',
            'VirtualMachine', 'Cluster', 'ClusterType', 'ClusterGroup', 'VMInterface',
            'Circuit', 'Provider', 'CircuitType',
            'Tunnel', 'TunnelGroup', 'L2VPN', 'IKEPolicy', 'IPSecPolicy', 'IPSecProfile',
            'WirelessLAN', 'WirelessLANGroup',
            'Tag', 'CustomField', 'Webhook', 'ConfigContext'
        )]
        [string]$ObjectType
    )

    $prefix = Get-TestPrefix

    switch ($ObjectType) {
        # DCIM - most use Query parameter for partial matching
        'Site'          { Get-NBDCIMSite -Query $prefix }
        'Device'        { Get-NBDCIMDevice -Query $prefix }
        'DeviceType'    { Get-NBDCIMDeviceType -Query $prefix }
        'DeviceRole'    { Get-NBDCIMDeviceRole -All | Where-Object { $_.name -like "$prefix*" } }
        'Manufacturer'  { Get-NBDCIMManufacturer -Query $prefix }
        'Platform'      { Get-NBDCIMPlatform -All | Where-Object { $_.name -like "$prefix*" } }
        'Rack'          { Get-NBDCIMRack -Query $prefix }
        'RackRole'      { Get-NBDCIMRackRole -Query $prefix }
        'RackType'      { Get-NBDCIMRackType -Query $prefix }
        'Location'      { Get-NBDCIMLocation -Query $prefix }
        'Region'        { Get-NBDCIMRegion -Query $prefix }
        'SiteGroup'     { Get-NBDCIMSiteGroup -Query $prefix }
        'Interface'     { Get-NBDCIMInterface -All | Where-Object { $_.device.name -like "$prefix*" } }
        'Cable'         { Get-NBDCIMCable -All | Where-Object { $_.description -like "*$prefix*" -or ($_.a_terminations -and $_.a_terminations[0].object.device.name -like "$prefix*") } }
        'FrontPort'     { Get-NBDCIMFrontPort -All | Where-Object { $_.device.name -like "$prefix*" } }
        'RearPort'      { Get-NBDCIMRearPort -All | Where-Object { $_.device.name -like "$prefix*" } }

        # IPAM - use Query parameter
        'Prefix'        { Get-NBIPAMPrefix -Query $prefix }
        'Address'       { Get-NBIPAMAddress -Query $prefix }
        'VLAN'          { Get-NBIPAMVLAN -Query $prefix }
        'VLANGroup'     { Get-NBIPAMVLANGroup -Query $prefix }
        'VRF'           { Get-NBIPAMVRF -Query $prefix }
        'Aggregate'     { Get-NBIPAMAggregate -Query $prefix }
        'RIR'           { Get-NBIPAMRIR -Query $prefix }
        'Role'          { Get-NBIPAMRole -Query $prefix }

        # Tenancy
        'Tenant'        { Get-NBTenant -Query $prefix }
        'TenantGroup'   { Get-NBTenantGroup -Query $prefix }
        'Contact'       { Get-NBContact -Query $prefix }
        'ContactRole'   { Get-NBContactRole -Query $prefix }

        # Virtualization
        'VirtualMachine' { Get-NBVirtualMachine -Query $prefix }
        'Cluster'        { Get-NBVirtualizationCluster -Query $prefix }
        'ClusterType'    { Get-NBVirtualizationClusterType -Query $prefix }
        'ClusterGroup'   { Get-NBVirtualizationClusterGroup -Query $prefix }
        'VMInterface'    { Get-NBVirtualMachineInterface -Query $prefix }

        # Circuits
        'Circuit'       { Get-NBCircuit -Query $prefix }
        'Provider'      { Get-NBCircuitProvider -Query $prefix }
        'CircuitType'   { Get-NBCircuitType -Query $prefix }

        # VPN
        'Tunnel'        { Get-NBVPNTunnel -Query $prefix }
        'TunnelGroup'   { Get-NBVPNTunnelGroup -All | Where-Object { $_.name -like "$prefix*" } }
        'L2VPN'         { Get-NBVPNL2VPN -All | Where-Object { $_.name -like "$prefix*" } }
        'IKEPolicy'     { Get-NBVPNIKEPolicy -All | Where-Object { $_.name -like "$prefix*" } }
        'IPSecPolicy'   { Get-NBVPNIPSecPolicy -All | Where-Object { $_.name -like "$prefix*" } }
        'IPSecProfile'  { Get-NBVPNIPSecProfile -All | Where-Object { $_.name -like "$prefix*" } }

        # Wireless
        'WirelessLAN'      { Get-NBWirelessLAN -All | Where-Object { $_.ssid -like "$prefix*" } }
        'WirelessLANGroup' { Get-NBWirelessLANGroup -All | Where-Object { $_.name -like "$prefix*" } }

        # Extras
        'Tag'           { Get-NBTag -All | Where-Object { $_.name -like "$prefix*" } }
        'CustomField'   { Get-NBCustomField -Query $prefix }
        'Webhook'       { Get-NBWebhook -Query $prefix }
        'ConfigContext' { Get-NBConfigContext -Query $prefix }

        default { throw "Unknown object type: $ObjectType" }
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'Get-ScenarioTestDataPath',
    'Get-ScenarioEnvironments',
    'Connect-ScenarioTest',
    'Import-ScenarioTestData',
    'Remove-ScenarioTestData',
    'Test-ScenarioTestData',
    'Get-TestPrefix',
    'Assert-ScenarioTestDataExists',
    'Get-ScenarioTestObjects'
)
