

#region File Add-NetboxDCIMFrontPort.ps1

function Add-NetboxDCIMFrontPort {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [uint64]$Device,

        [uint64]$Module,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$Label,

        [Parameter(Mandatory = $true)]
        [string]$Type,

        [ValidatePattern('^[0-9a-f]{6}$')]
        [string]$Color,

        [Parameter(Mandatory = $true)]
        [uint64]$Rear_Port,

        [uint64]$Rear_Port_Position,

        [string]$Description,

        [bool]$Mark_Connected,

        [uint16[]]$Tags

    )

    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'front-ports'))

    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

    $URI = BuildNewURI -Segments $URIComponents.Segments

    InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method POST
}

#endregion

#region File Add-NetboxDCIMInterface.ps1


function Add-NetboxDCIMInterface {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [uint64]$Device,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [ValidateSet('virtual', 'bridge', 'lag', '100base-tx', '1000base-t', '2.5gbase-t', '5gbase-t', '10gbase-t', '10gbase-cx4', '1000base-x-gbic', '1000base-x-sfp', '10gbase-x-sfpp', '10gbase-x-xfp', '10gbase-x-xenpak', '10gbase-x-x2', '25gbase-x-sfp28', '50gbase-x-sfp56', '40gbase-x-qsfpp', '50gbase-x-sfp28', '100gbase-x-cfp', '100gbase-x-cfp2', '200gbase-x-cfp2', '100gbase-x-cfp4', '100gbase-x-cpak', '100gbase-x-qsfp28', '200gbase-x-qsfp56', '400gbase-x-qsfpdd', '400gbase-x-osfp', '1000base-kx', '10gbase-kr', '10gbase-kx4', '25gbase-kr', '40gbase-kr4', '50gbase-kr', '100gbase-kp4', '100gbase-kr2', '100gbase-kr4', 'ieee802.11a', 'ieee802.11g', 'ieee802.11n', 'ieee802.11ac', 'ieee802.11ad', 'ieee802.11ax', 'ieee802.11ay', 'ieee802.15.1', 'other-wireless', 'gsm', 'cdma', 'lte', 'sonet-oc3', 'sonet-oc12', 'sonet-oc48', 'sonet-oc192', 'sonet-oc768', 'sonet-oc1920', 'sonet-oc3840', '1gfc-sfp', '2gfc-sfp', '4gfc-sfp', '8gfc-sfpp', '16gfc-sfpp', '32gfc-sfp28', '64gfc-qsfpp', '128gfc-qsfp28', 'infiniband-sdr', 'infiniband-ddr', 'infiniband-qdr', 'infiniband-fdr10', 'infiniband-fdr', 'infiniband-edr', 'infiniband-hdr', 'infiniband-ndr', 'infiniband-xdr', 't1', 'e1', 't3', 'e3', 'xdsl', 'docsis', 'gpon', 'xg-pon', 'xgs-pon', 'ng-pon2', 'epon', '10g-epon', 'cisco-stackwise', 'cisco-stackwise-plus', 'cisco-flexstack', 'cisco-flexstack-plus', 'cisco-stackwise-80', 'cisco-stackwise-160', 'cisco-stackwise-320', 'cisco-stackwise-480', 'juniper-vcp', 'extreme-summitstack', 'extreme-summitstack-128', 'extreme-summitstack-256', 'extreme-summitstack-512', 'other', IgnoreCase = $true)]
        [string]$Type,

        [bool]$Enabled,

        [object]$Form_Factor,

        [uint16]$MTU,

        [string]$MAC_Address,

        [bool]$MGMT_Only,

        [uint64]$LAG,

        [string]$Description,

        [ValidateSet('Access', 'Tagged', 'Tagged All', '100', '200', '300', IgnoreCase = $true)]
        [string]$Mode,

        [ValidateRange(1, 4094)]
        [uint16]$Untagged_VLAN,

        [ValidateRange(1, 4094)]
        [uint16[]]$Tagged_VLANs
    )

    if (-not [System.String]::IsNullOrWhiteSpace($Mode)) {
        $PSBoundParameters.Mode = switch ($Mode) {
            'Access' {
                100
                break
            }

            'Tagged' {
                200
                break
            }

            'Tagged All' {
                300
                break
            }

            default {
                $_
            }
        }
    }

    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'interfaces'))

    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

    $URI = BuildNewURI -Segments $URIComponents.Segments

    InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method POST
}

#endregion

#region File Add-NetboxDCIMInterfaceConnection.ps1


function Add-NetboxDCIMInterfaceConnection {
    <#
    .SYNOPSIS
        Create a new connection between two interfaces

    .DESCRIPTION
        Create a new connection between two interfaces

    .PARAMETER Connection_Status
        Is it connected or planned?

    .PARAMETER Interface_A
        Database ID of interface A

    .PARAMETER Interface_B
        Database ID of interface B

    .EXAMPLE
        PS C:\> Add-NetboxDCIMInterfaceConnection -Interface_A $value1 -Interface_B $value2

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [object]$Connection_Status,

        [Parameter(Mandatory = $true)]
        [uint64]$Interface_A,

        [Parameter(Mandatory = $true)]
        [uint64]$Interface_B
    )

    # Verify if both Interfaces exist
    Get-NetboxDCIMInterface -Id $Interface_A -ErrorAction Stop | Out-null
    Get-NetboxDCIMInterface -Id $Interface_B -ErrorAction Stop | Out-null

    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'interface-connections'))

    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

    $URI = BuildNewURI -Segments $URIComponents.Segments

    InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method POST
}

#endregion

#region File Add-NetboxDCIMRearPort.ps1

function Add-NetboxDCIMRearPort {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [uint64]$Device,

        [uint64]$Module,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$Label,

        [Parameter(Mandatory = $true)]
        [string]$Type,

        [ValidatePattern('^[0-9a-f]{6}$')]
        [string]$Color,

        [uint16]$Positions = 1,

        [string]$Description,

        [bool]$Mark_Connected,

        [uint16[]]$Tags
    )

    begin {

    }

    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'rear-ports'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

        $URI = BuildNewURI -Segments $URIComponents.Segments

        InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method POST
    }

    end {

    }
}

#endregion

#region File Add-NetboxVirtualMachineInterface.ps1


function Add-NetboxVirtualMachineInterface {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [uint64]$Virtual_Machine,

        [boolean]$Enabled = $true,

        [string]$MAC_Address,

        [uint16]$MTU,

        [string]$Description,

        [switch]$Raw
    )

    $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'interfaces'))

    $PSBoundParameters.Enabled = $Enabled

    $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

    $uri = BuildNewURI -Segments $URIComponents.Segments

    InvokeNetboxRequest -URI $uri -Method POST -Body $URIComponents.Parameters
}

#endregion

#region File BuildNewURI.ps1


function BuildNewURI {
<#
    .SYNOPSIS
        Create a new URI for Netbox

    .DESCRIPTION
        Internal function used to build a URIBuilder object.

    .PARAMETER Hostname
        Hostname of the Netbox API

    .PARAMETER Segments
        Array of strings for each segment in the URL path

    .PARAMETER Parameters
        Hashtable of query parameters to include

    .PARAMETER HTTPS
        Whether to use HTTPS or HTTP

    .PARAMETER Port
        A description of the Port parameter.

    .PARAMETER APIInfo
        A description of the APIInfo parameter.

    .EXAMPLE
        PS C:\> BuildNewURI

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding()]
    [OutputType([System.UriBuilder])]
    param
    (
        [Parameter(Mandatory = $false)]
        [string[]]$Segments,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters,

        [switch]$SkipConnectedCheck
    )

    Write-Verbose "Building URI"

    if (-not $SkipConnectedCheck) {
        # There is no point in continuing if we have not successfully connected to an API
        $null = CheckNetboxIsConnected
    }

    # Begin a URI builder with HTTP/HTTPS and the provided hostname
    $uriBuilder = [System.UriBuilder]::new($script:NetboxConfig.HostScheme, $script:NetboxConfig.Hostname, $script:NetboxConfig.HostPort)

    # Generate the path by trimming excess slashes and whitespace from the $segments[] and joining together
    $uriBuilder.Path = "api/{0}/" -f ($Segments.ForEach({
                $_.trim('/').trim()
            }) -join '/')

    Write-Verbose " URIPath: $($uriBuilder.Path)"

    if ($parameters) {
        # Loop through the parameters and use the HttpUtility to create a Query string
        [System.Collections.Specialized.NameValueCollection]$URIParams = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)

        foreach ($param in $Parameters.GetEnumerator()) {
            Write-Verbose " Adding URI parameter $($param.Key):$($param.Value)"
            $URIParams[$param.Key] = $param.Value
        }

        $uriBuilder.Query = $URIParams.ToString()
    }

    Write-Verbose " Completed building URIBuilder"
    # Return the entire UriBuilder object
    $uriBuilder
}

#endregion

#region File BuildURIComponents.ps1


function BuildURIComponents {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$URISegments,

        [Parameter(Mandatory = $true)]
        [object]$ParametersDictionary,

        [string[]]$SkipParameterByName
    )

    Write-Verbose "Building URI components"

    $URIParameters = @{
    }

    foreach ($CmdletParameterName in $ParametersDictionary.Keys) {
        if ($CmdletParameterName -in $script:CommonParameterNames) {
            # These are common parameters and should not be appended to the URI
            Write-Debug "Skipping common parameter $CmdletParameterName"
            continue
        }

        if ($CmdletParameterName -in $SkipParameterByName) {
            Write-Debug "Skipping parameter $CmdletParameterName by SkipParameterByName"
            continue
        }

        switch ($CmdletParameterName) {
            "id" {
                # Check if there is one or more values for Id and build a URI or query as appropriate
                if (@($ParametersDictionary[$CmdletParameterName]).Count -gt 1) {
                    Write-Verbose " Joining IDs for parameter"
                    $URIParameters['id__in'] = $ParametersDictionary[$CmdletParameterName] -join ','
                } else {
                    Write-Verbose " Adding ID to segments"
                    [void]$uriSegments.Add($ParametersDictionary[$CmdletParameterName])
                }

                break
            }

            'Query' {
                Write-Verbose " Adding query parameter"
                $URIParameters['q'] = $ParametersDictionary[$CmdletParameterName]
                break
            }

            'CustomFields' {
                Write-Verbose " Adding custom field query parameters"
                foreach ($field in $ParametersDictionary[$CmdletParameterName].GetEnumerator()) {
                    Write-Verbose "  Adding parameter 'cf_$($field.Key) = $($field.Value)"
                    $URIParameters["cf_$($field.Key.ToLower())"] = $field.Value
                }

                break
            }

            default {
                Write-Verbose " Adding $($CmdletParameterName.ToLower()) parameter"
                $URIParameters[$CmdletParameterName.ToLower()] = $ParametersDictionary[$CmdletParameterName]
                break
            }
        }
    }

    return @{
        'Segments' = [System.Collections.ArrayList]$URISegments
        'Parameters' = $URIParameters
    }
}

#endregion

#region File CheckNetboxIsConnected.ps1


function CheckNetboxIsConnected {
    [CmdletBinding()]
    param ()

    Write-Verbose "Checking connection status"
    if (-not $script:NetboxConfig.Connected) {
        throw "Not connected to a Netbox API! Please run 'Connect-NetboxAPI'"
    }
}

#endregion

#region File Clear-NetboxCredential.ps1

function Clear-NetboxCredential {
    [CmdletBinding(ConfirmImpact = 'Medium', SupportsShouldProcess = $true)]
    param
    (
        [switch]$Force
    )

    if ($Force -or ($PSCmdlet.ShouldProcess('Netbox Credentials', 'Clear'))) {
        $script:NetboxConfig.Credential = $null
    }
}

#endregion

#region File Connect-NetboxAPI.ps1

function Connect-NetboxAPI {
<#
    .SYNOPSIS
        Connects to the Netbox API and ensures Credential work properly

    .DESCRIPTION
        Connects to the Netbox API and ensures Credential work properly

    .PARAMETER Hostname
        The hostname for the resource such as netbox.domain.com

    .PARAMETER Credential
        Credential object containing the API key in the password. Username is not applicable

    .PARAMETER Scheme
        Scheme for the URI such as HTTP or HTTPS. Defaults to HTTPS

    .PARAMETER Port
        Port for the resource. Value between 1-65535

    .PARAMETER URI
        The full URI for the resource such as "https://netbox.domain.com:8443"

    .PARAMETER SkipCertificateCheck
        A description of the SkipCertificateCheck parameter.

    .PARAMETER TimeoutSeconds
        The number of seconds before the HTTP call times out. Defaults to 30 seconds

    .EXAMPLE
        PS C:\> Connect-NetboxAPI -Hostname "netbox.domain.com"

        This will prompt for Credential, then proceed to attempt a connection to Netbox

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(DefaultParameterSetName = 'Manual')]
    param
    (
        [Parameter(ParameterSetName = 'Manual',
                   Mandatory = $true)]
        [string]$Hostname,

        [Parameter(Mandatory = $false)]
        [pscredential]$Credential,

        [Parameter(ParameterSetName = 'Manual')]
        [ValidateSet('https', 'http', IgnoreCase = $true)]
        [string]$Scheme = 'https',

        [Parameter(ParameterSetName = 'Manual')]
        [uint16]$Port = 443,

        [Parameter(ParameterSetName = 'URI',
                   Mandatory = $true)]
        [string]$URI,

        [Parameter(Mandatory = $false)]
        [switch]$SkipCertificateCheck = $false,

        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 65535)]
        [uint16]$TimeoutSeconds = 30
    )

    if (-not $Credential) {
        try {
            $Credential = Get-NetboxCredential -ErrorAction Stop
        } catch {
            # Credentials are not set... Try to obtain from the user
            if (-not ($Credential = Get-Credential -UserName 'username-not-applicable' -Message "Enter token for Netbox")) {
                throw "Token is necessary to connect to a Netbox API."
            }
        }
    }

    $invokeParams = @{ SkipCertificateCheck = $SkipCertificateCheck; }

    if ("Desktop" -eq $PSVersionTable.PsEdition) {
        #Remove -SkipCertificateCheck from Invoke Parameter (not supported <= PS 5)
        $invokeParams.remove("SkipCertificateCheck")
    }

    #for PowerShell (<=) 5 (Desktop), Enable TLS 1.1, 1.2 and Disable SSL chain trust
    if ("Desktop" -eq $PSVersionTable.PsEdition) {
        #Add System.web (Need for ParseQueryString)
        Add-Type -AssemblyName System.Web
        #Enable TLS 1.1 and 1.2
        Set-NetboxCipherSSL
        if ($SkipCertificateCheck) {
            #Disable SSL chain trust...
            Set-NetboxuntrustedSSL
        }
    }

    switch ($PSCmdlet.ParameterSetName) {
        'Manual' {
            $uriBuilder = [System.UriBuilder]::new($Scheme, $Hostname, $Port)
        }

        'URI' {
            $uriBuilder = [System.UriBuilder]::new($URI)
            if ([string]::IsNullOrWhiteSpace($uriBuilder.Host)) {
                throw "URI appears to be invalid. Must be in format [host.name], [scheme://host.name], or [scheme://host.name:port]"
            }
        }
    }

    $null = Set-NetboxHostName -Hostname $uriBuilder.Host
    $null = Set-NetboxCredential -Credential $Credential
    $null = Set-NetboxHostScheme -Scheme $uriBuilder.Scheme
    $null = Set-NetboxHostPort -Port $uriBuilder.Port
    $null = Set-NetboxInvokeParams -invokeParams $invokeParams
    $null = Set-NetboxTimeout -TimeoutSeconds $TimeoutSeconds

    try {
        Write-Verbose "Verifying API connectivity..."
        $null = VerifyAPIConnectivity
    } catch {
        Write-Verbose "Failed to connect. Generating error"
        Write-Verbose $_.Exception.Message
        if (($_.Exception.Response) -and ($_.Exception.Response.StatusCode -eq 403)) {
            throw "Invalid token"
        } else {
            throw $_
        }
    }

#    Write-Verbose "Caching API definition"
#    $script:NetboxConfig.APIDefinition = Get-NetboxAPIDefinition
#
#    if ([version]$script:NetboxConfig.APIDefinition.info.version -lt 2.8) {
#        $Script:NetboxConfig.Connected = $false
#        throw "Netbox version is incompatible with this PS module. Requires >=2.8.*, found version $($script:NetboxConfig.APIDefinition.info.version)"
    #    }

    Write-Verbose "Checking Netbox version compatibility"
    $script:NetboxConfig.NetboxVersion = Get-NetboxVersion
    if ([version]$script:NetboxConfig.NetboxVersion.'netbox-version' -lt 2.8) {
        $Script:NetboxConfig.Connected = $false
        throw "Netbox version is incompatible with this PS module. Requires >=2.8.*, found version $($script:NetboxConfig.NetboxVersion.'netbox-version')"
    } else {
        Write-Verbose "Found compatible version [$($script:NetboxConfig.NetboxVersion.'netbox-version')]!"
    }

    $script:NetboxConfig.Connected = $true
    Write-Verbose "Successfully connected!"

    $script:NetboxConfig.ContentTypes = Get-NetboxContentType -Limit 500

    Write-Verbose "Connection process completed"
}

#endregion

#region File CreateEnum.ps1


function CreateEnum {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$EnumName,

        [Parameter(Mandatory = $true)]
        [pscustomobject]$Values,

        [switch]$PassThru
    )

    $definition = @"
public enum $EnumName
{`n$(foreach ($value in $values) {
            "`t$($value.label) = $($value.value),`n"
        })
}
"@
    if (-not ([System.Management.Automation.PSTypeName]"$EnumName").Type) {
        #Write-Host $definition -ForegroundColor Green
        Add-Type -TypeDefinition $definition -PassThru:$PassThru
    } else {
        Write-Warning "EnumType $EnumName already exists."
    }
}

#endregion

#region File Get-ModelDefinition.ps1


function Get-ModelDefinition {
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param
    (
        [Parameter(ParameterSetName = 'ByName',
                   Mandatory = $true)]
        [string]$ModelName,

        [Parameter(ParameterSetName = 'ByPath',
                   Mandatory = $true)]
        [string]$URIPath,

        [Parameter(ParameterSetName = 'ByPath')]
        [string]$Method = "post"
    )

    switch ($PsCmdlet.ParameterSetName) {
        'ByName' {
            $script:NetboxConfig.APIDefinition.definitions.$ModelName
            break
        }

        'ByPath' {
            switch ($Method) {
                "get" {

                    break
                }

                "post" {
                    if (-not $URIPath.StartsWith('/')) {
                        $URIPath = "/$URIPath"
                    }

                    if (-not $URIPath.EndsWith('/')) {
                        $URIPath = "$URIPath/"
                    }

                    $ModelName = $script:NetboxConfig.APIDefinition.paths.$URIPath.post.parameters.schema.'$ref'.split('/')[-1]
                    $script:NetboxConfig.APIDefinition.definitions.$ModelName
                    break
                }
            }

            break
        }
    }

}

#endregion

#region File Get-NetboxAPIDefinition.ps1


function Get-NetboxAPIDefinition {
    [CmdletBinding()]
    param
    (
        [ValidateSet('json', 'yaml', IgnoreCase = $true)]
        [string]$Format = 'json'
    )

    #$URI = "https://netbox.neonet.org/api/schema/?format=json"

    $Segments = [System.Collections.ArrayList]::new(@('schema'))

    $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary @{
        'format' = $Format.ToLower()
    }

    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters -SkipConnectedCheck

    InvokeNetboxRequest -URI $URI
}

#endregion

#region File Get-NetboxCircuit.ps1


function Get-NetboxCircuit {
    <#
    .SYNOPSIS
        Gets one or more circuits

    .DESCRIPTION
        A detailed description of the Get-NetboxCircuit function.

    .PARAMETER Id
        Database ID of circuit. This will query for exactly the IDs provided

    .PARAMETER CID
        Circuit ID

    .PARAMETER InstallDate
        Date of installation

    .PARAMETER CommitRate
        Committed rate in Kbps

    .PARAMETER Query
        A raw search query... As if you were searching the web site

    .PARAMETER Provider
        The name or ID of the provider. Provide either [string] or [uint64]. String will search provider names, integer will search database IDs

    .PARAMETER Type
        Type of circuit. Provide either [string] or [uint64]. String will search provider type names, integer will search database IDs

    .PARAMETER Site
        Location/site of circuit. Provide either [string] or [uint64]. String will search site names, integer will search database IDs

    .PARAMETER Tenant
        Tenant assigned to circuit. Provide either [string] or [uint64]. String will search tenant names, integer will search database IDs

    .PARAMETER Limit
        A description of the Limit parameter.

    .PARAMETER Offset
        A description of the Offset parameter.

    .PARAMETER Raw
        A description of the Raw parameter.

    .PARAMETER ID__IN
        Multiple unique DB IDs to retrieve

    .EXAMPLE
        PS C:\> Get-NetboxCircuit

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param
    (
        [Parameter(ParameterSetName = 'ById')]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$CID,

        [Parameter(ParameterSetName = 'Query')]
        [datetime]$InstallDate,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$CommitRate,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [object]$Provider,

        [Parameter(ParameterSetName = 'Query')]
        [object]$Type,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Site,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Tenant,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $ID) {
                    $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuits', $i))

                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName "Id"

                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuits'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NetboxCircuitProvider.ps1


function Get-NetboxCircuitProvider {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param
    (
        [Parameter(ParameterSetName = 'ById',
                   Mandatory = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query',
                   Mandatory = $false)]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [string]$ASN,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Account,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($i in $ID) {
                $Segments = [System.Collections.ArrayList]::new(@('circuits', 'providers', $i))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName "Id"

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('circuits', 'providers'))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

            $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $URI -Raw:$Raw
        }
    }
}

#endregion

#region File Get-NetboxCircuitTermination.ps1


function Get-NetboxCircuitTermination {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param
    (
        [Parameter(ParameterSetName = 'ById',
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Circuit_ID,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Term_Side,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Port_Speed,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Site_ID,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Site,

        [Parameter(ParameterSetName = 'Query')]
        [string]$XConnect_ID,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $ID) {
                    $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-terminations', $i))

                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName "Id"

                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-terminations'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NetboxCircuitType.ps1


function Get-NetboxCircuitType {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param
    (
        [Parameter(ParameterSetName = 'ById')]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($i in $ID) {
                $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit_types', $i))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName "Id"

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-types'))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

            $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $URI -Raw:$Raw
        }
    }
}

#endregion

#region File Get-NetboxContact.ps1


function Get-NetboxContact {
<#
    .SYNOPSIS
        Get a contact from Netbox

    .DESCRIPTION
        Obtain a contact or contacts from Netbox by ID or query

    .PARAMETER Name
        The specific name of the Contact. Must match exactly as is defined in Netbox

    .PARAMETER Id
        The database ID of the Contact

    .PARAMETER Query
        A standard search query that will match one or more Contacts.

    .PARAMETER Email
        Email address of the contact

    .PARAMETER Title
        Title of the contact

    .PARAMETER Phone
        Telephone number of the contact

    .PARAMETER Address
        Physical address of the contact

    .PARAMETER Group
        The specific group as defined in Netbox.

    .PARAMETER GroupID
        The database ID of the group in Netbox

    .PARAMETER Limit
        Limit the number of results to this number

    .PARAMETER Offset
        Start the search at this index in results

    .PARAMETER Raw
        Return the unparsed data from the HTTP request

    .EXAMPLE
        PS C:\> Get-NetboxContact

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param
    (
        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [string]$Name,

        [Parameter(ParameterSetName = 'ByID')]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Email,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Title,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Phone,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Address,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Group,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$GroupID,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($Contact_ID in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contacts', $Contact_ID))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id'

                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $uri -Raw:$Raw
            }

            break
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contacts'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

            $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $uri -Raw:$Raw

            break
        }
    }
}

#endregion

#region File Get-NetboxContactAssignment.ps1


function Get-NetboxContactAssignment {
<#
    .SYNOPSIS
        Get a contact Assignment from Netbox

    .DESCRIPTION
        A detailed description of the Get-NetboxContactAssignment function.

    .PARAMETER Name
        The specific name of the contact Assignment. Must match exactly as is defined in Netbox

    .PARAMETER Id
        The database ID of the contact Assignment

    .PARAMETER Content_Type_Id
        A description of the Content_Type_Id parameter.

    .PARAMETER Content_Type
        A description of the Content_Type parameter.

    .PARAMETER Object_Id
        A description of the Object_Id parameter.

    .PARAMETER Contact_Id
        A description of the Contact_Id parameter.

    .PARAMETER Role_Id
        A description of the Role_Id parameter.

    .PARAMETER Limit
        Limit the number of results to this number

    .PARAMETER Offset
        Start the search at this index in results

    .PARAMETER Raw
        Return the unparsed data from the HTTP request

    .EXAMPLE
        PS C:\> Get-NetboxContactAssignment

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param
    (
        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [string]$Name,

        [Parameter(ParameterSetName = 'ByID')]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Content_Type_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Content_Type,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Object_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Contact_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Role_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($ContactAssignment_ID in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contact-assignments', $ContactAssignment_ID))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id'

                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $uri -Raw:$Raw
            }

            break
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contact-assignments'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

            $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $uri -Raw:$Raw

            break
        }
    }
}

#endregion

#region File Get-NetboxContactRole.ps1


function Get-NetboxContactRole {
<#
    .SYNOPSIS
        Get a contact role from Netbox

    .DESCRIPTION
        A detailed description of the Get-NetboxContactRole function.

    .PARAMETER Name
        The specific name of the contact role. Must match exactly as is defined in Netbox

    .PARAMETER Id
        The database ID of the contact role

    .PARAMETER Query
        A standard search query that will match one or more contact roles.

    .PARAMETER Limit
        Limit the number of results to this number

    .PARAMETER Offset
        Start the search at this index in results

    .PARAMETER Raw
        Return the unparsed data from the HTTP request

    .EXAMPLE
        PS C:\> Get-NetboxContactRole

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param
    (
        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [string]$Name,

        [Parameter(ParameterSetName = 'ByID')]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Description,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($ContactRole_ID in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contact-roles', $ContactRole_ID))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id'

                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $uri -Raw:$Raw
            }

            break
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contact-roles'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

            $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $uri -Raw:$Raw

            break
        }
    }
}

#endregion

#region File Get-NetboxContentType.ps1

function Get-NetboxContentType {
<#
    .SYNOPSIS
        Get a content type definition from Netbox

    .DESCRIPTION
        A detailed description of the Get-NetboxContentType function.

    .PARAMETER Model
        A description of the Model parameter.

    .PARAMETER Id
        The database ID of the contact role

    .PARAMETER App_Label
        A description of the App_Label parameter.

    .PARAMETER Query
        A standard search query that will match one or more contact roles.

    .PARAMETER Limit
        Limit the number of results to this number

    .PARAMETER Offset
        Start the search at this index in results

    .PARAMETER Raw
        Return the unparsed data from the HTTP request

    .EXAMPLE
        PS C:\> Get-NetboxContentType

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param
    (
        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [string]$Model,

        [Parameter(ParameterSetName = 'ByID')]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$App_Label,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($ContentType_ID in $Id) {
                # Netbox 4.x moved content-types from /extras/ to /core/object-types/
                $Segments = [System.Collections.ArrayList]::new(@('core', 'object-types', $ContentType_ID))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id'

                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $uri -Raw:$Raw
            }

            break
        }

        default {
            # Netbox 4.x moved content-types from /extras/ to /core/object-types/
            $Segments = [System.Collections.ArrayList]::new(@('core', 'object-types'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

            $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $uri -Raw:$Raw

            break
        }
    }
}

#endregion

#region File Get-NetboxCredential.ps1

function Get-NetboxCredential {
    [CmdletBinding()]
    [OutputType([pscredential])]
    param ()

    if (-not $script:NetboxConfig.Credential) {
        throw "Netbox Credentials not set! You may set with Set-NetboxCredential"
    }

    $script:NetboxConfig.Credential
}

#endregion

#region File Get-NetboxDCIMCable.ps1

function Get-NetboxDCIMCable {
    [CmdletBinding()]
    #region Parameters
    param
    (
        [uint16]$Limit,

        [uint16]$Offset,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Label,

        [string]$Termination_A_Type,

        [uint64]$Termination_A_ID,

        [string]$Termination_B_Type,

        [uint64]$Termination_B_ID,

        [string]$Type,

        [string]$Status,

        [string]$Color,

        [uint64]$Device_ID,

        [string]$Device,

        [uint64]$Rack_Id,

        [string]$Rack,

        [uint64]$Location_ID,

        [string]$Location,

        [switch]$Raw
    )

    #endregion Parameters

    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cables'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $URI -Raw:$Raw
    }
}

#endregion

#region File Get-NetboxDCIMCableTermination.ps1

function Get-NetboxDCIMCableTermination {
    [CmdletBinding()]
    #region Parameters
    param
    (
        [uint16]$Limit,

        [uint16]$Offset,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [uint64]$Cable,

        [string]$Cable_End,

        [string]$Termination_Type,

        [uint64]$Termination_ID,

        [switch]$Raw
    )

    #endregion Parameters

    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cable-terminations'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $URI -Raw:$Raw
    }
}

#endregion

#region File Get-NetboxDCIMDevice.ps1


function Get-NetboxDCIMDevice {
    [CmdletBinding()]
    #region Parameters
    param
    (
        [uint16]$Limit,

        [uint16]$Offset,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Query,

        [string]$Name,

        [uint64]$Manufacturer_Id,

        [string]$Manufacturer,

        [uint64]$Device_Type_Id,

        [uint64]$Role_Id,

        [string]$Role,

        [uint64]$Tenant_Id,

        [string]$Tenant,

        [uint64]$Platform_Id,

        [string]$Platform,

        [string]$Asset_Tag,

        [uint64]$Site_Id,

        [string]$Site,

        [uint64]$Rack_Group_Id,

        [uint64]$Rack_Id,

        [uint64]$Cluster_Id,

        [uint64]$Model,

        [object]$Status,

        [bool]$Is_Full_Depth,

        [bool]$Is_Console_Server,

        [bool]$Is_PDU,

        [bool]$Is_Network_Device,

        [string]$MAC_Address,

        [bool]$Has_Primary_IP,

        [uint64]$Virtual_Chassis_Id,

        [uint16]$Position,

        [string]$Serial,

        [switch]$Raw
    )

    #endregion Parameters

    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'devices'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $URI -Raw:$Raw
    }
}

#endregion

#region File Get-NetboxDCIMDeviceRole.ps1


function Get-NetboxDCIMDeviceRole {
    [CmdletBinding()]
    param
    (
        [uint16]$Limit,

        [uint16]$Offset,

        [Parameter(ParameterSetName = 'ById')]
        [uint64[]]$Id,

        [string]$Name,

        [string]$Slug,

        [string]$Color,

        [bool]$VM_Role,

        [switch]$Raw
    )

    switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($DRId in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'device-roles', $DRId))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }

            break
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('dcim', 'device-roles'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

            $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $URI -Raw:$Raw
        }
    }
}

#endregion

#region File Get-NetboxDCIMDeviceType.ps1


function Get-NetboxDCIMDeviceType {
    [CmdletBinding()]
    #region Parameters
    param
    (
        [uint16]$Offset,

        [uint16]$Limit,

        [uint64[]]$Id,

        [string]$Query,

        [string]$Slug,

        [string]$Manufacturer,

        [uint64]$Manufacturer_Id,

        [string]$Model,

        [string]$Part_Number,

        [uint16]$U_Height,

        [bool]$Is_Full_Depth,

        [bool]$Is_Console_Server,

        [bool]$Is_PDU,

        [bool]$Is_Network_Device,

        [uint16]$Subdevice_Role,

        [switch]$Raw
    )
    #endregion Parameters

    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'device-types'))

    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

    InvokeNetboxRequest -URI $URI -Raw:$Raw
}

#endregion

#region File Get-NetboxDCIMFrontPort.ps1

function Get-NetboxDCIMFrontPort {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [uint16]$Limit,

        [uint16]$Offset,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Device,

        [uint64]$Device_Id,

        [string]$Type,

        [switch]$Raw
    )

    process {

        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'front-ports'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $URI -Raw:$Raw
    }
}

#endregion

#region File Get-NetboxDCIMInterface.ps1

function Get-NetboxDCIMInterface {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [uint16]$Limit,

        [uint16]$Offset,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [uint64]$Name,

        [object]$Form_Factor,

        [bool]$Enabled,

        [uint16]$MTU,

        [bool]$MGMT_Only,

        [string]$Device,

        [uint64]$Device_Id,

        [ValidateSet('virtual', 'bridge', 'lag', '100base-tx', '1000base-t', '2.5gbase-t', '5gbase-t', '10gbase-t', '10gbase-cx4', '1000base-x-gbic', '1000base-x-sfp', '10gbase-x-sfpp', '10gbase-x-xfp', '10gbase-x-xenpak', '10gbase-x-x2', '25gbase-x-sfp28', '50gbase-x-sfp56', '40gbase-x-qsfpp', '50gbase-x-sfp28', '100gbase-x-cfp', '100gbase-x-cfp2', '200gbase-x-cfp2', '100gbase-x-cfp4', '100gbase-x-cpak', '100gbase-x-qsfp28', '200gbase-x-qsfp56', '400gbase-x-qsfpdd', '400gbase-x-osfp', '1000base-kx', '10gbase-kr', '10gbase-kx4', '25gbase-kr', '40gbase-kr4', '50gbase-kr', '100gbase-kp4', '100gbase-kr2', '100gbase-kr4', 'ieee802.11a', 'ieee802.11g', 'ieee802.11n', 'ieee802.11ac', 'ieee802.11ad', 'ieee802.11ax', 'ieee802.11ay', 'ieee802.15.1', 'other-wireless', 'gsm', 'cdma', 'lte', 'sonet-oc3', 'sonet-oc12', 'sonet-oc48', 'sonet-oc192', 'sonet-oc768', 'sonet-oc1920', 'sonet-oc3840', '1gfc-sfp', '2gfc-sfp', '4gfc-sfp', '8gfc-sfpp', '16gfc-sfpp', '32gfc-sfp28', '64gfc-qsfpp', '128gfc-qsfp28', 'infiniband-sdr', 'infiniband-ddr', 'infiniband-qdr', 'infiniband-fdr10', 'infiniband-fdr', 'infiniband-edr', 'infiniband-hdr', 'infiniband-ndr', 'infiniband-xdr', 't1', 'e1', 't3', 'e3', 'xdsl', 'docsis', 'gpon', 'xg-pon', 'xgs-pon', 'ng-pon2', 'epon', '10g-epon', 'cisco-stackwise', 'cisco-stackwise-plus', 'cisco-flexstack', 'cisco-flexstack-plus', 'cisco-stackwise-80', 'cisco-stackwise-160', 'cisco-stackwise-320', 'cisco-stackwise-480', 'juniper-vcp', 'extreme-summitstack', 'extreme-summitstack-128', 'extreme-summitstack-256', 'extreme-summitstack-512', 'other', IgnoreCase = $true)]
        [string]$Type,

        [uint64]$LAG_Id,

        [string]$MAC_Address,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'interfaces'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $URI -Raw:$Raw
    }
}

#endregion

#region File Get-NetboxDCIMInterfaceConnection.ps1


function Get-NetboxDCIMInterfaceConnection {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [uint16]$Limit,

        [uint16]$Offset,

        [uint64]$Id,

        [object]$Connection_Status,

        [uint64]$Site,

        [uint64]$Device,

        [switch]$Raw
    )

    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'interface-connections'))

    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

    InvokeNetboxRequest -URI $URI -Raw:$Raw
}

#endregion

#region File Get-NetboxDCIMLocation.ps1

function Get-NetboxDCIMLocation {
<#
    .SYNOPSIS
        Get locations from Netbox

    .DESCRIPTION
        Retrieves location objects from Netbox with optional filtering.
        Locations represent physical areas within a site (e.g., floors, rooms, cages).

    .PARAMETER Id
        The ID of the location to retrieve

    .PARAMETER Name
        Filter by location name

    .PARAMETER Query
        A general search query

    .PARAMETER Slug
        Filter by slug

    .PARAMETER Site_Id
        Filter by site ID

    .PARAMETER Site
        Filter by site name

    .PARAMETER Parent_Id
        Filter by parent location ID

    .PARAMETER Status
        Filter by status (planned, staging, active, decommissioning, retired)

    .PARAMETER Tenant_Id
        Filter by tenant ID

    .PARAMETER Limit
        Limit the number of results

    .PARAMETER Offset
        Offset for pagination

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Get-NetboxDCIMLocation

        Returns all locations

    .EXAMPLE
        Get-NetboxDCIMLocation -Site_Id 1

        Returns all locations at site with ID 1

    .EXAMPLE
        Get-NetboxDCIMLocation -Name "Server Room"

        Returns locations matching the name "Server Room"
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ParameterSetName = 'ByID',
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Site_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Site,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Parent_Id,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('planned', 'staging', 'active', 'decommissioning', 'retired')]
        [string]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($LocationId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'locations', $LocationId))

                    $URI = BuildNewURI -Segments $Segments

                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'locations'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NetboxDCIMManufacturer.ps1

function Get-NetboxDCIMManufacturer {
<#
    .SYNOPSIS
        Get manufacturers from Netbox

    .DESCRIPTION
        Retrieves manufacturer objects from Netbox with optional filtering.

    .PARAMETER Id
        The ID of the manufacturer to retrieve

    .PARAMETER Name
        Filter by manufacturer name

    .PARAMETER Slug
        Filter by slug

    .PARAMETER Query
        A general search query

    .PARAMETER Limit
        Limit the number of results

    .PARAMETER Offset
        Offset for pagination

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Get-NetboxDCIMManufacturer

        Returns all manufacturers

    .EXAMPLE
        Get-NetboxDCIMManufacturer -Name "Cisco"

        Returns manufacturers matching the name "Cisco"
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ParameterSetName = 'ByID',
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($ManufacturerId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'manufacturers', $ManufacturerId))

                    $URI = BuildNewURI -Segments $Segments

                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'manufacturers'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NetboxDCIMPlatform.ps1


function Get-NetboxDCIMPlatform {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [uint16]$Limit,

        [uint16]$Offset,

        [Parameter(ParameterSetName = 'ById')]
        [uint64[]]$Id,

        [string]$Name,

        [string]$Slug,

        [uint64]$Manufacturer_Id,

        [string]$Manufacturer,

        [switch]$Raw
    )

    switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($PlatformID in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'platforms', $PlatformID))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }

            break
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('dcim', 'platforms'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

            $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $URI -Raw:$Raw
        }
    }
}

#endregion

#region File Get-NetboxDCIMRack.ps1

function Get-NetboxDCIMRack {
<#
    .SYNOPSIS
        Get racks from Netbox

    .DESCRIPTION
        Retrieves rack objects from Netbox with optional filtering.

    .PARAMETER Id
        The ID of the rack to retrieve

    .PARAMETER Name
        Filter by rack name

    .PARAMETER Query
        A general search query

    .PARAMETER Site_Id
        Filter by site ID

    .PARAMETER Site
        Filter by site name

    .PARAMETER Location_Id
        Filter by location ID

    .PARAMETER Tenant_Id
        Filter by tenant ID

    .PARAMETER Status
        Filter by status (active, planned, reserved, deprecated)

    .PARAMETER Role_Id
        Filter by role ID

    .PARAMETER Serial
        Filter by serial number

    .PARAMETER Asset_Tag
        Filter by asset tag

    .PARAMETER Facility_Id
        Filter by facility ID

    .PARAMETER Limit
        Limit the number of results

    .PARAMETER Offset
        Offset for pagination

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Get-NetboxDCIMRack

        Returns all racks

    .EXAMPLE
        Get-NetboxDCIMRack -Site_Id 1

        Returns all racks at site with ID 1

    .EXAMPLE
        Get-NetboxDCIMRack -Name "Rack-01"

        Returns racks matching the name "Rack-01"
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ParameterSetName = 'ByID',
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Site_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Site,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Location_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_Id,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('active', 'planned', 'reserved', 'deprecated')]
        [string]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Role_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Serial,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Asset_Tag,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Facility_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($RackId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'racks', $RackId))

                    $URI = BuildNewURI -Segments $Segments

                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'racks'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NetboxDCIMRearPort.ps1

function Get-NetboxDCIMRearPort {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [uint16]$Limit,

        [uint16]$Offset,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Device,

        [uint64]$Device_Id,

        [string]$Type,

        [switch]$Raw
    )

    process {

        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'rear-ports'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $URI -Raw:$Raw
    }
}

#endregion

#region File Get-NetboxDCIMRegion.ps1

function Get-NetboxDCIMRegion {
<#
    .SYNOPSIS
        Get regions from Netbox

    .DESCRIPTION
        Retrieves region objects from Netbox with optional filtering.
        Regions are used to organize sites geographically (e.g., countries, states, cities).

    .PARAMETER Id
        The ID of the region to retrieve

    .PARAMETER Name
        Filter by region name

    .PARAMETER Query
        A general search query

    .PARAMETER Slug
        Filter by slug

    .PARAMETER Parent_Id
        Filter by parent region ID

    .PARAMETER Limit
        Limit the number of results

    .PARAMETER Offset
        Offset for pagination

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Get-NetboxDCIMRegion

        Returns all regions

    .EXAMPLE
        Get-NetboxDCIMRegion -Name "Europe"

        Returns regions matching the name "Europe"

    .EXAMPLE
        Get-NetboxDCIMRegion -Parent_Id 1

        Returns all child regions of region 1
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ParameterSetName = 'ByID',
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Parent_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($RegionId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'regions', $RegionId))

                    $URI = BuildNewURI -Segments $Segments

                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'regions'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NetboxDCIMSite.ps1


function Get-NetboxDCIMSite {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Facility,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$ASN,

        [Parameter(ParameterSetName = 'Query')]
        [decimal]$Latitude,

        [Parameter(ParameterSetName = 'Query')]
        [decimal]$Longitude,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Contact_Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Contact_Phone,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Contact_Email,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_Group_ID,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Tenant_Group,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_ID,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Tenant,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Region_ID,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Region,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($Site_ID in $ID) {
                    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'sites', $Site_Id))

                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName "Id"

                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'sites'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NetboxDCIMSiteGroup.ps1

function Get-NetboxDCIMSiteGroup {
<#
    .SYNOPSIS
        Get site groups from Netbox

    .DESCRIPTION
        Retrieves site group objects from Netbox with optional filtering.
        Site groups are used to organize sites by functional role (e.g., production, staging, DR).

    .PARAMETER Id
        The ID of the site group to retrieve

    .PARAMETER Name
        Filter by site group name

    .PARAMETER Query
        A general search query

    .PARAMETER Slug
        Filter by slug

    .PARAMETER Parent_Id
        Filter by parent site group ID

    .PARAMETER Limit
        Limit the number of results

    .PARAMETER Offset
        Offset for pagination

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Get-NetboxDCIMSiteGroup

        Returns all site groups

    .EXAMPLE
        Get-NetboxDCIMSiteGroup -Name "Production"

        Returns site groups matching the name "Production"

    .EXAMPLE
        Get-NetboxDCIMSiteGroup -Parent_Id 1

        Returns all child site groups of site group 1
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ParameterSetName = 'ByID',
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Parent_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($SiteGroupId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'site-groups', $SiteGroupId))

                    $URI = BuildNewURI -Segments $Segments

                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'site-groups'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NetboxHostname.ps1

function Get-NetboxHostname {
    [CmdletBinding()]
    param ()

    Write-Verbose "Getting Netbox hostname"
    if ($null -eq $script:NetboxConfig.Hostname) {
        throw "Netbox Hostname is not set! You may set it with Set-NetboxHostname -Hostname 'hostname.domain.tld'"
    }

    $script:NetboxConfig.Hostname
}

#endregion

#region File Get-NetboxHostPort.ps1

function Get-NetboxHostPort {
    [CmdletBinding()]
    param ()

    Write-Verbose "Getting Netbox host port"
    if ($null -eq $script:NetboxConfig.HostPort) {
        throw "Netbox host port is not set! You may set it with Set-NetboxHostPort -Port 'https'"
    }

    $script:NetboxConfig.HostPort
}

#endregion

#region File Get-NetboxHostScheme.ps1

function Get-NetboxHostScheme {
    [CmdletBinding()]
    param ()

    Write-Verbose "Getting Netbox host scheme"
    if ($null -eq $script:NetboxConfig.Hostscheme) {
        throw "Netbox host sceme is not set! You may set it with Set-NetboxHostScheme -Scheme 'https'"
    }

    $script:NetboxConfig.HostScheme
}

#endregion

#region File Get-NetboxInvokeParams.ps1

function Get-NetboxInvokeParams {
    [CmdletBinding()]
    param ()

    Write-Verbose "Getting Netbox InvokeParams"
    if ($null -eq $script:NetboxConfig.InvokeParams) {
        throw "Netbox Invoke Params is not set! You may set it with Set-NetboxInvokeParams -InvokeParams ..."
    }

    $script:NetboxConfig.InvokeParams
}

#endregion

#region File Get-NetboxIPAMAddress.ps1

function Get-NetboxIPAMAddress {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param
    (
        [Parameter(ParameterSetName = 'Query',
            Position = 0)]
        [string]$Address,

        [Parameter(ParameterSetName = 'ByID')]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [object]$Family,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Parent,

        [Parameter(ParameterSetName = 'Query')]
        [byte]$Mask_Length,

        [Parameter(ParameterSetName = 'Query')]
        [string]$VRF,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$VRF_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Tenant,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Device,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Device_ID,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Virtual_Machine,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Virtual_Machine_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Interface_Id,

        [Parameter(ParameterSetName = 'Query')]
        [object]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [object]$Role,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($IP_ID in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-addresses', $IP_ID))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id'

                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $uri -Raw:$Raw
            }

            break
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-addresses'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

            $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $uri -Raw:$Raw

            break
        }
    }
}

#endregion

#region File Get-NetboxIPAMAddressRange.ps1


function Get-NetboxIPAMAddressRange {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param
    (
        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [string]$Range,

        [Parameter(ParameterSetName = 'ByID')]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [object]$Family,

        [Parameter(ParameterSetName = 'Query')]
        [string]$VRF,

        [Parameter(ParameterSetName = 'Query')]
        [uint32]$VRF_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Tenant,

        [Parameter(ParameterSetName = 'Query')]
        [uint32]$Tenant_Id,

        [Parameter(ParameterSetName = 'Query')]
        [object]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [object]$Role,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($Range_ID in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-ranges', $Range_ID))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id'

                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $uri -Raw:$Raw
            }

            break
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-ranges'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

            $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $uri -Raw:$Raw

            break
        }
    }
}

#endregion

#region File Get-NetboxIPAMAggregate.ps1


function Get-NetboxIPAMAggregate {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param
    (
        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'ByID')]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Prefix,

        [Parameter(ParameterSetName = 'Query')]
        [object]$Family,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$RIR_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$RIR,

        [Parameter(ParameterSetName = 'Query')]
        [datetime]$Date_Added,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

#    if ($null -ne $Family) {
#        $PSBoundParameters.Family = ValidateIPAMChoice -ProvidedValue $Family -AggregateFamily
    #    }

    switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($IP_ID in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'aggregates', $IP_ID))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id'

                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $uri -Raw:$Raw
            }
            break
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'aggregates'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

            $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $uri -Raw:$Raw

            break
        }
    }
}

#endregion

#region File Get-NetboxIPAMASN.ps1

function Get-NetboxIPAMASN {
<#
    .SYNOPSIS
        Get ASNs from Netbox

    .DESCRIPTION
        Retrieves ASN (Autonomous System Number) objects from Netbox with optional filtering.

    .PARAMETER Id
        The ID of the ASN to retrieve

    .PARAMETER ASN
        Filter by ASN number

    .PARAMETER Query
        A general search query

    .PARAMETER RIR_Id
        Filter by RIR ID

    .PARAMETER Tenant_Id
        Filter by tenant ID

    .PARAMETER Site_Id
        Filter by site ID

    .PARAMETER Limit
        Limit the number of results

    .PARAMETER Offset
        Offset for pagination

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Get-NetboxIPAMASN

        Returns all ASNs

    .EXAMPLE
        Get-NetboxIPAMASN -ASN 65001

        Returns ASN 65001
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ParameterSetName = 'ByID',
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$ASN,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$RIR_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Site_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($ASNId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('ipam', 'asns', $ASNId))

                    $URI = BuildNewURI -Segments $Segments

                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'asns'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NetboxIPAMASNRange.ps1

function Get-NetboxIPAMASNRange {
<#
    .SYNOPSIS
        Get ASN ranges from Netbox

    .DESCRIPTION
        Retrieves ASN range objects from Netbox with optional filtering.

    .PARAMETER Id
        The ID of the ASN range to retrieve

    .PARAMETER Name
        Filter by name

    .PARAMETER Query
        A general search query

    .PARAMETER RIR_Id
        Filter by RIR ID

    .PARAMETER Tenant_Id
        Filter by tenant ID

    .PARAMETER Limit
        Limit the number of results

    .PARAMETER Offset
        Offset for pagination

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Get-NetboxIPAMASNRange

        Returns all ASN ranges

    .EXAMPLE
        Get-NetboxIPAMASNRange -Name "Private"

        Returns ASN ranges matching the name "Private"
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ParameterSetName = 'ByID',
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$RIR_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($RangeId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('ipam', 'asn-ranges', $RangeId))

                    $URI = BuildNewURI -Segments $Segments

                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'asn-ranges'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NetboxIPAMAvailableIP.ps1


function Get-NetboxIPAMAvailableIP {
    <#
    .SYNOPSIS
        A convenience method for returning available IP addresses within a prefix

    .DESCRIPTION
        By default, the number of IPs returned will be equivalent to PAGINATE_COUNT. An arbitrary limit
        (up to MAX_PAGE_SIZE, if set) may be passed, however results will not be paginated

    .PARAMETER Prefix_ID
        A description of the Prefix_ID parameter.

    .PARAMETER Limit
        A description of the Limit parameter.

    .PARAMETER Raw
        A description of the Raw parameter.

    .PARAMETER NumberOfIPs
        A description of the NumberOfIPs parameter.

    .EXAMPLE
        Get-NetboxIPAMAvailableIP -Prefix_ID (Get-NetboxIPAMPrefix -Prefix 192.0.2.0/24).id

        Get (Next) Available IP on the Prefix 192.0.2.0/24

    .EXAMPLE
        Get-NetboxIPAMAvailableIP -Prefix_ID 2 -NumberOfIPs 3

        Get 3 (Next) Available IP on the Prefix 192.0.2.0/24

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Id')]
        [uint64]$Prefix_ID,

        [Alias('NumberOfIPs')]
        [uint64]$Limit,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'prefixes', $Prefix_ID, 'available-ips'))

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'prefix_id'

        $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $uri -Raw:$Raw
    }
}

#endregion

#region File Get-NetboxIPAMPrefix.ps1


function Get-NetboxIPAMPrefix {
<#
    .SYNOPSIS
        A brief description of the Get-NetboxIPAMPrefix function.

    .DESCRIPTION
        A detailed description of the Get-NetboxIPAMPrefix function.

    .PARAMETER Query
        A description of the Query parameter.

    .PARAMETER Id
        A description of the Id parameter.

    .PARAMETER Limit
        A description of the Limit parameter.

    .PARAMETER Offset
        A description of the Offset parameter.

    .PARAMETER Family
        A description of the Family parameter.

    .PARAMETER Is_Pool
        A description of the Is_Pool parameter.

    .PARAMETER Within
        Should be a CIDR notation prefix such as '10.0.0.0/16'

    .PARAMETER Within_Include
        Should be a CIDR notation prefix such as '10.0.0.0/16'

    .PARAMETER Contains
        A description of the Contains parameter.

    .PARAMETER Mask_Length
        CIDR mask length value

    .PARAMETER VRF
        A description of the VRF parameter.

    .PARAMETER VRF_Id
        A description of the VRF_Id parameter.

    .PARAMETER Tenant
        A description of the Tenant parameter.

    .PARAMETER Tenant_Id
        A description of the Tenant_Id parameter.

    .PARAMETER Site
        A description of the Site parameter.

    .PARAMETER Site_Id
        A description of the Site_Id parameter.

    .PARAMETER Vlan_VId
        A description of the Vlan_VId parameter.

    .PARAMETER Vlan_Id
        A description of the Vlan_Id parameter.

    .PARAMETER Status
        A description of the Status parameter.

    .PARAMETER Role
        A description of the Role parameter.

    .PARAMETER Role_Id
        A description of the Role_Id parameter.

    .PARAMETER Raw
        A description of the Raw parameter.

    .EXAMPLE
        PS C:\> Get-NetboxIPAMPrefix

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param
    (
        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [string]$Prefix,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'ByID')]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [object]$Family,

        [Parameter(ParameterSetName = 'Query')]
        [boolean]$Is_Pool,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Within,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Within_Include,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Contains,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateRange(0, 127)]
        [byte]$Mask_Length,

        [Parameter(ParameterSetName = 'Query')]
        [string]$VRF,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$VRF_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Tenant,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Site,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Site_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Vlan_VId,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Vlan_Id,

        [Parameter(ParameterSetName = 'Query')]
        [object]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Role,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Role_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    #    if ($null -ne $Family) {
    #        $PSBoundParameters.Family = ValidateIPAMChoice -ProvidedValue $Family -PrefixFamily
    #    }
    #
    #    if ($null -ne $Status) {
    #        $PSBoundParameters.Status = ValidateIPAMChoice -ProvidedValue $Status -PrefixStatus
    #    }

    switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($Prefix_ID in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'prefixes', $Prefix_ID))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id'

                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $uri -Raw:$Raw
            }

            break
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'prefixes'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

            $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $uri -Raw:$Raw

            break
        }
    }
}

#endregion

#region File Get-NetboxIPAMRole.ps1


function Get-NetboxIPAMRole {
<#
    .SYNOPSIS
        Get IPAM Prefix/VLAN roles

    .DESCRIPTION
        A role indicates the function of a prefix or VLAN. For example, you might define Data, Voice, and Security roles. Generally, a prefix will be assigned the same functional role as the VLAN to which it is assigned (if any).

    .PARAMETER Id
        Unique ID

    .PARAMETER Query
        Search query

    .PARAMETER Name
        Role name

    .PARAMETER Slug
        Role URL slug

    .PARAMETER Brief
        Brief format

    .PARAMETER Limit
        Result limit

    .PARAMETER Offset
        Result offset

    .PARAMETER Raw
        A description of the Raw parameter.

    .EXAMPLE
        PS C:\> Get-NetboxIPAMRole

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding()]
    param
    (
        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'ByID')]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [switch]$Brief,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($Role_ID in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'roles', $Role_ID))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id'

                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $uri -Raw:$Raw
            }

            break
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'roles'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

            $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $uri -Raw:$Raw

            break
        }
    }
}

#endregion

#region File Get-NetboxIPAMRouteTarget.ps1

function Get-NetboxIPAMRouteTarget {
<#
    .SYNOPSIS
        Get route targets from Netbox

    .DESCRIPTION
        Retrieves route target objects from Netbox with optional filtering.
        Route targets are used for VRF import/export policies.

    .PARAMETER Id
        The ID of the route target to retrieve

    .PARAMETER Name
        Filter by route target name (RFC 4360 format)

    .PARAMETER Query
        A general search query

    .PARAMETER Tenant_Id
        Filter by tenant ID

    .PARAMETER Tenant
        Filter by tenant name

    .PARAMETER Importing_VRF_Id
        Filter by VRF ID that imports this target

    .PARAMETER Exporting_VRF_Id
        Filter by VRF ID that exports this target

    .PARAMETER Limit
        Limit the number of results

    .PARAMETER Offset
        Offset for pagination

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Get-NetboxIPAMRouteTarget

        Returns all route targets

    .EXAMPLE
        Get-NetboxIPAMRouteTarget -Name "65001:100"

        Returns route targets matching the specified value
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ParameterSetName = 'ByID',
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Tenant,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Importing_VRF_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Exporting_VRF_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($RTId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('ipam', 'route-targets', $RTId))

                    $URI = BuildNewURI -Segments $Segments

                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'route-targets'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NetboxIPAMService.ps1

function Get-NetboxIPAMService {
<#
    .SYNOPSIS
        Get services from Netbox

    .DESCRIPTION
        Retrieves service objects from Netbox with optional filtering.
        Services represent network services running on devices or virtual machines.

    .PARAMETER Id
        The ID of the service to retrieve

    .PARAMETER Name
        Filter by service name

    .PARAMETER Query
        A general search query

    .PARAMETER Protocol
        Filter by protocol (tcp, udp, sctp)

    .PARAMETER Port
        Filter by port number

    .PARAMETER Device_Id
        Filter by device ID

    .PARAMETER Virtual_Machine_Id
        Filter by virtual machine ID

    .PARAMETER Limit
        Limit the number of results

    .PARAMETER Offset
        Offset for pagination

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Get-NetboxIPAMService

        Returns all services

    .EXAMPLE
        Get-NetboxIPAMService -Protocol tcp -Port 443

        Returns TCP services on port 443
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ParameterSetName = 'ByID',
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('tcp', 'udp', 'sctp')]
        [string]$Protocol,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Port,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Device_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Virtual_Machine_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($ServiceId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('ipam', 'services', $ServiceId))

                    $URI = BuildNewURI -Segments $Segments

                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'services'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NetboxIPAMServiceTemplate.ps1

function Get-NetboxIPAMServiceTemplate {
<#
    .SYNOPSIS
        Get service templates from Netbox

    .DESCRIPTION
        Retrieves service template objects from Netbox with optional filtering.
        Service templates are reusable definitions for creating services.

    .PARAMETER Id
        The ID of the service template to retrieve

    .PARAMETER Name
        Filter by template name

    .PARAMETER Query
        A general search query

    .PARAMETER Protocol
        Filter by protocol (tcp, udp, sctp)

    .PARAMETER Port
        Filter by port number

    .PARAMETER Limit
        Limit the number of results

    .PARAMETER Offset
        Offset for pagination

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Get-NetboxIPAMServiceTemplate

        Returns all service templates

    .EXAMPLE
        Get-NetboxIPAMServiceTemplate -Name "HTTP"

        Returns service templates matching the name "HTTP"
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ParameterSetName = 'ByID',
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('tcp', 'udp', 'sctp')]
        [string]$Protocol,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Port,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($TemplateId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('ipam', 'service-templates', $TemplateId))

                    $URI = BuildNewURI -Segments $Segments

                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'service-templates'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NetboxIPAMVLAN.ps1


function Get-NetboxIPAMVLAN {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param
    (
        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [ValidateRange(1, 4096)]
        [uint16]$VID,

        [Parameter(ParameterSetName = 'ByID')]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Tenant,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$TenantGroup,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$TenantGroup_Id,

        [Parameter(ParameterSetName = 'Query')]
        [object]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Region,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Site,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Site_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Group,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Group_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Role,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Role_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($VLAN_ID in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'vlans', $VLAN_ID))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id'

                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $uri -Raw:$Raw
            }

            break
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'vlans'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

            $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $uri -Raw:$Raw

            break
        }
    }
}





#endregion

#region File Get-NetboxIPAMVRF.ps1

function Get-NetboxIPAMVRF {
<#
    .SYNOPSIS
        Get VRFs from Netbox

    .DESCRIPTION
        Retrieves VRF (Virtual Routing and Forwarding) objects from Netbox with optional filtering.

    .PARAMETER Id
        The ID of the VRF to retrieve

    .PARAMETER Name
        Filter by VRF name

    .PARAMETER Query
        A general search query

    .PARAMETER RD
        Filter by route distinguisher

    .PARAMETER Tenant_Id
        Filter by tenant ID

    .PARAMETER Tenant
        Filter by tenant name

    .PARAMETER Enforce_Unique
        Filter by enforce unique flag

    .PARAMETER Limit
        Limit the number of results

    .PARAMETER Offset
        Offset for pagination

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Get-NetboxIPAMVRF

        Returns all VRFs

    .EXAMPLE
        Get-NetboxIPAMVRF -Name "Production"

        Returns VRFs matching the name "Production"

    .EXAMPLE
        Get-NetboxIPAMVRF -RD "65001:100"

        Returns VRFs with the specified route distinguisher
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ParameterSetName = 'ByID',
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [string]$RD,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Tenant,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Enforce_Unique,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($VRFId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('ipam', 'vrfs', $VRFId))

                    $URI = BuildNewURI -Segments $Segments

                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'vrfs'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NetboxTag.ps1


function Get-NetboxTag {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [uint16]$Limit,

        [uint16]$Offset,

        [switch]$Raw
    )

    process {

        $Segments = [System.Collections.ArrayList]::new(@('extras', 'tags'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $URI -Raw:$Raw
    }
}

#endregion

#region File Get-NetboxTenant.ps1


function Get-NetboxTenant {
<#
    .SYNOPSIS
        Get a tenent from Netbox

    .DESCRIPTION
        A detailed description of the Get-NetboxTenant function.

    .PARAMETER Name
        The specific name of the tenant. Must match exactly as is defined in Netbox

    .PARAMETER Id
        The database ID of the tenant

    .PARAMETER Query
        A standard search query that will match one or more tenants.

    .PARAMETER Slug
        The specific slug of the tenant. Must match exactly as is defined in Netbox

    .PARAMETER Group
        The specific group as defined in Netbox.

    .PARAMETER GroupID
        The database ID of the group in Netbox

    .PARAMETER CustomFields
        Hashtable in the format @{"field_name" = "value"} to search

    .PARAMETER Limit
        Limit the number of results to this number

    .PARAMETER Offset
        Start the search at this index in results

    .PARAMETER Raw
        Return the unparsed data from the HTTP request

    .EXAMPLE
        PS C:\> Get-NetboxTenant

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param
    (
        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [string]$Name,

        [Parameter(ParameterSetName = 'ByID')]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Group,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$GroupID,

        [Parameter(ParameterSetName = 'Query')]
        [hashtable]$CustomFields,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($Tenant_ID in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'tenants', $Tenant_ID))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id'

                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $uri -Raw:$Raw
            }

            break
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'tenants'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

            $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $uri -Raw:$Raw

            break
        }
    }
}

#endregion

#region File Get-NetboxTimeout.ps1


function Get-NetboxTimeout {
    [CmdletBinding()]
    [OutputType([uint16])]
    param ()

    Write-Verbose "Getting Netbox Timeout"
    if ($null -eq $script:NetboxConfig.Timeout) {
        throw "Netbox Timeout is not set! You may set it with Set-NetboxTimeout -TimeoutSeconds [uint16]"
    }

    $script:NetboxConfig.Timeout
}

#endregion

#region File Get-NetboxVersion.ps1


function Get-NetboxVersion {
    [CmdletBinding()]
    param ()

    $Segments = [System.Collections.ArrayList]::new(@('status'))

    $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary @{
        'format' = 'json'
    }

    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters -SkipConnectedCheck

    InvokeNetboxRequest -URI $URI
}

#endregion

#region File Get-NetboxVirtualizationCluster.ps1


function Get-NetboxVirtualizationCluster {
<#
    .SYNOPSIS
        Obtains virtualization clusters from Netbox.

    .DESCRIPTION
        Obtains one or more virtualization clusters based on provided filters.

    .PARAMETER Limit
        Number of results to return per page

    .PARAMETER Offset
        The initial index from which to return the results

    .PARAMETER Query
        A general query used to search for a cluster

    .PARAMETER Name
        Name of the cluster

    .PARAMETER Id
        Database ID(s) of the cluster

    .PARAMETER Group
        String value of the cluster group.

    .PARAMETER Group_Id
        Database ID of the cluster group.

    .PARAMETER Type
        String value of the Cluster type.

    .PARAMETER Type_Id
        Database ID of the cluster type.

    .PARAMETER Site
        String value of the site.

    .PARAMETER Site_Id
        Database ID of the site.

    .PARAMETER Raw
        A description of the Raw parameter.

    .EXAMPLE
        PS C:\> Get-NetboxVirtualizationCluster

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding()]
    param
    (
        [string]$Name,

        [Alias('q')]
        [string]$Query,

        [uint64[]]$Id,

        [string]$Group,

        [uint64]$Group_Id,

        [string]$Type,

        [uint64]$Type_Id,

        [string]$Site,

        [uint64]$Site_Id,

        [uint16]$Limit,

        [uint16]$Offset,

        [switch]$Raw
    )

    $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'clusters'))

    $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

    $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

    InvokeNetboxRequest -URI $uri -Raw:$Raw
}

#endregion

#region File Get-NetboxVirtualizationClusterGroup.ps1


function Get-NetboxVirtualizationClusterGroup {
    [CmdletBinding()]
    param
    (
        [string]$Name,

        [string]$Slug,

        [string]$Description,

        [string]$Query,

        [uint64[]]$Id,

        [uint16]$Limit,

        [uint16]$Offset,

        [switch]$Raw
    )

    $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'cluster-groups'))

    $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

    $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

    InvokeNetboxRequest -URI $uri -Raw:$Raw
}

#endregion

#region File Get-NetboxVirtualMachine.ps1


function Get-NetboxVirtualMachine {
    <#
    .SYNOPSIS
        Obtains virtual machines from Netbox.

    .DESCRIPTION
        Obtains one or more virtual machines based on provided filters.

    .PARAMETER Limit
        Number of results to return per page

    .PARAMETER Offset
        The initial index from which to return the results

    .PARAMETER Query
        A general query used to search for a VM

    .PARAMETER Name
        Name of the VM

    .PARAMETER Id
        Database ID of the VM

    .PARAMETER Status
        Status of the VM

    .PARAMETER Tenant
        String value of tenant

    .PARAMETER Tenant_ID
        Database ID of the tenant.

    .PARAMETER Platform
        String value of the platform

    .PARAMETER Platform_ID
        Database ID of the platform

    .PARAMETER Cluster_Group
        String value of the cluster group.

    .PARAMETER Cluster_Group_Id
        Database ID of the cluster group.

    .PARAMETER Cluster_Type
        String value of the Cluster type.

    .PARAMETER Cluster_Type_Id
        Database ID of the cluster type.

    .PARAMETER Cluster_Id
        Database ID of the cluster.

    .PARAMETER Site
        String value of the site.

    .PARAMETER Site_Id
        Database ID of the site.

    .PARAMETER Role
        String value of the role.

    .PARAMETER Role_Id
        Database ID of the role.

    .PARAMETER Raw
        A description of the Raw parameter.

    .PARAMETER TenantID
        Database ID of tenant

    .PARAMETER PlatformID
        Database ID of the platform

    .PARAMETER id__in
        Database IDs of VMs

    .EXAMPLE
        PS C:\> Get-NetboxVirtualMachine

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding()]
    param
    (
        [Alias('q')]
        [string]$Query,

        [string]$Name,

        [uint64[]]$Id,

        [object]$Status,

        [string]$Tenant,

        [uint64]$Tenant_ID,

        [string]$Platform,

        [uint64]$Platform_ID,

        [string]$Cluster_Group,

        [uint64]$Cluster_Group_Id,

        [string]$Cluster_Type,

        [uint64]$Cluster_Type_Id,

        [uint64]$Cluster_Id,

        [string]$Site,

        [uint64]$Site_Id,

        [string]$Role,

        [uint64]$Role_Id,

        [uint16]$Limit,

        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        if ($null -ne $Status) {
            $PSBoundParameters.Status = ValidateVirtualizationChoice -ProvidedValue $Status -VirtualMachineStatus
        }

        $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'virtual-machines'))

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

        $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $uri -Raw:$Raw
    }
}

#endregion

#region File Get-NetboxVirtualMachineInterface.ps1


function Get-NetboxVirtualMachineInterface {
    <#
    .SYNOPSIS
        Gets VM interfaces

    .DESCRIPTION
        Obtains the interface objects for one or more VMs

    .PARAMETER Limit
        Number of results to return per page.

    .PARAMETER Offset
        The initial index from which to return the results.

    .PARAMETER Id
        Database ID of the interface

    .PARAMETER Name
        Name of the interface

    .PARAMETER Enabled
        True/False if the interface is enabled

    .PARAMETER MTU
        Maximum Transmission Unit size. Generally 1500 or 9000

    .PARAMETER Virtual_Machine_Id
        ID of the virtual machine to which the interface(s) are assigned.

    .PARAMETER Virtual_Machine
        Name of the virtual machine to get interfaces

    .PARAMETER MAC_Address
        MAC address assigned to the interface

    .PARAMETER Raw
        A description of the Raw parameter.

    .EXAMPLE
        PS C:\> Get-NetboxVirtualMachineInterface

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Query,

        [boolean]$Enabled,

        [uint16]$MTU,

        [uint64]$Virtual_Machine_Id,

        [string]$Virtual_Machine,

        [string]$MAC_Address,

        [uint16]$Limit,

        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'interfaces'))

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

        $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $uri -Raw:$Raw
    }
}

#endregion

#region File Get-NetboxVPNIKEPolicy.ps1

function Get-NetboxVPNIKEPolicy {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,[Parameter(ParameterSetName = 'Query')][uint16]$Limit,[Parameter(ParameterSetName = 'Query')][uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ike-policies',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('vpn','ike-policies')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}

#endregion

#region File Get-NetboxVPNIKEProposal.ps1

function Get-NetboxVPNIKEProposal {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,[Parameter(ParameterSetName = 'Query')][uint16]$Limit,[Parameter(ParameterSetName = 'Query')][uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ike-proposals',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('vpn','ike-proposals')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}

#endregion

#region File Get-NetboxVPNIPSecPolicy.ps1

function Get-NetboxVPNIPSecPolicy {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,[Parameter(ParameterSetName = 'Query')][uint16]$Limit,[Parameter(ParameterSetName = 'Query')][uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ipsec-policies',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-policies')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}

#endregion

#region File Get-NetboxVPNIPSecProfile.ps1

function Get-NetboxVPNIPSecProfile {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,[Parameter(ParameterSetName = 'Query')][uint16]$Limit,[Parameter(ParameterSetName = 'Query')][uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ipsec-profiles',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-profiles')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}

#endregion

#region File Get-NetboxVPNIPSecProposal.ps1

function Get-NetboxVPNIPSecProposal {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,[Parameter(ParameterSetName = 'Query')][uint16]$Limit,[Parameter(ParameterSetName = 'Query')][uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ipsec-proposals',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-proposals')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}

#endregion

#region File Get-NetboxVPNL2VPN.ps1

function Get-NetboxVPNL2VPN {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,[Parameter(ParameterSetName = 'Query')][string]$Slug,
        [Parameter(ParameterSetName = 'Query')][string]$Type,[Parameter(ParameterSetName = 'Query')][uint64]$Tenant_Id,
        [Parameter(ParameterSetName = 'Query')][uint16]$Limit,[Parameter(ParameterSetName = 'Query')][uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','l2vpns',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('vpn','l2vpns')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}

#endregion

#region File Get-NetboxVPNL2VPNTermination.ps1

function Get-NetboxVPNL2VPNTermination {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$L2VPN_Id,[Parameter(ParameterSetName = 'Query')][uint16]$Limit,[Parameter(ParameterSetName = 'Query')][uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','l2vpn-terminations',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('vpn','l2vpn-terminations')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}

#endregion

#region File Get-NetboxVPNTunnel.ps1

function Get-NetboxVPNTunnel {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [Parameter(ParameterSetName = 'Query')][string]$Status,
        [Parameter(ParameterSetName = 'Query')][uint64]$Group_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Encapsulation,
        [Parameter(ParameterSetName = 'Query')][uint16]$Limit,
        [Parameter(ParameterSetName = 'Query')][uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($TunnelId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('vpn', 'tunnels', $TunnelId))
                    $URI = BuildNewURI -Segments $Segments
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('vpn', 'tunnels'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NetboxVPNTunnelGroup.ps1

function Get-NetboxVPNTunnelGroup {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,[Parameter(ParameterSetName = 'Query')][string]$Slug,
        [Parameter(ParameterSetName = 'Query')][uint16]$Limit,[Parameter(ParameterSetName = 'Query')][uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','tunnel-groups',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('vpn','tunnel-groups')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}

#endregion

#region File Get-NetboxVPNTunnelTermination.ps1

function Get-NetboxVPNTunnelTermination {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Tunnel_Id,[Parameter(ParameterSetName = 'Query')][string]$Role,
        [Parameter(ParameterSetName = 'Query')][uint16]$Limit,[Parameter(ParameterSetName = 'Query')][uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','tunnel-terminations',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('vpn','tunnel-terminations')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}

#endregion

#region File Get-NetboxWirelessLAN.ps1

function Get-NetboxWirelessLAN {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$SSID,[Parameter(ParameterSetName = 'Query')][uint64]$Group_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Status,[Parameter(ParameterSetName = 'Query')][uint64]$VLAN_Id,
        [Parameter(ParameterSetName = 'Query')][uint16]$Limit,[Parameter(ParameterSetName = 'Query')][uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('wireless','wireless-lans',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('wireless','wireless-lans')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}

#endregion

#region File Get-NetboxWirelessLANGroup.ps1

function Get-NetboxWirelessLANGroup {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,[Parameter(ParameterSetName = 'Query')][string]$Slug,
        [Parameter(ParameterSetName = 'Query')][uint64]$Parent_Id,[Parameter(ParameterSetName = 'Query')][uint16]$Limit,[Parameter(ParameterSetName = 'Query')][uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('wireless','wireless-lan-groups',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('wireless','wireless-lan-groups')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}

#endregion

#region File Get-NetboxWirelessLink.ps1

function Get-NetboxWirelessLink {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$SSID,[Parameter(ParameterSetName = 'Query')][string]$Status,
        [Parameter(ParameterSetName = 'Query')][uint16]$Limit,[Parameter(ParameterSetName = 'Query')][uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('wireless','wireless-links',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('wireless','wireless-links')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}

#endregion

#region File GetNetboxAPIErrorBody.ps1


function GetNetboxAPIErrorBody {
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Net.HttpWebResponse]$Response
    )

    # This takes the $Response stream and turns it into a useable object... generally a string.
    # If the body is JSON, you should be able to use ConvertFrom-Json

    $reader = New-Object System.IO.StreamReader($Response.GetResponseStream())
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $reader.ReadToEnd()
}

#endregion

#region File GetNetboxConfigVariable.ps1

function GetNetboxConfigVariable {
    return $script:NetboxConfig
}

#endregion

#region File InvokeNetboxRequest.ps1


function InvokeNetboxRequest {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.UriBuilder]$URI,

        [Hashtable]$Headers = @{
        },

        [pscustomobject]$Body = $null,

        [ValidateRange(1, 65535)]
        [uint16]$Timeout = (Get-NetboxTimeout),

        [ValidateSet('GET', 'PATCH', 'PUT', 'POST', 'DELETE', 'OPTIONS', IgnoreCase = $true)]
        [string]$Method = 'GET',

        [switch]$Raw
    )

    $creds = Get-NetboxCredential

    $Headers.Authorization = "Token {0}" -f $creds.GetNetworkCredential().Password

    $splat = @{
        'Method'      = $Method
        'Uri'         = $URI.Uri.AbsoluteUri # This property auto generates the scheme, hostname, path, and query
        'Headers'     = $Headers
        'TimeoutSec'  = $Timeout
        'ContentType' = 'application/json'
        'ErrorAction' = 'Stop'
        'Verbose'     = $VerbosePreference
    }

    $splat += Get-NetboxInvokeParams

    if ($Body) {
        Write-Verbose "BODY: $($Body | ConvertTo-Json -Compress)"
        $null = $splat.Add('Body', ($Body | ConvertTo-Json -Compress))
    }

    $result = Invoke-RestMethod @splat

    #region TODO: Handle errors a little more gracefully...

    <#
    try {
        Write-Verbose "Sending request..."
        $result = Invoke-RestMethod @splat
        Write-Verbose $result
    } catch {
        Write-Verbose "Caught exception"
        if ($_.Exception.psobject.properties.Name.contains('Response')) {
            Write-Verbose "Exception contains a response property"
            if ($Raw) {
                Write-Verbose "RAW provided...throwing raw exception"
                throw $_
            }

            Write-Verbose "Converting response to object"
            $myError = GetNetboxAPIErrorBody -Response $_.Exception.Response | ConvertFrom-Json
        } else {
            Write-Verbose "No response property found"
            $myError = $_
        }
    }

    Write-Verbose "MyError is $($myError.GetType().FullName)"

    if ($myError -is [Exception]) {
        throw $_
    } elseif ($myError -is [pscustomobject]) {
        throw $myError.detail
    }
    #>

    #endregion TODO: Handle errors a little more gracefully...

    # If the user wants the raw value from the API... otherwise return only the actual result
    if ($Raw) {
        Write-Verbose "Returning raw result by choice"
        return $result
    } else {
        if ($result.psobject.Properties.Name.Contains('results')) {
            Write-Verbose "Found Results property on data, returning results directly"
            return $result.Results
        } else {
            Write-Verbose "Did NOT find results property on data, returning raw result"
            return $result
        }
    }
}

#endregion

#region File New-NetboxCircuit.ps1


function New-NetboxCircuit {
    [CmdletBinding(ConfirmImpact = 'Low',
        SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$CID,

        [Parameter(Mandatory = $true)]
        [uint64]$Provider,

        [Parameter(Mandatory = $true)]
        [uint64]$Type,

        #[ValidateSet('Active', 'Planned', 'Provisioning', 'Offline', 'Deprovisioning', 'Decommissioned ')]
        [uint16]$Status = 'Active',

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
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuits'))
        $Method = 'POST'

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($Force -or $PSCmdlet.ShouldProcess($CID, 'Create new circuit')) {
            InvokeNetboxRequest -URI $URI -Method $Method -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NetboxContact.ps1


function New-NetboxContact {
<#
    .SYNOPSIS
        Create a new contact in Netbox

    .DESCRIPTION
        Creates a new contact object in Netbox which can be linked to other objects

    .PARAMETER Name
        The contacts full name, e.g "Leroy Jenkins"

    .PARAMETER Email
        Email address of the contact

    .PARAMETER Title
        Job title or other title related to the contact

    .PARAMETER Phone
        Telephone number

    .PARAMETER Address
        Physical address, usually mailing address

    .PARAMETER Description
        Short description of the contact

    .PARAMETER Comments
        Detailed comments. Markdown supported.

    .PARAMETER Link
        URI related to the contact

    .PARAMETER Custom_Fields
        A description of the Custom_Fields parameter.

    .PARAMETER Raw
        A description of the Raw parameter.

    .EXAMPLE
        PS C:\> New-NetboxContact -Name 'Leroy Jenkins' -Email 'leroy.jenkins@example.com'

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(ConfirmImpact = 'Low',
                   SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateLength(1, 100)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateLength(0, 254)]
        [string]$Email,

        [ValidateLength(0, 100)]
        [string]$Title,

        [ValidateLength(0, 50)]
        [string]$Phone,

        [ValidateLength(0, 200)]
        [string]$Address,

        [ValidateLength(0, 200)]
        [string]$Description,

        [string]$Comments,

        [ValidateLength(0, 200)]
        [string]$Link,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contacts'))
        $Method = 'POST'

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new contact')) {
            InvokeNetboxRequest -URI $URI -Method $Method -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}





#endregion

#region File New-NetboxContactAssignment.ps1


function New-NetboxContactAssignment {
<#
    .SYNOPSIS
        Create a new contact role assignment in Netbox

    .DESCRIPTION
        Creates a new contact role assignment in Netbox

    .PARAMETER Content_Type
        The content type for this assignment.

    .PARAMETER Object_Id
        ID of the object to assign.

    .PARAMETER Contact
        ID of the contact to assign.

    .PARAMETER Role
        ID of the contact role to assign.

    .PARAMETER Priority
        Piority of the contact assignment.

    .PARAMETER Raw
        Return the unparsed data from the HTTP request

    .EXAMPLE
        PS C:\> New-NetboxContactAssignment -Content_Type 'dcim.location' -Object_id 10 -Contact 15 -Role 10 -Priority 'Primary'

    .NOTES
        Valid content types: https://docs.netbox.dev/en/stable/features/contacts/#contacts_1
#>

    [CmdletBinding(ConfirmImpact = 'Low',
                   SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('circuits.circuit', 'circuits.provider', 'circuits.provideraccount', 'dcim.device', 'dcim.location', 'dcim.manufacturer', 'dcim.powerpanel', 'dcim.rack', 'dcim.region', 'dcim.site', 'dcim.sitegroup', 'tenancy.tenant', 'virtualization.cluster', 'virtualization.clustergroup', 'virtualization.virtualmachine', IgnoreCase = $true)]
        [string]$Content_Type,

        [Parameter(Mandatory = $true)]
        [uint64]$Object_Id,

        [Parameter(Mandatory = $true)]
        [uint64]$Contact,

        [Parameter(Mandatory = $true)]
        [uint64]$Role,

        [ValidateSet('primary', 'secondary', 'tertiary', 'inactive', IgnoreCase = $true)]
        [string]$Priority,

        [switch]$Raw
    )

    begin {
        $Method = 'POST'
    }

    process {
        $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contact-assignments'))

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Content_Type, 'Create new contact assignment')) {
            InvokeNetboxRequest -URI $URI -Method $Method -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}





#endregion

#region File New-NetboxContactRole.ps1


function New-NetboxContactRole {
<#
    .SYNOPSIS
        Create a new contact role in Netbox

    .DESCRIPTION
        Creates a new contact role object in Netbox

    .PARAMETER Name
        The contact role name, e.g "Network Support"

    .PARAMETER Slug
        The unique URL for the role. Can only contain hypens, A-Z, a-z, 0-9, and underscores

    .PARAMETER Description
        Short description of the contact role

    .PARAMETER Custom_Fields
        A description of the Custom_Fields parameter.

    .PARAMETER Raw
        Return the unparsed data from the HTTP request

    .EXAMPLE
        PS C:\> New-NetboxContact -Name 'Leroy Jenkins' -Email 'leroy.jenkins@example.com'

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(ConfirmImpact = 'Low',
                   SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateLength(1, 100)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 100)]
        [ValidatePattern('^[-a-zA-Z0-9_]+$')]
        [string]$Slug,

        [ValidateLength(0, 200)]
        [string]$Description,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contacts'))
        $Method = 'POST'

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new contact')) {
            InvokeNetboxRequest -URI $URI -Method $Method -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}





#endregion

#region File New-NetboxDCIMDevice.ps1


function New-NetboxDCIMDevice {
    [CmdletBinding(ConfirmImpact = 'low',
        SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    #region Parameters
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [object]$Device_Role,

        [Parameter(Mandatory = $true)]
        [object]$Device_Type,

        [Parameter(Mandatory = $true)]
        [uint64]$Site,

        [object]$Status = 'Active',

        [uint64]$Platform,

        [uint64]$Tenant,

        [uint64]$Cluster,

        [uint64]$Rack,

        [uint16]$Position,

        [object]$Face,

        [string]$Serial,

        [string]$Asset_Tag,

        [uint64]$Virtual_Chassis,

        [uint64]$VC_Priority,

        [uint64]$VC_Position,

        [uint64]$Primary_IP4,

        [uint64]$Primary_IP6,

        [string]$Comments,

        [hashtable]$Custom_Fields
    )
    #endregion Parameters

    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'devices'))

    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

    $URI = BuildNewURI -Segments $URIComponents.Segments

    if ($PSCmdlet.ShouldProcess($Name, 'Create new Device')) {
        InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method POST
    }
}

#endregion

#region File New-NetboxDCIMLocation.ps1

function New-NetboxDCIMLocation {
<#
    .SYNOPSIS
        Create a new location in Netbox

    .DESCRIPTION
        Creates a new location object in Netbox.
        Locations represent physical areas within a site (e.g., floors, rooms, cages).

    .PARAMETER Name
        The name of the location (required)

    .PARAMETER Slug
        The URL-friendly slug (required)

    .PARAMETER Site
        The site ID where the location exists (required)

    .PARAMETER Parent
        The parent location ID for nested locations

    .PARAMETER Status
        The operational status (planned, staging, active, decommissioning, retired)

    .PARAMETER Tenant
        The tenant ID that owns this location

    .PARAMETER Facility
        The facility identifier

    .PARAMETER Description
        A description of the location

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        New-NetboxDCIMLocation -Name "Server Room" -Slug "server-room" -Site 1

        Creates a new location named "Server Room" at site 1

    .EXAMPLE
        New-NetboxDCIMLocation -Name "Floor 2" -Slug "floor-2" -Site 1 -Status active

        Creates a new active location at site 1
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Slug,

        [Parameter(Mandatory = $true)]
        [uint64]$Site,

        [uint64]$Parent,

        [ValidateSet('planned', 'staging', 'active', 'decommissioning', 'retired')]
        [string]$Status,

        [uint64]$Tenant,

        [string]$Facility,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'locations'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new location')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NetboxDCIMManufacturer.ps1

function New-NetboxDCIMManufacturer {
<#
    .SYNOPSIS
        Create a new manufacturer in Netbox

    .DESCRIPTION
        Creates a new manufacturer object in Netbox.

    .PARAMETER Name
        The name of the manufacturer (required)

    .PARAMETER Slug
        The URL-friendly slug (required)

    .PARAMETER Description
        A description of the manufacturer

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        New-NetboxDCIMManufacturer -Name "Cisco" -Slug "cisco"

        Creates a new manufacturer named "Cisco"

    .EXAMPLE
        New-NetboxDCIMManufacturer -Name "Dell Technologies" -Slug "dell" -Description "Server and storage manufacturer"

        Creates a new manufacturer with description
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Slug,

        [string]$Description,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'manufacturers'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new manufacturer')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NetboxDCIMRack.ps1

function New-NetboxDCIMRack {
<#
    .SYNOPSIS
        Create a new rack in Netbox

    .DESCRIPTION
        Creates a new rack object in Netbox.

    .PARAMETER Name
        The name of the rack (required)

    .PARAMETER Site
        The site ID where the rack is located (required)

    .PARAMETER Location
        The location ID within the site

    .PARAMETER Tenant
        The tenant ID that owns this rack

    .PARAMETER Status
        The operational status (active, planned, reserved, deprecated)

    .PARAMETER Role
        The rack role ID

    .PARAMETER Serial
        The serial number

    .PARAMETER Asset_Tag
        The asset tag

    .PARAMETER Rack_Type
        The rack type ID

    .PARAMETER Width
        The rack width (10 or 19 inches)

    .PARAMETER U_Height
        The height in rack units (default: 42)

    .PARAMETER Starting_Unit
        The starting unit number (default: 1)

    .PARAMETER Desc_Units
        Whether units are numbered top-to-bottom

    .PARAMETER Outer_Width
        The outer width in millimeters

    .PARAMETER Outer_Depth
        The outer depth in millimeters

    .PARAMETER Outer_Height
        The outer height in millimeters

    .PARAMETER Mounting_Depth
        The mounting depth in millimeters

    .PARAMETER Max_Weight
        The maximum weight capacity

    .PARAMETER Weight_Unit
        The weight unit (kg, g, lb, oz)

    .PARAMETER Facility_Id
        The facility identifier

    .PARAMETER Description
        A description of the rack

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        New-NetboxDCIMRack -Name "Rack-01" -Site 1

        Creates a new rack named "Rack-01" at site 1

    .EXAMPLE
        New-NetboxDCIMRack -Name "Rack-02" -Site 1 -U_Height 48 -Status active

        Creates a 48U active rack at site 1
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [uint64]$Site,

        [uint64]$Location,

        [uint64]$Tenant,

        [ValidateSet('active', 'planned', 'reserved', 'deprecated')]
        [string]$Status,

        [uint64]$Role,

        [string]$Serial,

        [string]$Asset_Tag,

        [uint64]$Rack_Type,

        [ValidateSet(10, 19, 21, 23)]
        [uint16]$Width,

        [ValidateRange(1, 100)]
        [uint16]$U_Height,

        [ValidateRange(1, 100)]
        [uint16]$Starting_Unit,

        [bool]$Desc_Units,

        [uint16]$Outer_Width,

        [uint16]$Outer_Depth,

        [uint16]$Outer_Height,

        [uint16]$Mounting_Depth,

        [uint32]$Max_Weight,

        [ValidateSet('kg', 'g', 'lb', 'oz')]
        [string]$Weight_Unit,

        [string]$Facility_Id,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'racks'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new rack')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NetboxDCIMRegion.ps1

function New-NetboxDCIMRegion {
<#
    .SYNOPSIS
        Create a new region in Netbox

    .DESCRIPTION
        Creates a new region object in Netbox.
        Regions are used to organize sites geographically (e.g., countries, states, cities).

    .PARAMETER Name
        The name of the region (required)

    .PARAMETER Slug
        The URL-friendly slug (required)

    .PARAMETER Parent
        The parent region ID for nested regions

    .PARAMETER Description
        A description of the region

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        New-NetboxDCIMRegion -Name "Europe" -Slug "europe"

        Creates a new region named "Europe"

    .EXAMPLE
        New-NetboxDCIMRegion -Name "Netherlands" -Slug "netherlands" -Parent 1

        Creates a new region as a child of region 1
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Slug,

        [uint64]$Parent,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'regions'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new region')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NetboxDCIMSite.ps1

<#
    .NOTES
    ===========================================================================
     Created with:  SAPIEN Technologies, Inc., PowerShell Studio 2020 v5.7.181
     Created on:    2020-10-02 15:52
     Created by:    Claussen
     Organization:  NEOnet
     Filename:      New-NetboxDCIMSite.ps1
    ===========================================================================
    .DESCRIPTION
        A description of the file.
#>



function New-NetboxDCIMSite {
    <#
    .SYNOPSIS
        Create a new Site to Netbox

    .DESCRIPTION
        Create a new Site to Netbox

    .EXAMPLE
        New-NetboxDCIMSite -name MySite

        Add new Site MySite on Netbox

    #>

    [CmdletBinding(ConfirmImpact = 'Low',
        SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$Slug,

        [string]$Facility,

        [uint64]$ASN,

        [decimal]$Latitude,

        [decimal]$Longitude,

        [string]$Contact_Name,

        [string]$Contact_Phone,

        [string]$Contact_Email,

        [uint64]$Tenant_Group,

        [uint64]$Tenant,

        [string]$Status,

        [uint64]$Region,

        [string]$Description,

        [string]$Comments,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'sites'))
        $Method = 'POST'

        if (-not $PSBoundParameters.ContainsKey('slug')) {
            $PSBoundParameters.Add('slug', $name)
        }

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($name, 'Create new Site')) {
            InvokeNetboxRequest -URI $URI -Method $Method -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NetboxDCIMSiteGroup.ps1

function New-NetboxDCIMSiteGroup {
<#
    .SYNOPSIS
        Create a new site group in Netbox

    .DESCRIPTION
        Creates a new site group object in Netbox.
        Site groups are used to organize sites by functional role (e.g., production, staging, DR).

    .PARAMETER Name
        The name of the site group (required)

    .PARAMETER Slug
        The URL-friendly slug (required)

    .PARAMETER Parent
        The parent site group ID for nested groups

    .PARAMETER Description
        A description of the site group

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        New-NetboxDCIMSiteGroup -Name "Production" -Slug "production"

        Creates a new site group named "Production"

    .EXAMPLE
        New-NetboxDCIMSiteGroup -Name "DR Sites" -Slug "dr-sites" -Parent 1

        Creates a new site group as a child of site group 1
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Slug,

        [uint64]$Parent,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'site-groups'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new site group')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NetboxIPAMAddress.ps1


function New-NetboxIPAMAddress {
    <#
    .SYNOPSIS
        Create a new IP address to Netbox

    .DESCRIPTION
        Create a new IP address to Netbox with a status of Active by default.

    .PARAMETER Address
        IP address in CIDR notation: 192.168.1.1/24

    .PARAMETER Status
        Status of the IP. Defaults to Active

    .PARAMETER Tenant
        Tenant ID

    .PARAMETER VRF
        VRF ID

    .PARAMETER Role
        Role such as anycast, loopback, etc... Defaults to nothing

    .PARAMETER NAT_Inside
        ID of IP for NAT

    .PARAMETER Custom_Fields
        Custom field hash table. Will be validated by the API service

    .PARAMETER Interface
        ID of interface to apply IP

    .PARAMETER Description
        Description of IP address

    .PARAMETER Dns_name
        DNS Name of IP address (example : netbox.example.com)

    .PARAMETER Assigned_Object_Type
        Assigned Object Type dcim.interface or virtualization.vminterface

    .PARAMETER Assigned_Object_Id
        Assigned Object ID

    .PARAMETER Raw
        Return raw results from API service

    .EXAMPLE
        New-NetboxIPAMAddress -Address 192.0.2.1/32

        Add new IP Address 192.0.2.1/32 with status active

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(ConfirmImpact = 'Low',
        SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$Address,

        [object]$Status = 'Active',

        [uint64]$Tenant,

        [uint64]$VRF,

        [object]$Role,

        [uint64]$NAT_Inside,

        [hashtable]$Custom_Fields,

        [uint64]$Interface,

        [string]$Description,

        [string]$Dns_name,

        [ValidateSet('dcim.interface', 'virtualization.vminterface', IgnoreCase = $true)]
        [string]$Assigned_Object_Type,

        [uint64]$Assigned_Object_Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-addresses'))
        $Method = 'POST'

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Address, 'Create new IP address')) {
            InvokeNetboxRequest -URI $URI -Method $Method -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}






#endregion

#region File New-NetboxIPAMAddressRange.ps1



function New-NetboxIPAMAddressRange {
<#
    .SYNOPSIS
        Create a new IP address range to Netbox

    .DESCRIPTION
        Create a new IP address range to Netbox with a status of Active by default. The maximum supported
        size of an IP range is 2^32 - 1.

    .PARAMETER Start_Address
        Starting IPv4 or IPv6 address (with mask). The maximum supported size of an IP range is 2^32 - 1.

    .PARAMETER End_Address
        Ending IPv4 or IPv6 address (with mask). The maximum supported size of an IP range is 2^32 - 1.

    .PARAMETER Status
        Operational status of this range. Defaults to Active

    .PARAMETER Tenant
        Tenant ID

    .PARAMETER VRF
        VRF ID

    .PARAMETER Role
        Role such as backup, customer, development, etc... Defaults to nothing

    .PARAMETER Custom_Fields
        Custom field hash table. Will be validated by the API service

    .PARAMETER Description
        Description of IP address range

    .PARAMETER Comments
        Extra comments (markdown supported).

    .PARAMETER Tags
        One or more tags.

    .PARAMETER Mark_Utilized
        Treat as 100% utilized

    .PARAMETER Raw
        Return raw results from API service

    .EXAMPLE
        New-NetboxIPAMAddressRange -Start_Address 192.0.2.20/24 -End_Address 192.0.2.20/24

        Add new IP Address range from 192.0.2.20/24 to 192.0.2.20/24 with status active

    .NOTES
        https://netbox.neonet.org/static/docs/models/ipam/iprange/
#>

    [CmdletBinding(ConfirmImpact = 'Low',
                   SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Start_Address,

        [Parameter(Mandatory = $true)]
        [string]$End_Address,

        [object]$Status = 'Active',

        [uint64]$Tenant,

        [uint64]$VRF,

        [object]$Role,

        [hashtable]$Custom_Fields,

        [string]$Description,

        [string]$Comments,

        [object[]]$Tags,

        [switch]$Mark_Utilized,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-ranges'))
        $Method = 'POST'

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Start_Address, 'Create new IP address range')) {
            InvokeNetboxRequest -URI $URI -Method $Method -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}






#endregion

#region File New-NetboxIPAMASN.ps1

function New-NetboxIPAMASN {
<#
    .SYNOPSIS
        Create a new ASN in Netbox

    .DESCRIPTION
        Creates a new ASN (Autonomous System Number) object in Netbox.

    .PARAMETER ASN
        The ASN number (required, 1-4294967295)

    .PARAMETER RIR
        The RIR (Regional Internet Registry) ID

    .PARAMETER Tenant
        The tenant ID

    .PARAMETER Description
        A description of the ASN

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        New-NetboxIPAMASN -ASN 65001

        Creates ASN 65001

    .EXAMPLE
        New-NetboxIPAMASN -ASN 65001 -RIR 1 -Description "Primary ASN"

        Creates ASN 65001 with RIR and description
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 4294967295)]
        [uint64]$ASN,

        [uint64]$RIR,

        [uint64]$Tenant,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'asns'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($ASN, 'Create new ASN')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NetboxIPAMASNRange.ps1

function New-NetboxIPAMASNRange {
<#
    .SYNOPSIS
        Create a new ASN range in Netbox

    .DESCRIPTION
        Creates a new ASN range object in Netbox.

    .PARAMETER Name
        The name of the ASN range (required)

    .PARAMETER Slug
        The URL-friendly slug (required)

    .PARAMETER RIR
        The RIR (Regional Internet Registry) ID (required)

    .PARAMETER Start
        The starting ASN number (required)

    .PARAMETER End
        The ending ASN number (required)

    .PARAMETER Tenant
        The tenant ID

    .PARAMETER Description
        A description of the ASN range

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        New-NetboxIPAMASNRange -Name "Private" -Slug "private" -RIR 1 -Start 64512 -End 65534

        Creates a private ASN range
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Slug,

        [Parameter(Mandatory = $true)]
        [uint64]$RIR,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 4294967295)]
        [uint64]$Start,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 4294967295)]
        [uint64]$End,

        [uint64]$Tenant,

        [string]$Description,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'asn-ranges'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new ASN range')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NetboxIPAMPrefix.ps1


function New-NetboxIPAMPrefix {
    [CmdletBinding(ConfirmImpact = 'low',
        SupportsShouldProcess = $true)]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Prefix,

        [object]$Status = 'Active',

        [uint64]$Tenant,

        [object]$Role,

        [bool]$IsPool,

        [string]$Description,

        [uint64]$Site,

        [uint64]$VRF,

        [uint64]$VLAN,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    #    $PSBoundParameters.Status = ValidateIPAMChoice -ProvidedValue $Status -PrefixStatus

    <#
    # As of 2018/10/18, this does not appear to be a validated IPAM choice
    if ($null -ne $Role) {
        $PSBoundParameters.Role = ValidateIPAMChoice -ProvidedValue $Role -PrefixRole
    }
    #>

    $segments = [System.Collections.ArrayList]::new(@('ipam', 'prefixes'))

    $URIComponents = BuildURIComponents -URISegments $segments -ParametersDictionary $PSBoundParameters

    $URI = BuildNewURI -Segments $URIComponents.Segments

    if ($PSCmdlet.ShouldProcess($Prefix, 'Create new Prefix')) {
        InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
    }
}

#endregion

#region File New-NetboxIPAMRouteTarget.ps1

function New-NetboxIPAMRouteTarget {
<#
    .SYNOPSIS
        Create a new route target in Netbox

    .DESCRIPTION
        Creates a new route target object in Netbox.
        Route targets are used for VRF import/export policies (RFC 4360).

    .PARAMETER Name
        The route target value (required, RFC 4360 format, e.g., "65001:100")

    .PARAMETER Tenant
        The tenant ID that owns this route target

    .PARAMETER Description
        A description of the route target

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        New-NetboxIPAMRouteTarget -Name "65001:100"

        Creates a new route target with value "65001:100"

    .EXAMPLE
        New-NetboxIPAMRouteTarget -Name "65001:200" -Description "Customer A import"

        Creates a new route target with description
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [uint64]$Tenant,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'route-targets'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new route target')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NetboxIPAMService.ps1

function New-NetboxIPAMService {
<#
    .SYNOPSIS
        Create a new service in Netbox

    .DESCRIPTION
        Creates a new service object in Netbox.
        Services represent network services running on devices or virtual machines.

    .PARAMETER Name
        The name of the service (required)

    .PARAMETER Ports
        Array of port numbers (required)

    .PARAMETER Protocol
        The protocol (tcp, udp, sctp). Defaults to tcp.

    .PARAMETER Device
        The device ID this service runs on

    .PARAMETER Virtual_Machine
        The virtual machine ID this service runs on

    .PARAMETER IPAddresses
        Array of IP address IDs associated with this service

    .PARAMETER Description
        A description of the service

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        New-NetboxIPAMService -Name "HTTPS" -Ports @(443) -Protocol tcp -Device 1

        Creates an HTTPS service on device 1

    .EXAMPLE
        New-NetboxIPAMService -Name "DNS" -Ports @(53) -Protocol udp -Virtual_Machine 1

        Creates a DNS service on VM 1
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [uint16[]]$Ports,

        [ValidateSet('tcp', 'udp', 'sctp')]
        [string]$Protocol = 'tcp',

        [uint64]$Device,

        [uint64]$Virtual_Machine,

        [uint64[]]$IPAddresses,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'services'))

        # Build body manually to handle parent object type
        $Body = @{
            name = $Name
            ports = $Ports
            protocol = $Protocol
        }

        if ($Device) {
            $Body['parent_object_type'] = 'dcim.device'
            $Body['parent_object_id'] = $Device
        } elseif ($Virtual_Machine) {
            $Body['parent_object_type'] = 'virtualization.virtualmachine'
            $Body['parent_object_id'] = $Virtual_Machine
        }

        if ($IPAddresses) { $Body['ipaddresses'] = $IPAddresses }
        if ($Description) { $Body['description'] = $Description }
        if ($Comments) { $Body['comments'] = $Comments }
        if ($Custom_Fields) { $Body['custom_fields'] = $Custom_Fields }

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new service')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $Body -Raw:$Raw
        }
    }
}

#endregion

#region File New-NetboxIPAMServiceTemplate.ps1

function New-NetboxIPAMServiceTemplate {
<#
    .SYNOPSIS
        Create a new service template in Netbox

    .DESCRIPTION
        Creates a new service template object in Netbox.
        Service templates are reusable definitions for creating services.

    .PARAMETER Name
        The name of the service template (required)

    .PARAMETER Ports
        Array of port numbers (required)

    .PARAMETER Protocol
        The protocol (tcp, udp, sctp). Defaults to tcp.

    .PARAMETER Description
        A description of the service template

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        New-NetboxIPAMServiceTemplate -Name "HTTPS" -Ports @(443) -Protocol tcp

        Creates an HTTPS service template

    .EXAMPLE
        New-NetboxIPAMServiceTemplate -Name "Web Server" -Ports @(80, 443) -Protocol tcp

        Creates a web server template with HTTP and HTTPS ports
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [uint16[]]$Ports,

        [ValidateSet('tcp', 'udp', 'sctp')]
        [string]$Protocol = 'tcp',

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'service-templates'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new service template')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NetboxIPAMVLAN.ps1

function New-NetboxIPAMVLAN {
    <#
    .SYNOPSIS
        Create a new VLAN

    .DESCRIPTION
        Create a new VLAN in Netbox with a status of Active by default.

    .PARAMETER VID
        The VLAN ID.

    .PARAMETER Name
        The name of the VLAN.

    .PARAMETER Status
        Status of the VLAN. Defaults to Active

    .PARAMETER Tenant
        Tenant ID

    .PARAMETER Role
        Role such as anycast, loopback, etc... Defaults to nothing

    .PARAMETER Description
        Description of IP address

    .PARAMETER Custom_Fields
        Custom field hash table. Will be validated by the API service

    .PARAMETER Raw
        Return raw results from API service

    .PARAMETER Address
        IP address in CIDR notation: 192.168.1.1/24

    .EXAMPLE
        PS C:\> Create-NetboxIPAMAddress

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(ConfirmImpact = 'low',
        SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [uint16]$VID,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [object]$Status = 'Active',

        [uint64]$Tenant,

        [object]$Role,

        [string]$Description,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    #    $PSBoundParameters.Status = ValidateIPAMChoice -ProvidedValue $Status -VLANStatus

    #    if ($null -ne $Role) {
    #        $PSBoundParameters.Role = ValidateIPAMChoice -ProvidedValue $Role -IPAddressRole
    #    }

    $segments = [System.Collections.ArrayList]::new(@('ipam', 'vlans'))

    $URIComponents = BuildURIComponents -URISegments $segments -ParametersDictionary $PSBoundParameters

    $URI = BuildNewURI -Segments $URIComponents.Segments

    if ($PSCmdlet.ShouldProcess($nae, 'Create new Vlan $($vid)')) {
        InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
    }
}

#endregion

#region File New-NetboxIPAMVRF.ps1

function New-NetboxIPAMVRF {
<#
    .SYNOPSIS
        Create a new VRF in Netbox

    .DESCRIPTION
        Creates a new VRF (Virtual Routing and Forwarding) object in Netbox.

    .PARAMETER Name
        The name of the VRF (required)

    .PARAMETER RD
        The route distinguisher (RFC 4364 format, e.g., "65001:100")

    .PARAMETER Tenant
        The tenant ID that owns this VRF

    .PARAMETER Enforce_Unique
        Prevent duplicate prefixes/IP addresses within this VRF

    .PARAMETER Description
        A description of the VRF

    .PARAMETER Comments
        Additional comments

    .PARAMETER Import_Targets
        Array of route target IDs for import

    .PARAMETER Export_Targets
        Array of route target IDs for export

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        New-NetboxIPAMVRF -Name "Production"

        Creates a new VRF named "Production"

    .EXAMPLE
        New-NetboxIPAMVRF -Name "Customer-A" -RD "65001:100" -Enforce_Unique $true

        Creates a new VRF with route distinguisher and unique enforcement
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$RD,

        [uint64]$Tenant,

        [bool]$Enforce_Unique,

        [string]$Description,

        [string]$Comments,

        [uint64[]]$Import_Targets,

        [uint64[]]$Export_Targets,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'vrfs'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new VRF')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NetboxTenant.ps1


function New-NetboxTenant {
<#
    .SYNOPSIS
        Create a new tenant in Netbox

    .DESCRIPTION
        Creates a new tenant object in Netbox

    .PARAMETER Name
        The tenant name, e.g "Contoso Inc"

    .PARAMETER Slug
        The unique URL for the tenant. Can only contain hypens, A-Z, a-z, 0-9, and underscores

    .PARAMETER Description
        Short description of the tenant

    .PARAMETER Custom_Fields
        Hashtable of custom field values.

    .PARAMETER Raw
        Return the unparsed data from the HTTP request

    .EXAMPLE
        PS C:\> New-NetboxTenant -Name 'Contoso Inc' -Slug 'contoso-inc'

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(ConfirmImpact = 'Low',
                   SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateLength(1, 100)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 100)]
        [ValidatePattern('^[-a-zA-Z0-9_]+$')]
        [string]$Slug,

        [ValidateLength(0, 200)]
        [string]$Description,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'tenants'))
        $Method = 'POST'

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Address, 'Create new tenant')) {
            InvokeNetboxRequest -URI $URI -Method $Method -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}





#endregion

#region File New-NetboxVirtualMachine.ps1


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





#endregion

#region File New-NetboxVPNIKEPolicy.ps1

function New-NetboxVPNIKEPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param([Parameter(Mandatory = $true)][string]$Name,[uint16]$Version,[string]$Mode,[uint64[]]$Proposals,
        [string]$Preshared_Key,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','ike-policies')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create IKE policy')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File New-NetboxVPNIKEProposal.ps1

function New-NetboxVPNIKEProposal {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param([Parameter(Mandatory = $true)][string]$Name,[string]$Authentication_Method,[string]$Encryption_Algorithm,
        [string]$Authentication_Algorithm,[uint16]$Group,[uint32]$SA_Lifetime,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','ike-proposals')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create IKE proposal')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File New-NetboxVPNIPSecPolicy.ps1

function New-NetboxVPNIPSecPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param([Parameter(Mandatory = $true)][string]$Name,[uint64[]]$Proposals,[bool]$Pfs_Group,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-policies')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create IPSec policy')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File New-NetboxVPNIPSecProfile.ps1

function New-NetboxVPNIPSecProfile {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param([Parameter(Mandatory = $true)][string]$Name,[string]$Mode,[uint64]$IKE_Policy,[uint64]$IPSec_Policy,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-profiles')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create IPSec profile')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File New-NetboxVPNIPSecProposal.ps1

function New-NetboxVPNIPSecProposal {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param([Parameter(Mandatory = $true)][string]$Name,[string]$Encryption_Algorithm,[string]$Authentication_Algorithm,[uint32]$SA_Lifetime_Seconds,[uint32]$SA_Lifetime_Data,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-proposals')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create IPSec proposal')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File New-NetboxVPNL2VPN.ps1

function New-NetboxVPNL2VPN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param([Parameter(Mandatory = $true)][string]$Name,[Parameter(Mandatory = $true)][string]$Slug,
        [uint64]$Identifier,[string]$Type,[string]$Status,[uint64]$Tenant,[string]$Description,[string]$Comments,
        [uint64[]]$Import_Targets,[uint64[]]$Export_Targets,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','l2vpns')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create L2VPN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File New-NetboxVPNL2VPNTermination.ps1

function New-NetboxVPNL2VPNTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param([Parameter(Mandatory = $true)][uint64]$L2VPN,[Parameter(Mandatory = $true)][string]$Assigned_Object_Type,[Parameter(Mandatory = $true)][uint64]$Assigned_Object_Id,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','l2vpn-terminations')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("L2VPN $L2VPN", 'Create L2VPN termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File New-NetboxVPNTunnel.ps1

function New-NetboxVPNTunnel {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][ValidateSet('active', 'planned', 'disabled')][string]$Status,
        [Parameter(Mandatory = $true)][ValidateSet('ipsec-transport', 'ipsec-tunnel', 'ip-ip', 'gre')][string]$Encapsulation,
        [uint64]$Group,
        [uint64]$IPSec_Profile,
        [uint64]$Tenant,
        [uint64]$Tunnel_Id,
        [string]$Description,
        [string]$Comments,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('vpn', 'tunnels'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments
        if ($PSCmdlet.ShouldProcess($Name, 'Create new VPN tunnel')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NetboxVPNTunnelGroup.ps1

function New-NetboxVPNTunnelGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param([Parameter(Mandatory = $true)][string]$Name,[Parameter(Mandatory = $true)][string]$Slug,[string]$Description,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','tunnel-groups')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create tunnel group')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File New-NetboxVPNTunnelTermination.ps1

function New-NetboxVPNTunnelTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param([Parameter(Mandatory = $true)][uint64]$Tunnel,[Parameter(Mandatory = $true)][ValidateSet('peer', 'hub', 'spoke')][string]$Role,
        [string]$Termination_Type,[uint64]$Termination_Id,[uint64]$Outside_IP,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','tunnel-terminations')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("Tunnel $Tunnel", 'Create tunnel termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File New-NetboxWirelessLAN.ps1

function New-NetboxWirelessLAN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param([Parameter(Mandatory = $true)][string]$SSID,[uint64]$Group,[string]$Status,[uint64]$VLAN,[uint64]$Tenant,
        [string]$Auth_Type,[string]$Auth_Cipher,[string]$Auth_PSK,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('wireless','wireless-lans')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($SSID, 'Create wireless LAN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File New-NetboxWirelessLANGroup.ps1

function New-NetboxWirelessLANGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param([Parameter(Mandatory = $true)][string]$Name,[Parameter(Mandatory = $true)][string]$Slug,[uint64]$Parent,[string]$Description,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('wireless','wireless-lan-groups')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create wireless LAN group')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File New-NetboxWirelessLink.ps1

function New-NetboxWirelessLink {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param([Parameter(Mandatory = $true)][uint64]$Interface_A,[Parameter(Mandatory = $true)][uint64]$Interface_B,
        [string]$SSID,[string]$Status,[uint64]$Tenant,[string]$Auth_Type,[string]$Auth_Cipher,[string]$Auth_PSK,
        [string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('wireless','wireless-links')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("$Interface_A to $Interface_B", 'Create wireless link')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File Remove-NetboxDCIMDevice.ps1


function Remove-NetboxDCIMDevice {
<#
    .SYNOPSIS
        Delete a device

    .DESCRIPTION
        Deletes a device from Netbox by ID

    .PARAMETER Id
        Database ID of the device

    .PARAMETER Force
        Force deletion without any prompts

    .EXAMPLE
        PS C:\> Remove-NetboxDCIMDevice -Id $value1

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(ConfirmImpact = 'High',
                   SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force
    )

    begin {

    }

    process {
        foreach ($DeviceID in $Id) {
            $CurrentDevice = Get-NetboxDCIMDevice -Id $DeviceID -ErrorAction Stop

            if ($Force -or $pscmdlet.ShouldProcess("Name: $($CurrentDevice.Name) | ID: $($CurrentDevice.Id)", "Remove")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'devices', $CurrentDevice.Id))

                $URI = BuildNewURI -Segments $Segments

                InvokeNetboxRequest -URI $URI -Method DELETE
            }
        }
    }

    end {

    }
}

#endregion

#region File Remove-NetboxDCIMFrontPort.ps1

function Remove-NetboxDCIMFrontPort {

    [CmdletBinding(ConfirmImpact = 'High',
        SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force
    )

    begin {

    }

    process {
        foreach ($FrontPortID in $Id) {
            $CurrentPort = Get-NetboxDCIMFrontPort -Id $FrontPortID -ErrorAction Stop

            if ($Force -or $pscmdlet.ShouldProcess("Name: $($CurrentPort.Name) | ID: $($CurrentPort.Id)", "Remove")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'front-ports', $CurrentPort.Id))

                $URI = BuildNewURI -Segments $Segments

                InvokeNetboxRequest -URI $URI -Method DELETE
            }
        }
    }

    end {

    }
}

#endregion

#region File Remove-NetboxDCIMInterface.ps1

function Remove-NetboxDCIMInterface {
    <#
    .SYNOPSIS
        Removes an interface

    .DESCRIPTION
        Removes an interface by ID from a device

    .PARAMETER Id
        A description of the Id parameter.

    .PARAMETER Force
        A description of the Force parameter.

    .EXAMPLE
        		PS C:\> Remove-NetboxDCIMInterface -Id $value1

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(ConfirmImpact = 'High',
        SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force
    )

    begin {

    }

    process {
        foreach ($InterfaceId in $Id) {
            $CurrentInterface = Get-NetboxDCIMInterface -Id $InterfaceId -ErrorAction Stop

            if ($Force -or $pscmdlet.ShouldProcess("Name: $($CurrentInterface.Name) | ID: $($CurrentInterface.Id)", "Remove")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'interfaces', $CurrentInterface.Id))

                $URI = BuildNewURI -Segments $Segments

                InvokeNetboxRequest -URI $URI -Method DELETE
            }
        }
    }

    end {

    }
}

#endregion

#region File Remove-NetboxDCIMInterfaceConnection.ps1


function Remove-NetboxDCIMInterfaceConnection {
    [CmdletBinding(ConfirmImpact = 'High',
                   SupportsShouldProcess = $true)]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force
    )

    begin {

    }

    process {
        foreach ($ConnectionID in $Id) {
            $CurrentConnection = Get-NetboxDCIMInterfaceConnection -Id $ConnectionID -ErrorAction Stop

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

#endregion

#region File Remove-NetboxDCIMLocation.ps1

function Remove-NetboxDCIMLocation {
<#
    .SYNOPSIS
        Remove a location from Netbox

    .DESCRIPTION
        Deletes a location object from Netbox.

    .PARAMETER Id
        The ID of the location to delete (required)

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Remove-NetboxDCIMLocation -Id 1

        Deletes location with ID 1

    .EXAMPLE
        Get-NetboxDCIMLocation -Name "Old Room" | Remove-NetboxDCIMLocation

        Deletes locations matching the name "Old Room"
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'locations', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete location')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NetboxDCIMManufacturer.ps1

function Remove-NetboxDCIMManufacturer {
<#
    .SYNOPSIS
        Delete a manufacturer from Netbox

    .DESCRIPTION
        Removes a manufacturer object from Netbox.

    .PARAMETER Id
        The ID of the manufacturer to delete

    .PARAMETER Force
        Skip confirmation prompts

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Remove-NetboxDCIMManufacturer -Id 1

        Deletes manufacturer with ID 1 (with confirmation)

    .EXAMPLE
        Remove-NetboxDCIMManufacturer -Id 1 -Confirm:$false

        Deletes manufacturer with ID 1 without confirmation

    .EXAMPLE
        Get-NetboxDCIMManufacturer -Name "OldVendor" | Remove-NetboxDCIMManufacturer

        Deletes manufacturer named "OldVendor"
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        foreach ($ManufacturerId in $Id) {
            $CurrentManufacturer = Get-NetboxDCIMManufacturer -Id $ManufacturerId -ErrorAction Stop

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentManufacturer.Name)", "Delete manufacturer")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'manufacturers', $CurrentManufacturer.Id))

                $URI = BuildNewURI -Segments $Segments

                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Remove-NetboxDCIMRack.ps1

function Remove-NetboxDCIMRack {
<#
    .SYNOPSIS
        Delete a rack from Netbox

    .DESCRIPTION
        Removes a rack object from Netbox.

    .PARAMETER Id
        The ID of the rack to delete

    .PARAMETER Force
        Skip confirmation prompts

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Remove-NetboxDCIMRack -Id 1

        Deletes rack with ID 1 (with confirmation)

    .EXAMPLE
        Remove-NetboxDCIMRack -Id 1 -Confirm:$false

        Deletes rack with ID 1 without confirmation

    .EXAMPLE
        Get-NetboxDCIMRack -Name "Rack-01" | Remove-NetboxDCIMRack

        Deletes rack named "Rack-01"
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        foreach ($RackId in $Id) {
            $CurrentRack = Get-NetboxDCIMRack -Id $RackId -ErrorAction Stop

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentRack.Name)", "Delete rack")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'racks', $CurrentRack.Id))

                $URI = BuildNewURI -Segments $Segments

                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Remove-NetboxDCIMRearPort.ps1

function Remove-NetboxDCIMRearPort {

    [CmdletBinding(ConfirmImpact = 'High',
        SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force
    )

    begin {

    }

    process {
        foreach ($RearPortID in $Id) {
            $CurrentPort = Get-NetboxDCIMRearPort -Id $RearPortID -ErrorAction Stop

            if ($Force -or $pscmdlet.ShouldProcess("Name: $($CurrentPort.Name) | ID: $($CurrentPort.Id)", "Remove")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'rear-ports', $CurrentPort.Id))

                $URI = BuildNewURI -Segments $Segments

                InvokeNetboxRequest -URI $URI -Method DELETE
            }
        }
    }

    end {

    }
}

#endregion

#region File Remove-NetboxDCIMRegion.ps1

function Remove-NetboxDCIMRegion {
<#
    .SYNOPSIS
        Remove a region from Netbox

    .DESCRIPTION
        Deletes a region object from Netbox.

    .PARAMETER Id
        The ID of the region to delete (required)

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Remove-NetboxDCIMRegion -Id 1

        Deletes region with ID 1

    .EXAMPLE
        Get-NetboxDCIMRegion -Name "Old Region" | Remove-NetboxDCIMRegion

        Deletes regions matching the name "Old Region"
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'regions', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete region')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NetboxDCIMSite.ps1

<#
    .NOTES
    ===========================================================================
     Created with:  SAPIEN Technologies, Inc., PowerShell Studio 2020 v5.7.181
     Created on:    2020-10-02 15:52
     Created by:    Claussen
     Organization:  NEOnet
     Filename:      New-NetboxDCIMSite.ps1
    ===========================================================================
    .DESCRIPTION
        A description of the file.
#>


function Remove-NetboxDCIMSite {
    <#
        .SYNOPSIS
            Remove a Site

        .DESCRIPTION
            Remove a DCIM Site from Netbox

        .EXAMPLE
            Remove-NetboxDCIMSite -Id 1

            Remove DCM Site with id 1

        .EXAMPLE
            Get-NetboxDCIMSite -name My Site | Remove-NetboxDCIMSite -confirm:$false

            Remove DCM Site with name My Site without confirmation

    #>

    [CmdletBinding(ConfirmImpact = 'High',
        SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [uint]$Id

    )

    begin {

    }

    process {
        $CurrentSite = Get-NetboxDCIMSite -Id $Id -ErrorAction Stop

        if ($pscmdlet.ShouldProcess("$($CurrentSite.Name)/$($CurrentSite.Id)", "Remove Site")) {
            $Segments = [System.Collections.ArrayList]::new(@('dcim', 'sites', $CurrentSite.Id))

            $URI = BuildNewURI -Segments $Segments

            InvokeNetboxRequest -URI $URI -Method DELETE
        }
    }

    end {

    }
}

#endregion

#region File Remove-NetboxDCIMSiteGroup.ps1

function Remove-NetboxDCIMSiteGroup {
<#
    .SYNOPSIS
        Remove a site group from Netbox

    .DESCRIPTION
        Deletes a site group object from Netbox.

    .PARAMETER Id
        The ID of the site group to delete (required)

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Remove-NetboxDCIMSiteGroup -Id 1

        Deletes site group with ID 1

    .EXAMPLE
        Get-NetboxDCIMSiteGroup -Name "Old Group" | Remove-NetboxDCIMSiteGroup

        Deletes site groups matching the name "Old Group"
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'site-groups', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete site group')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NetboxIPAMAddress.ps1


function Remove-NetboxIPAMAddress {
    <#
    .SYNOPSIS
        Remove an IP address from Netbox

    .DESCRIPTION
        Removes/deletes an IP address from Netbox by ID and optional other filters

    .PARAMETER Id
        Database ID of the IP address object.

    .PARAMETER Force
        Do not confirm.

    .EXAMPLE
        PS C:\> Remove-NetboxIPAMAddress -Id $value1

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(ConfirmImpact = 'High',
        SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force
    )

    process {
        foreach ($IPId in $Id) {
            $CurrentIP = Get-NetboxIPAMAddress -Id $IPId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-addresses', $IPId))

            if ($Force -or $pscmdlet.ShouldProcess($CurrentIP.Address, "Delete")) {
                $URI = BuildNewURI -Segments $Segments

                InvokeNetboxRequest -URI $URI -Method DELETE
            }
        }
    }
}

#endregion

#region File Remove-NetboxIPAMAddressRange.ps1


function Remove-NetboxIPAMAddressRange {
    <#
    .SYNOPSIS
        Remove an IP address range from Netbox

    .DESCRIPTION
        Removes/deletes an IP address range from Netbox by ID

    .PARAMETER Id
        Database ID of the IP address range object.

    .PARAMETER Force
        Do not confirm.

    .EXAMPLE
        PS C:\> Remove-NetboxIPAMAddressRange -Id 1234

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(ConfirmImpact = 'High',
                   SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force
    )

    process {
        foreach ($Range_Id in $Id) {
            $CurrentRange = Get-NetboxIPAMAddressRange -Id $Range_Id -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-ranges', $Range_Id))

            if ($Force -or $pscmdlet.ShouldProcess($CurrentRange.start_address, "Delete")) {
                $URI = BuildNewURI -Segments $Segments

                InvokeNetboxRequest -URI $URI -Method DELETE
            }
        }
    }
}

#endregion

#region File Remove-NetboxIPAMASN.ps1

function Remove-NetboxIPAMASN {
<#
    .SYNOPSIS
        Remove an ASN from Netbox

    .DESCRIPTION
        Deletes an ASN (Autonomous System Number) object from Netbox.

    .PARAMETER Id
        The ID of the ASN to delete (required)

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Remove-NetboxIPAMASN -Id 1

        Deletes ASN with ID 1
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'asns', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete ASN')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NetboxIPAMASNRange.ps1

function Remove-NetboxIPAMASNRange {
<#
    .SYNOPSIS
        Remove an ASN range from Netbox

    .DESCRIPTION
        Deletes an ASN range object from Netbox.

    .PARAMETER Id
        The ID of the ASN range to delete (required)

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Remove-NetboxIPAMASNRange -Id 1

        Deletes ASN range with ID 1
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'asn-ranges', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete ASN range')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NetboxIPAMRouteTarget.ps1

function Remove-NetboxIPAMRouteTarget {
<#
    .SYNOPSIS
        Remove a route target from Netbox

    .DESCRIPTION
        Deletes a route target object from Netbox.

    .PARAMETER Id
        The ID of the route target to delete (required)

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Remove-NetboxIPAMRouteTarget -Id 1

        Deletes route target with ID 1

    .EXAMPLE
        Get-NetboxIPAMRouteTarget -Name "65001:999" | Remove-NetboxIPAMRouteTarget

        Deletes route targets matching the specified value
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'route-targets', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete route target')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NetboxIPAMService.ps1

function Remove-NetboxIPAMService {
<#
    .SYNOPSIS
        Remove a service from Netbox

    .DESCRIPTION
        Deletes a service object from Netbox.

    .PARAMETER Id
        The ID of the service to delete (required)

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Remove-NetboxIPAMService -Id 1

        Deletes service with ID 1
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'services', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete service')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NetboxIPAMServiceTemplate.ps1

function Remove-NetboxIPAMServiceTemplate {
<#
    .SYNOPSIS
        Remove a service template from Netbox

    .DESCRIPTION
        Deletes a service template object from Netbox.

    .PARAMETER Id
        The ID of the service template to delete (required)

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Remove-NetboxIPAMServiceTemplate -Id 1

        Deletes service template with ID 1
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'service-templates', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete service template')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NetboxIPAMVRF.ps1

function Remove-NetboxIPAMVRF {
<#
    .SYNOPSIS
        Remove a VRF from Netbox

    .DESCRIPTION
        Deletes a VRF (Virtual Routing and Forwarding) object from Netbox.

    .PARAMETER Id
        The ID of the VRF to delete (required)

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Remove-NetboxIPAMVRF -Id 1

        Deletes VRF with ID 1

    .EXAMPLE
        Get-NetboxIPAMVRF -Name "Test-VRF" | Remove-NetboxIPAMVRF

        Deletes VRFs matching the name "Test-VRF"
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'vrfs', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete VRF')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NetboxVirtualMachine.ps1


function Remove-NetboxVirtualMachine {
<#
    .SYNOPSIS
        Delete a virtual machine

    .DESCRIPTION
        Deletes a virtual machine from Netbox by ID

    .PARAMETER Id
        Database ID of the virtual machine

    .PARAMETER Force
        Force deletion without any prompts

    .EXAMPLE
        PS C:\> Remove-NetboxVirtualMachine -Id $value1

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(ConfirmImpact = 'High',
                   SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force
    )

    begin {

    }

    process {
        foreach ($VMId in $Id) {
            $CurrentVM = Get-NetboxVirtualMachine -Id $VMId -ErrorAction Stop

            if ($Force -or $pscmdlet.ShouldProcess("$($CurrentVM.Name)/$($CurrentVM.Id)", "Remove")) {
                $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'virtual-machines', $CurrentVM.Id))

                $URI = BuildNewURI -Segments $Segments

                InvokeNetboxRequest -URI $URI -Method DELETE
            }
        }
    }

    end {

    }
}

#endregion

#region File Remove-NetboxVPNIKEPolicy.ps1

function Remove-NetboxVPNIKEPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete IKE policy')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ike-policies',$Id)) -Method DELETE -Raw:$Raw } }
}

#endregion

#region File Remove-NetboxVPNIKEProposal.ps1

function Remove-NetboxVPNIKEProposal {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete IKE proposal')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ike-proposals',$Id)) -Method DELETE -Raw:$Raw } }
}

#endregion

#region File Remove-NetboxVPNIPSecPolicy.ps1

function Remove-NetboxVPNIPSecPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete IPSec policy')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ipsec-policies',$Id)) -Method DELETE -Raw:$Raw } }
}

#endregion

#region File Remove-NetboxVPNIPSecProfile.ps1

function Remove-NetboxVPNIPSecProfile {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete IPSec profile')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ipsec-profiles',$Id)) -Method DELETE -Raw:$Raw } }
}

#endregion

#region File Remove-NetboxVPNIPSecProposal.ps1

function Remove-NetboxVPNIPSecProposal {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete IPSec proposal')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ipsec-proposals',$Id)) -Method DELETE -Raw:$Raw } }
}

#endregion

#region File Remove-NetboxVPNL2VPN.ps1

function Remove-NetboxVPNL2VPN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete L2VPN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','l2vpns',$Id)) -Method DELETE -Raw:$Raw } }
}

#endregion

#region File Remove-NetboxVPNL2VPNTermination.ps1

function Remove-NetboxVPNL2VPNTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete L2VPN termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','l2vpn-terminations',$Id)) -Method DELETE -Raw:$Raw } }
}

#endregion

#region File Remove-NetboxVPNTunnel.ps1

function Remove-NetboxVPNTunnel {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('vpn', 'tunnels', $Id))
        $URI = BuildNewURI -Segments $Segments
        if ($PSCmdlet.ShouldProcess($Id, 'Delete VPN tunnel')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NetboxVPNTunnelGroup.ps1

function Remove-NetboxVPNTunnelGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete tunnel group')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','tunnel-groups',$Id)) -Method DELETE -Raw:$Raw } }
}

#endregion

#region File Remove-NetboxVPNTunnelTermination.ps1

function Remove-NetboxVPNTunnelTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete tunnel termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','tunnel-terminations',$Id)) -Method DELETE -Raw:$Raw } }
}

#endregion

#region File Remove-NetboxWirelessLAN.ps1

function Remove-NetboxWirelessLAN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete wireless LAN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('wireless','wireless-lans',$Id)) -Method DELETE -Raw:$Raw } }
}

#endregion

#region File Remove-NetboxWirelessLANGroup.ps1

function Remove-NetboxWirelessLANGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete wireless LAN group')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('wireless','wireless-lan-groups',$Id)) -Method DELETE -Raw:$Raw } }
}

#endregion

#region File Remove-NetboxWirelessLink.ps1

function Remove-NetboxWirelessLink {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete wireless link')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('wireless','wireless-links',$Id)) -Method DELETE -Raw:$Raw } }
}

#endregion

#region File Set-NetboxCipherSSL.ps1

Function Set-NetboxCipherSSL {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessforStateChangingFunctions", "")]
    Param(  )
    # Hack for allowing TLS 1.1 and TLS 1.2 (by default it is only SSL3 and TLS (1.0))
    $AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
    [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols

}

#endregion

#region File Set-NetboxContact.ps1


function Set-NetboxContact {
<#
    .SYNOPSIS
        Update a contact in Netbox

    .DESCRIPTION
        Updates a contact object in Netbox which can be linked to other objects

    .PARAMETER Id
        A description of the Id parameter.

    .PARAMETER Name
        The contacts full name, e.g "Leroy Jenkins"

    .PARAMETER Email
        Email address of the contact

    .PARAMETER Group
        Database ID of assigned group

    .PARAMETER Title
        Job title or other title related to the contact

    .PARAMETER Phone
        Telephone number

    .PARAMETER Address
        Physical address, usually mailing address

    .PARAMETER Description
        Short description of the contact

    .PARAMETER Comments
        Detailed comments. Markdown supported.

    .PARAMETER Link
        URI related to the contact

    .PARAMETER Custom_Fields
        A description of the Custom_Fields parameter.

    .PARAMETER Force
        A description of the Force parameter.

    .PARAMETER Raw
        A description of the Raw parameter.

    .EXAMPLE
        PS C:\> Set-NetboxContact -Id 10 -Name 'Leroy Jenkins' -Email 'leroy.jenkins@example.com'

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(ConfirmImpact = 'Low',
                   SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [ValidateLength(1, 100)]
        [string]$Name,

        [ValidateLength(0, 254)]
        [string]$Email,

        [uint64]$Group,

        [ValidateLength(0, 100)]
        [string]$Title,

        [ValidateLength(0, 50)]
        [string]$Phone,

        [ValidateLength(0, 200)]
        [string]$Address,

        [ValidateLength(0, 200)]
        [string]$Description,

        [string]$Comments,

        [ValidateLength(0, 200)]
        [string]$Link,

        [hashtable]$Custom_Fields,

        [switch]$Force,

        [switch]$Raw
    )

    begin {
        $Method = 'PATCH'
    }

    process {
        foreach ($ContactId in $Id) {
            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contacts', $ContactId))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force'

            $URI = BuildNewURI -Segments $URIComponents.Segments

            $CurrentContact = Get-NetboxContact -Id $ContactId -ErrorAction Stop

            if ($Force -or $PSCmdlet.ShouldProcess($CurrentContact.Name, 'Update contact')) {
                InvokeNetboxRequest -URI $URI -Method $Method -Body $URIComponents.Parameters -Raw:$Raw
            }
        }
    }
}





#endregion

#region File Set-NetboxContactAssignment.ps1



function Set-NetboxContactAssignment {
<#
    .SYNOPSIS
        Update a contact role assignment in Netbox

    .DESCRIPTION
        Updates a contact role assignment in Netbox

    .PARAMETER Content_Type
        The content type for this assignment.

    .PARAMETER Object_Id
        ID of the object to assign.

    .PARAMETER Contact
        ID of the contact to assign.

    .PARAMETER Role
        ID of the contact role to assign.

    .PARAMETER Priority
        Priority of the contact assignment.

    .PARAMETER Raw
        Return the unparsed data from the HTTP request

    .EXAMPLE
        PS C:\> Set-NetboxContactAssignment -Id 11 -Content_Type 'dcim.location' -Object_id 10 -Contact 15 -Role 10 -Priority 'Primary'

    .NOTES
        Valid content types: https://docs.netbox.dev/en/stable/features/contacts/#contacts_1
#>

    [CmdletBinding(ConfirmImpact = 'Low',
                   SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('circuits.circuit', 'circuits.provider', 'circuits.provideraccount', 'dcim.device', 'dcim.location', 'dcim.manufacturer', 'dcim.powerpanel', 'dcim.rack', 'dcim.region', 'dcim.site', 'dcim.sitegroup', 'tenancy.tenant', 'virtualization.cluster', 'virtualization.clustergroup', 'virtualization.virtualmachine', IgnoreCase = $true)]
        [string]$Content_Type,

        [uint64]$Object_Id,

        [uint64]$Contact,

        [uint64]$Role,

        [ValidateSet('primary', 'secondary', 'tertiary', 'inactive', IgnoreCase = $true)]
        [string]$Priority,

        [switch]$Raw
    )

    begin {
        $Method = 'Patch'
    }

    process {
        foreach ($ContactAssignmentId in $Id) {
            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contact-assignments', $ContactAssignmentId))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force'

            $URI = BuildNewURI -Segments $URIComponents.Segments

            $CurrentContactAssignment = Get-NetboxContactAssignment -Id $ContactAssignmentId -ErrorAction Stop

            if ($PSCmdlet.ShouldProcess($CurrentContactAssignment.Id, 'Update contact assignment')) {
                InvokeNetboxRequest -URI $URI -Method $Method -Body $URIComponents.Parameters -Raw:$Raw
            }
        }
    }
}





#endregion

#region File Set-NetboxContactRole.ps1


function Set-NetboxContactRole {
<#
    .SYNOPSIS
        Update a contact role in Netbox

    .DESCRIPTION
        Updates a contact role in Netbox

    .PARAMETER Name
        The contact role name, e.g "Network Support"

    .PARAMETER Slug
        The unique URL for the role. Can only contain hypens, A-Z, a-z, 0-9, and underscores

    .PARAMETER Description
        Short description of the contact role

    .PARAMETER Custom_Fields
        A description of the Custom_Fields parameter.

    .PARAMETER Raw
        Return the unparsed data from the HTTP request

    .EXAMPLE
        PS C:\> New-NetboxContact -Name 'Leroy Jenkins' -Email 'leroy.jenkins@example.com'

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(ConfirmImpact = 'Low',
                   SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateLength(1, 100)]
        [string]$Name,

        [ValidateLength(1, 100)]
        [ValidatePattern('^[-a-zA-Z0-9_]+$')]
        [string]$Slug,

        [ValidateLength(0, 200)]
        [string]$Description,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    begin {
        $Method = 'PATCH'
    }

    process {
        foreach ($ContactRoleId in $Id) {
            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contacts', $ContactRoleId))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force'

            $URI = BuildNewURI -Segments $URIComponents.Segments

            $CurrentContactRole = Get-NetboxContactRole -Id $ContactRoleId -ErrorAction Stop

            if ($Force -or $PSCmdlet.ShouldProcess($CurrentContactRole.Name, 'Update contact role')) {
                InvokeNetboxRequest -URI $URI -Method $Method -Body $URIComponents.Parameters -Raw:$Raw
            }
        }
    }
}





#endregion

#region File Set-NetboxCredential.ps1

function Set-NetboxCredential {
    [CmdletBinding(DefaultParameterSetName = 'CredsObject',
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true)]
    [OutputType([pscredential])]
    param
    (
        [Parameter(ParameterSetName = 'CredsObject',
            Mandatory = $true)]
        [pscredential]$Credential,

        [Parameter(ParameterSetName = 'UserPass',
            Mandatory = $true)]
        [securestring]$Token
    )

    if ($PSCmdlet.ShouldProcess('Netbox Credentials', 'Set')) {
        switch ($PsCmdlet.ParameterSetName) {
            'CredsObject' {
                $script:NetboxConfig.Credential = $Credential
                break
            }

            'UserPass' {
                $script:NetboxConfig.Credential = [System.Management.Automation.PSCredential]::new('notapplicable', $Token)
                break
            }
        }

        $script:NetboxConfig.Credential
    }
}

#endregion

#region File Set-NetboxDCIMDevice.ps1


function Set-NetboxDCIMDevice {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Name,

        [object]$Device_Role,

        [object]$Device_Type,

        [uint64]$Site,

        [object]$Status,

        [uint64]$Platform,

        [uint64]$Tenant,

        [uint64]$Cluster,

        [uint64]$Rack,

        [uint16]$Position,

        [object]$Face,

        [string]$Serial,

        [string]$Asset_Tag,

        [uint64]$Virtual_Chassis,

        [uint64]$VC_Priority,

        [uint64]$VC_Position,

        [uint64]$Primary_IP4,

        [uint64]$Primary_IP6,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Force
    )

    begin {

    }

    process {
        foreach ($DeviceID in $Id) {
            $CurrentDevice = Get-NetboxDCIMDevice -Id $DeviceID -ErrorAction Stop

            if ($Force -or $pscmdlet.ShouldProcess("$($CurrentDevice.Name)", "Set")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'devices', $CurrentDevice.Id))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH
            }
        }
    }

    end {

    }
}

#endregion

#region File Set-NetboxDCIMFrontPort.ps1

function Set-NetboxDCIMFrontPort {
    [CmdletBinding(ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [uint16]$Device,

        [uint16]$Module,

        [string]$Name,

        [string]$Label,

        [string]$Type,

        [ValidatePattern('^[0-9a-f]{6}$')]
        [string]$Color,

        [uint64]$Rear_Port,

        [uint16]$Rear_Port_Position,

        [string]$Description,

        [bool]$Mark_Connected,

        [uint64[]]$Tags,

        [switch]$Force
    )

    begin {

    }

    process {
        foreach ($FrontPortID in $Id) {
            $CurrentPort = Get-NetboxDCIMFrontPort -Id $FrontPortID -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('dcim', 'front-ports', $CurrentPort.Id))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id'

            $URI = BuildNewURI -Segments $Segments

            if ($Force -or $pscmdlet.ShouldProcess("Front Port ID $($CurrentPort.Id)", "Set")) {
                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH
            }
        }
    }

    end {

    }
}

#endregion

#region File Set-NetboxDCIMInterface.ps1

function Set-NetboxDCIMInterface {
    [CmdletBinding(ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [uint64]$Device,

        [string]$Name,

        [bool]$Enabled,

        [object]$Form_Factor,

        [ValidateSet('virtual', 'bridge', 'lag', '100base-tx', '1000base-t', '2.5gbase-t', '5gbase-t', '10gbase-t', '10gbase-cx4', '1000base-x-gbic', '1000base-x-sfp', '10gbase-x-sfpp', '10gbase-x-xfp', '10gbase-x-xenpak', '10gbase-x-x2', '25gbase-x-sfp28', '50gbase-x-sfp56', '40gbase-x-qsfpp', '50gbase-x-sfp28', '100gbase-x-cfp', '100gbase-x-cfp2', '200gbase-x-cfp2', '100gbase-x-cfp4', '100gbase-x-cpak', '100gbase-x-qsfp28', '200gbase-x-qsfp56', '400gbase-x-qsfpdd', '400gbase-x-osfp', '1000base-kx', '10gbase-kr', '10gbase-kx4', '25gbase-kr', '40gbase-kr4', '50gbase-kr', '100gbase-kp4', '100gbase-kr2', '100gbase-kr4', 'ieee802.11a', 'ieee802.11g', 'ieee802.11n', 'ieee802.11ac', 'ieee802.11ad', 'ieee802.11ax', 'ieee802.11ay', 'ieee802.15.1', 'other-wireless', 'gsm', 'cdma', 'lte', 'sonet-oc3', 'sonet-oc12', 'sonet-oc48', 'sonet-oc192', 'sonet-oc768', 'sonet-oc1920', 'sonet-oc3840', '1gfc-sfp', '2gfc-sfp', '4gfc-sfp', '8gfc-sfpp', '16gfc-sfpp', '32gfc-sfp28', '64gfc-qsfpp', '128gfc-qsfp28', 'infiniband-sdr', 'infiniband-ddr', 'infiniband-qdr', 'infiniband-fdr10', 'infiniband-fdr', 'infiniband-edr', 'infiniband-hdr', 'infiniband-ndr', 'infiniband-xdr', 't1', 'e1', 't3', 'e3', 'xdsl', 'docsis', 'gpon', 'xg-pon', 'xgs-pon', 'ng-pon2', 'epon', '10g-epon', 'cisco-stackwise', 'cisco-stackwise-plus', 'cisco-flexstack', 'cisco-flexstack-plus', 'cisco-stackwise-80', 'cisco-stackwise-160', 'cisco-stackwise-320', 'cisco-stackwise-480', 'juniper-vcp', 'extreme-summitstack', 'extreme-summitstack-128', 'extreme-summitstack-256', 'extreme-summitstack-512', 'other', IgnoreCase = $true)]
        [string]$Type,

        [uint16]$MTU,

        [string]$MAC_Address,

        [bool]$MGMT_Only,

        [uint64]$LAG,

        [string]$Description,

        [ValidateSet('Access', 'Tagged', 'Tagged All', '100', '200', '300', IgnoreCase = $true)]
        [string]$Mode,

        [ValidateRange(1, 4094)]
        [uint16]$Untagged_VLAN,

        [ValidateRange(1, 4094)]
        [uint16[]]$Tagged_VLANs,

        [switch]$Force
    )

    begin {
        if (-not [System.String]::IsNullOrWhiteSpace($Mode)) {
            $PSBoundParameters.Mode = switch ($Mode) {
                'Access' {
                    100
                    break
                }

                'Tagged' {
                    200
                    break
                }

                'Tagged All' {
                    300
                    break
                }

                default {
                    $_
                }
            }
        }
    }

    process {
        foreach ($InterfaceId in $Id) {
            $CurrentInterface = Get-NetboxDCIMInterface -Id $InterfaceId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('dcim', 'interfaces', $CurrentInterface.Id))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id'

            $URI = BuildNewURI -Segments $Segments

            if ($Force -or $pscmdlet.ShouldProcess("Interface ID $($CurrentInterface.Id)", "Set")) {
                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH
            }
        }
    }

    end {

    }
}

#endregion

#region File Set-NetboxDCIMInterfaceConnection.ps1


function Set-NetboxDCIMInterfaceConnection {
<#
    .SYNOPSIS
        Update an interface connection

    .DESCRIPTION
        Update an interface connection

    .PARAMETER Id
        A description of the Id parameter.

    .PARAMETER Connection_Status
        A description of the Connection_Status parameter.

    .PARAMETER Interface_A
        A description of the Interface_A parameter.

    .PARAMETER Interface_B
        A description of the Interface_B parameter.

    .PARAMETER Force
        A description of the Force parameter.

    .EXAMPLE
        PS C:\> Set-NetboxDCIMInterfaceConnection -Id $value1

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(ConfirmImpact = 'Medium',
                   SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [object]$Connection_Status,

        [uint64]$Interface_A,

        [uint64]$Interface_B,

        [switch]$Force
    )

    begin {
        if ((@($ID).Count -gt 1) -and ($Interface_A -or $Interface_B)) {
            throw "Cannot set multiple connections to the same interface"
        }
    }

    process {
        foreach ($ConnectionID in $Id) {
            $CurrentConnection = Get-NetboxDCIMInterfaceConnection -Id $ConnectionID -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('dcim', 'interface-connections', $CurrentConnection.Id))

            if ($Force -or $pscmdlet.ShouldProcess("Connection ID $($CurrentConnection.Id)", "Set")) {

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH
            }
        }
    }

    end {

    }
}

#endregion

#region File Set-NetboxDCIMLocation.ps1

function Set-NetboxDCIMLocation {
<#
    .SYNOPSIS
        Update a location in Netbox

    .DESCRIPTION
        Updates an existing location object in Netbox.

    .PARAMETER Id
        The ID of the location to update (required)

    .PARAMETER Name
        The name of the location

    .PARAMETER Slug
        The URL-friendly slug

    .PARAMETER Site
        The site ID where the location exists

    .PARAMETER Parent
        The parent location ID for nested locations

    .PARAMETER Status
        The operational status (planned, staging, active, decommissioning, retired)

    .PARAMETER Tenant
        The tenant ID that owns this location

    .PARAMETER Facility
        The facility identifier

    .PARAMETER Description
        A description of the location

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Set-NetboxDCIMLocation -Id 1 -Name "Server Room A"

        Updates the name of location 1

    .EXAMPLE
        Set-NetboxDCIMLocation -Id 1 -Status retired

        Marks location 1 as retired
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [uint64]$Site,

        [uint64]$Parent,

        [ValidateSet('planned', 'staging', 'active', 'decommissioning', 'retired')]
        [string]$Status,

        [uint64]$Tenant,

        [string]$Facility,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'locations', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update location')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NetboxDCIMManufacturer.ps1

function Set-NetboxDCIMManufacturer {
<#
    .SYNOPSIS
        Update a manufacturer in Netbox

    .DESCRIPTION
        Updates an existing manufacturer object in Netbox.

    .PARAMETER Id
        The ID of the manufacturer to update

    .PARAMETER Name
        The name of the manufacturer

    .PARAMETER Slug
        The URL-friendly slug

    .PARAMETER Description
        A description of the manufacturer

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Force
        Skip confirmation prompts

    .EXAMPLE
        Set-NetboxDCIMManufacturer -Id 1 -Description "Updated description"

    .EXAMPLE
        Get-NetboxDCIMManufacturer -Name "Cisco" | Set-NetboxDCIMManufacturer -Description "Network equipment"
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Name,

        [string]$Slug,

        [string]$Description,

        [hashtable]$Custom_Fields,

        [switch]$Force
    )

    process {
        foreach ($ManufacturerId in $Id) {
            $CurrentManufacturer = Get-NetboxDCIMManufacturer -Id $ManufacturerId -ErrorAction Stop

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentManufacturer.Name)", "Update manufacturer")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'manufacturers', $CurrentManufacturer.Id))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH
            }
        }
    }
}

#endregion

#region File Set-NetboxDCIMRack.ps1

function Set-NetboxDCIMRack {
<#
    .SYNOPSIS
        Update a rack in Netbox

    .DESCRIPTION
        Updates an existing rack object in Netbox.

    .PARAMETER Id
        The ID of the rack to update

    .PARAMETER Name
        The name of the rack

    .PARAMETER Site
        The site ID where the rack is located

    .PARAMETER Location
        The location ID within the site

    .PARAMETER Tenant
        The tenant ID that owns this rack

    .PARAMETER Status
        The operational status (active, planned, reserved, deprecated)

    .PARAMETER Role
        The rack role ID

    .PARAMETER Serial
        The serial number

    .PARAMETER Asset_Tag
        The asset tag

    .PARAMETER Rack_Type
        The rack type ID

    .PARAMETER Width
        The rack width (10 or 19 inches)

    .PARAMETER U_Height
        The height in rack units

    .PARAMETER Starting_Unit
        The starting unit number

    .PARAMETER Desc_Units
        Whether units are numbered top-to-bottom

    .PARAMETER Outer_Width
        The outer width in millimeters

    .PARAMETER Outer_Depth
        The outer depth in millimeters

    .PARAMETER Outer_Height
        The outer height in millimeters

    .PARAMETER Mounting_Depth
        The mounting depth in millimeters

    .PARAMETER Max_Weight
        The maximum weight capacity

    .PARAMETER Weight_Unit
        The weight unit (kg, g, lb, oz)

    .PARAMETER Facility_Id
        The facility identifier

    .PARAMETER Description
        A description of the rack

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Force
        Skip confirmation prompts

    .EXAMPLE
        Set-NetboxDCIMRack -Id 1 -Description "Updated description"

    .EXAMPLE
        Get-NetboxDCIMRack -Name "Rack-01" | Set-NetboxDCIMRack -Status deprecated
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Name,

        [uint64]$Site,

        [uint64]$Location,

        [uint64]$Tenant,

        [ValidateSet('active', 'planned', 'reserved', 'deprecated')]
        [string]$Status,

        [uint64]$Role,

        [string]$Serial,

        [string]$Asset_Tag,

        [uint64]$Rack_Type,

        [ValidateSet(10, 19, 21, 23)]
        [uint16]$Width,

        [ValidateRange(1, 100)]
        [uint16]$U_Height,

        [ValidateRange(1, 100)]
        [uint16]$Starting_Unit,

        [bool]$Desc_Units,

        [uint16]$Outer_Width,

        [uint16]$Outer_Depth,

        [uint16]$Outer_Height,

        [uint16]$Mounting_Depth,

        [uint32]$Max_Weight,

        [ValidateSet('kg', 'g', 'lb', 'oz')]
        [string]$Weight_Unit,

        [string]$Facility_Id,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Force
    )

    process {
        foreach ($RackId in $Id) {
            $CurrentRack = Get-NetboxDCIMRack -Id $RackId -ErrorAction Stop

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentRack.Name)", "Update rack")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'racks', $CurrentRack.Id))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH
            }
        }
    }
}

#endregion

#region File Set-NetboxDCIMRearPort.ps1


function Set-NetboxDCIMRearPort {
    [CmdletBinding(ConfirmImpact = 'Medium',
                   SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [uint64]$Device,

        [uint64]$Module,

        [string]$Name,

        [string]$Label,

        [string]$Type,

        [ValidatePattern('^[0-9a-f]{6}$')]
        [string]$Color,

        [uint16]$Positions,

        [string]$Description,

        [bool]$Mark_Connected,

        [uint16[]]$Tags,

        [switch]$Force
    )

    begin {

    }

    process {
        foreach ($RearPortID in $Id) {
            $CurrentPort = Get-NetboxDCIMRearPort -Id $RearPortID -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('dcim', 'rear-ports', $CurrentPort.Id))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id'

            $URI = BuildNewURI -Segments $Segments

            if ($Force -or $pscmdlet.ShouldProcess("Rear Port ID $($CurrentPort.Id)", "Set")) {
                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH
            }
        }
    }

    end {

    }
}

#endregion

#region File Set-NetboxDCIMRegion.ps1

function Set-NetboxDCIMRegion {
<#
    .SYNOPSIS
        Update a region in Netbox

    .DESCRIPTION
        Updates an existing region object in Netbox.

    .PARAMETER Id
        The ID of the region to update (required)

    .PARAMETER Name
        The name of the region

    .PARAMETER Slug
        The URL-friendly slug

    .PARAMETER Parent
        The parent region ID for nested regions

    .PARAMETER Description
        A description of the region

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Set-NetboxDCIMRegion -Id 1 -Name "Western Europe"

        Updates the name of region 1

    .EXAMPLE
        Set-NetboxDCIMRegion -Id 1 -Description "Western European countries"

        Updates the description of region 1
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [uint64]$Parent,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'regions', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update region')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NetboxDCIMSite.ps1

function Set-NetboxDCIMSite {
<#
    .SYNOPSIS
        Update a site in Netbox

    .DESCRIPTION
        Updates an existing site with the provided parameters.

    .PARAMETER Id
        The ID of the site to update

    .PARAMETER Name
        The name of the site

    .PARAMETER Slug
        The URL-friendly slug for the site

    .PARAMETER Status
        The operational status of the site (active, planned, staging, decommissioning, retired)

    .PARAMETER Region
        The region ID this site belongs to

    .PARAMETER Group
        The site group ID this site belongs to

    .PARAMETER Tenant
        The tenant ID that owns this site

    .PARAMETER Facility
        The facility identifier

    .PARAMETER Time_Zone
        The time zone for this site

    .PARAMETER Description
        A description of the site

    .PARAMETER Physical_Address
        The physical address of the site

    .PARAMETER Shipping_Address
        The shipping address for the site

    .PARAMETER Latitude
        The latitude coordinate

    .PARAMETER Longitude
        The longitude coordinate

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields and values

    .PARAMETER Force
        Skip confirmation prompts

    .EXAMPLE
        Set-NetboxDCIMSite -Id 1 -Description "Updated description"

    .EXAMPLE
        Get-NetboxDCIMSite -Name "Site1" | Set-NetboxDCIMSite -Status planned
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Name,

        [string]$Slug,

        [ValidateSet('active', 'planned', 'staging', 'decommissioning', 'retired')]
        [string]$Status,

        [uint64]$Region,

        [uint64]$Group,

        [uint64]$Tenant,

        [string]$Facility,

        [string]$Time_Zone,

        [string]$Description,

        [string]$Physical_Address,

        [string]$Shipping_Address,

        [double]$Latitude,

        [double]$Longitude,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Force
    )

    process {
        foreach ($SiteID in $Id) {
            $CurrentSite = Get-NetboxDCIMSite -Id $SiteID -ErrorAction Stop

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentSite.Name)", "Update site")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'sites', $CurrentSite.Id))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH
            }
        }
    }
}

#endregion

#region File Set-NetboxDCIMSiteGroup.ps1

function Set-NetboxDCIMSiteGroup {
<#
    .SYNOPSIS
        Update a site group in Netbox

    .DESCRIPTION
        Updates an existing site group object in Netbox.

    .PARAMETER Id
        The ID of the site group to update (required)

    .PARAMETER Name
        The name of the site group

    .PARAMETER Slug
        The URL-friendly slug

    .PARAMETER Parent
        The parent site group ID for nested groups

    .PARAMETER Description
        A description of the site group

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Set-NetboxDCIMSiteGroup -Id 1 -Name "Production Sites"

        Updates the name of site group 1

    .EXAMPLE
        Set-NetboxDCIMSiteGroup -Id 1 -Description "All production sites"

        Updates the description of site group 1
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [uint64]$Parent,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'site-groups', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update site group')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NetboxHostName.ps1

function Set-NetboxHostName {
    [CmdletBinding(ConfirmImpact = 'Low',
        SupportsShouldProcess = $true)]
    [OutputType([string])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Hostname
    )

    if ($PSCmdlet.ShouldProcess('Netbox Hostname', 'Set')) {
        $script:NetboxConfig.Hostname = $Hostname.Trim()
        $script:NetboxConfig.Hostname
    }
}

#endregion

#region File Set-NetboxHostPort.ps1

function Set-NetboxHostPort {
    [CmdletBinding(ConfirmImpact = 'Low',
                   SupportsShouldProcess = $true)]
    [OutputType([string])]
    param
    (
        [Parameter(Mandatory = $true)]
        [uint16]$Port
    )

    if ($PSCmdlet.ShouldProcess('Netbox Port', 'Set')) {
        $script:NetboxConfig.HostPort = $Port
        $script:NetboxConfig.HostPort
    }
}

#endregion

#region File Set-NetboxHostScheme.ps1

function Set-NetboxHostScheme {
    [CmdletBinding(ConfirmImpact = 'Low',
                   SupportsShouldProcess = $true)]
    [OutputType([string])]
    param
    (
        [Parameter(Mandatory = $false)]
        [ValidateSet('https', 'http', IgnoreCase = $true)]
        [string]$Scheme = 'https'
    )

    if ($PSCmdlet.ShouldProcess('Netbox Host Scheme', 'Set')) {
        if ($Scheme -eq 'http') {
            Write-Warning "Connecting via non-secure HTTP is not-recommended"
        }

        $script:NetboxConfig.HostScheme = $Scheme
        $script:NetboxConfig.HostScheme
    }
}

#endregion

#region File Set-NetboxInvokeParams.ps1

function Set-NetboxInvokeParams {
    [CmdletBinding(ConfirmImpact = 'Low',
        SupportsShouldProcess = $true)]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [array]$InvokeParams
    )

    if ($PSCmdlet.ShouldProcess('Netbox Invoke Params', 'Set')) {
        $script:NetboxConfig.InvokeParams = $InvokeParams
        $script:NetboxConfig.InvokeParams
    }
}

#endregion

#region File Set-NetboxIPAMAddress.ps1


function Set-NetboxIPAMAddress {
    [CmdletBinding(ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Address,

        [string]$Status,

        [uint64]$Tenant,

        [uint64]$VRF,

        [object]$Role,

        [uint64]$NAT_Inside,

        [hashtable]$Custom_Fields,

        [ValidateSet('dcim.interface', 'virtualization.vminterface', IgnoreCase = $true)]
        [string]$Assigned_Object_Type,

        [uint64]$Assigned_Object_Id,

        [string]$Description,

        [string]$Dns_name,

        [switch]$Force
    )

    begin {
        #        Write-Verbose "Validating enum properties"
        #        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-addresses', 0))
        $Method = 'PATCH'
        #
        #        # Value validation
        #        $ModelDefinition = GetModelDefinitionFromURIPath -Segments $Segments -Method $Method
        #        $EnumProperties = GetModelEnumProperties -ModelDefinition $ModelDefinition
        #
        #        foreach ($Property in $EnumProperties.Keys) {
        #            if ($PSBoundParameters.ContainsKey($Property)) {
        #                Write-Verbose "Validating property [$Property] with value [$($PSBoundParameters.$Property)]"
        #                $PSBoundParameters.$Property = ValidateValue -ModelDefinition $ModelDefinition -Property $Property -ProvidedValue $PSBoundParameters.$Property
        #            } else {
        #                Write-Verbose "User did not provide a value for [$Property]"
        #            }
        #        }
        #
        #        Write-Verbose "Finished enum validation"
    }

    process {
        foreach ($IPId in $Id) {
            if ($PSBoundParameters.ContainsKey('Assigned_Object_Type') -or $PSBoundParameters.ContainsKey('Assigned_Object_Id')) {
                if ((-not [string]::IsNullOrWhiteSpace($Assigned_Object_Id)) -and [string]::IsNullOrWhiteSpace($Assigned_Object_Type)) {
                    throw "Assigned_Object_Type is required when specifying Assigned_Object_Id"
                }
                elseif ((-not [string]::IsNullOrWhiteSpace($Assigned_Object_Type)) -and [string]::IsNullOrWhiteSpace($Assigned_Object_Id)) {
                    throw "Assigned_Object_Id is required when specifying Assigned_Object_Type"
                }
            }

            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-addresses', $IPId))

            Write-Verbose "Obtaining IP from ID $IPId"
            $CurrentIP = Get-NetboxIPAMAddress -Id $IPId -ErrorAction Stop

            if ($Force -or $PSCmdlet.ShouldProcess($CurrentIP.Address, 'Set')) {
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method $Method
            }
        }
    }
}

#endregion

#region File Set-NetboxIPAMAddressRange.ps1


function Set-NetboxIPAMAddressRange {
    [CmdletBinding(ConfirmImpact = 'Medium',
                   SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Start_Address,

        [string]$End_Address,

        [object]$Status,

        [uint64]$Tenant,

        [uint64]$VRF,

        [object]$Role,

        [hashtable]$Custom_Fields,

        [string]$Description,

        [string]$Comments,

        [object[]]$Tags,

        [switch]$Mark_Utilized,

        [switch]$Force,

        [switch]$Raw
    )

    begin {
        $Method = 'PATCH'
    }

    process {
        foreach ($RangeID in $Id) {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-ranges', $RangeID))

            Write-Verbose "Obtaining IP range from ID $RangeID"
            $CurrentRange = Get-NetboxIPAMAddressRange -Id $RangeID -ErrorAction Stop

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentRange.Start_Address) - $($CurrentRange.End_Address)", 'Set')) {
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method $Method
            }
        }
    }
}

#endregion

#region File Set-NetboxIPAMASN.ps1

function Set-NetboxIPAMASN {
<#
    .SYNOPSIS
        Update an ASN in Netbox

    .DESCRIPTION
        Updates an existing ASN (Autonomous System Number) object in Netbox.

    .PARAMETER Id
        The ID of the ASN to update (required)

    .PARAMETER ASN
        The ASN number

    .PARAMETER RIR
        The RIR (Regional Internet Registry) ID

    .PARAMETER Tenant
        The tenant ID

    .PARAMETER Description
        A description of the ASN

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Set-NetboxIPAMASN -Id 1 -Description "Updated description"

        Updates the description of ASN 1
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [ValidateRange(1, 4294967295)]
        [uint64]$ASN,

        [uint64]$RIR,

        [uint64]$Tenant,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'asns', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update ASN')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NetboxIPAMASNRange.ps1

function Set-NetboxIPAMASNRange {
<#
    .SYNOPSIS
        Update an ASN range in Netbox

    .DESCRIPTION
        Updates an existing ASN range object in Netbox.

    .PARAMETER Id
        The ID of the ASN range to update (required)

    .PARAMETER Name
        The name of the ASN range

    .PARAMETER Slug
        The URL-friendly slug

    .PARAMETER RIR
        The RIR (Regional Internet Registry) ID

    .PARAMETER Start
        The starting ASN number

    .PARAMETER End
        The ending ASN number

    .PARAMETER Tenant
        The tenant ID

    .PARAMETER Description
        A description of the ASN range

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Set-NetboxIPAMASNRange -Id 1 -Description "Updated description"

        Updates the description of ASN range 1
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [uint64]$RIR,

        [ValidateRange(1, 4294967295)]
        [uint64]$Start,

        [ValidateRange(1, 4294967295)]
        [uint64]$End,

        [uint64]$Tenant,

        [string]$Description,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'asn-ranges', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update ASN range')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NetboxIPAMPrefix.ps1


function Set-NetboxIPAMPrefix {
    [CmdletBinding(ConfirmImpact = 'Medium',
                   SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Prefix,

        [string]$Status,

        [uint64]$Tenant,

        [uint64]$Site,

        [uint64]$VRF,

        [uint64]$VLAN,

        [object]$Role,

        [hashtable]$Custom_Fields,

        [string]$Description,

        [switch]$Is_Pool,

        [switch]$Force
    )

    begin {
        #        Write-Verbose "Validating enum properties"
        #        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-addresses', 0))
        $Method = 'PATCH'
        #
        #        # Value validation
        #        $ModelDefinition = GetModelDefinitionFromURIPath -Segments $Segments -Method $Method
        #        $EnumProperties = GetModelEnumProperties -ModelDefinition $ModelDefinition
        #
        #        foreach ($Property in $EnumProperties.Keys) {
        #            if ($PSBoundParameters.ContainsKey($Property)) {
        #                Write-Verbose "Validating property [$Property] with value [$($PSBoundParameters.$Property)]"
        #                $PSBoundParameters.$Property = ValidateValue -ModelDefinition $ModelDefinition -Property $Property -ProvidedValue $PSBoundParameters.$Property
        #            } else {
        #                Write-Verbose "User did not provide a value for [$Property]"
        #            }
        #        }
        #
        #        Write-Verbose "Finished enum validation"
    }

    process {
        foreach ($PrefixId in $Id) {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'prefixes', $PrefixId))

            Write-Verbose "Obtaining Prefix from ID $PrefixId"
            $CurrentPrefix = Get-NetboxIPAMPrefix -Id $PrefixId -ErrorAction Stop

            if ($Force -or $PSCmdlet.ShouldProcess($CurrentPrefix.Prefix, 'Set')) {
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method $Method
            }
        }
    }
}









#endregion

#region File Set-NetboxIPAMRouteTarget.ps1

function Set-NetboxIPAMRouteTarget {
<#
    .SYNOPSIS
        Update a route target in Netbox

    .DESCRIPTION
        Updates an existing route target object in Netbox.

    .PARAMETER Id
        The ID of the route target to update (required)

    .PARAMETER Name
        The route target value (RFC 4360 format)

    .PARAMETER Tenant
        The tenant ID that owns this route target

    .PARAMETER Description
        A description of the route target

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Set-NetboxIPAMRouteTarget -Id 1 -Description "Updated description"

        Updates the description of route target 1

    .EXAMPLE
        Set-NetboxIPAMRouteTarget -Id 1 -Tenant 5

        Assigns route target 1 to tenant 5
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [uint64]$Tenant,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'route-targets', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update route target')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NetboxIPAMService.ps1

function Set-NetboxIPAMService {
<#
    .SYNOPSIS
        Update a service in Netbox

    .DESCRIPTION
        Updates an existing service object in Netbox.

    .PARAMETER Id
        The ID of the service to update (required)

    .PARAMETER Name
        The name of the service

    .PARAMETER Ports
        Array of port numbers

    .PARAMETER Protocol
        The protocol (tcp, udp, sctp)

    .PARAMETER IPAddresses
        Array of IP address IDs associated with this service

    .PARAMETER Description
        A description of the service

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Set-NetboxIPAMService -Id 1 -Ports @(443, 8443)

        Updates service 1 to listen on ports 443 and 8443
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [uint16[]]$Ports,

        [ValidateSet('tcp', 'udp', 'sctp')]
        [string]$Protocol,

        [uint64[]]$IPAddresses,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'services', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update service')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NetboxIPAMServiceTemplate.ps1

function Set-NetboxIPAMServiceTemplate {
<#
    .SYNOPSIS
        Update a service template in Netbox

    .DESCRIPTION
        Updates an existing service template object in Netbox.

    .PARAMETER Id
        The ID of the service template to update (required)

    .PARAMETER Name
        The name of the service template

    .PARAMETER Ports
        Array of port numbers

    .PARAMETER Protocol
        The protocol (tcp, udp, sctp)

    .PARAMETER Description
        A description of the service template

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Set-NetboxIPAMServiceTemplate -Id 1 -Ports @(80, 443, 8080)

        Updates service template 1 with new ports
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [uint16[]]$Ports,

        [ValidateSet('tcp', 'udp', 'sctp')]
        [string]$Protocol,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'service-templates', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update service template')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NetboxIPAMVRF.ps1

function Set-NetboxIPAMVRF {
<#
    .SYNOPSIS
        Update a VRF in Netbox

    .DESCRIPTION
        Updates an existing VRF (Virtual Routing and Forwarding) object in Netbox.

    .PARAMETER Id
        The ID of the VRF to update (required)

    .PARAMETER Name
        The name of the VRF

    .PARAMETER RD
        The route distinguisher (RFC 4364 format)

    .PARAMETER Tenant
        The tenant ID that owns this VRF

    .PARAMETER Enforce_Unique
        Prevent duplicate prefixes/IP addresses within this VRF

    .PARAMETER Description
        A description of the VRF

    .PARAMETER Comments
        Additional comments

    .PARAMETER Import_Targets
        Array of route target IDs for import

    .PARAMETER Export_Targets
        Array of route target IDs for export

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Set-NetboxIPAMVRF -Id 1 -Name "Production-VRF"

        Updates the name of VRF 1

    .EXAMPLE
        Set-NetboxIPAMVRF -Id 1 -Enforce_Unique $true

        Enables unique enforcement for VRF 1
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$RD,

        [uint64]$Tenant,

        [bool]$Enforce_Unique,

        [string]$Description,

        [string]$Comments,

        [uint64[]]$Import_Targets,

        [uint64[]]$Export_Targets,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'vrfs', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update VRF')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NetboxTimeout.ps1


function Set-NetboxTimeout {
    [CmdletBinding(ConfirmImpact = 'Low',
                   SupportsShouldProcess = $true)]
    [OutputType([uint16])]
    param
    (
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 65535)]
        [uint16]$TimeoutSeconds = 30
    )

    if ($PSCmdlet.ShouldProcess('Netbox Timeout', 'Set')) {
        $script:NetboxConfig.Timeout = $TimeoutSeconds
        $script:NetboxConfig.Timeout
    }
}

#endregion

#region File Set-NetboxUnstrustedSSL.ps1

Function Set-NetboxUntrustedSSL {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessforStateChangingFunctions", "")]
    Param(  )
    # Hack for allowing untrusted SSL certs with https connections
    Add-Type -TypeDefinition @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@

    [System.Net.ServicePointManager]::CertificatePolicy = New-Object -TypeName TrustAllCertsPolicy

}

#endregion

#region File Set-NetboxVirtualMachine.ps1


function Set-NetboxVirtualMachine {
    [CmdletBinding(ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [uint64]$Role,

        [uint64]$Cluster,

        [object]$Status,

        [uint64]$Platform,

        [uint64]$Primary_IP4,

        [uint64]$Primary_IP6,

        [byte]$VCPUs,

        [uint64]$Memory,

        [uint64]$Disk,

        [uint64]$Tenant,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Force
    )

    #    if ($null -ne $Status) {
    #        $PSBoundParameters.Status = ValidateVirtualizationChoice -ProvidedValue $Status -VirtualMachineStatus
    #    }

    process {
        $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'virtual-machines', $Id))

        Write-Verbose "Obtaining VM from ID $Id"

        #$CurrentVM = Get-NetboxVirtualMachine -Id $Id -ErrorAction Stop

        Write-Verbose "Finished obtaining VM"

        if ($Force -or $pscmdlet.ShouldProcess($ID, "Set properties on VM ID")) {
            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force'

            $URI = BuildNewURI -Segments $URIComponents.Segments

            InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH
        }
    }
}

#endregion

#region File Set-NetboxVirtualMachineInterface.ps1


function Set-NetboxVirtualMachineInterface {
    [CmdletBinding(ConfirmImpact = 'Medium',
                   SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Name,

        [string]$MAC_Address,

        [uint16]$MTU,

        [string]$Description,

        [boolean]$Enabled,

        [uint64]$Virtual_Machine,

        [switch]$Force
    )

    begin {

    }

    process {
        foreach ($VMI_ID in $Id) {
            Write-Verbose "Obtaining VM Interface..."
            $CurrentVMI = Get-NetboxVirtualMachineInterface -Id $VMI_ID -ErrorAction Stop
            Write-Verbose "Finished obtaining VM Interface"

            $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'interfaces', $CurrentVMI.Id))

            if ($Force -or $pscmdlet.ShouldProcess("Interface $($CurrentVMI.Id) on VM $($CurrentVMI.Virtual_Machine.Name)", "Set")) {
                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH
            }
        }
    }

    end {

    }
}

#endregion

#region File Set-NetboxVPNIKEPolicy.ps1

function Set-NetboxVPNIKEPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,[uint16]$Version,[string]$Mode,[uint64[]]$Proposals,[string]$Preshared_Key,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','ike-policies',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update IKE policy')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File Set-NetboxVPNIKEProposal.ps1

function Set-NetboxVPNIKEProposal {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[string]$Name,
        [string]$Authentication_Method,[string]$Encryption_Algorithm,[string]$Authentication_Algorithm,[uint16]$Group,[uint32]$SA_Lifetime,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','ike-proposals',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update IKE proposal')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File Set-NetboxVPNIPSecPolicy.ps1

function Set-NetboxVPNIPSecPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[string]$Name,[uint64[]]$Proposals,[bool]$Pfs_Group,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-policies',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update IPSec policy')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File Set-NetboxVPNIPSecProfile.ps1

function Set-NetboxVPNIPSecProfile {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[string]$Name,[string]$Mode,[uint64]$IKE_Policy,[uint64]$IPSec_Policy,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-profiles',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update IPSec profile')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File Set-NetboxVPNIPSecProposal.ps1

function Set-NetboxVPNIPSecProposal {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[string]$Name,[string]$Encryption_Algorithm,[string]$Authentication_Algorithm,[uint32]$SA_Lifetime_Seconds,[uint32]$SA_Lifetime_Data,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-proposals',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update IPSec proposal')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File Set-NetboxVPNL2VPN.ps1

function Set-NetboxVPNL2VPN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,[string]$Slug,[uint64]$Identifier,[string]$Type,[string]$Status,[uint64]$Tenant,
        [string]$Description,[string]$Comments,[uint64[]]$Import_Targets,[uint64[]]$Export_Targets,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','l2vpns',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update L2VPN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File Set-NetboxVPNL2VPNTermination.ps1

function Set-NetboxVPNL2VPNTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[uint64]$L2VPN,[string]$Assigned_Object_Type,[uint64]$Assigned_Object_Id,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','l2vpn-terminations',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update L2VPN termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File Set-NetboxVPNTunnel.ps1

function Set-NetboxVPNTunnel {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,
        [ValidateSet('active', 'planned', 'disabled')][string]$Status,
        [ValidateSet('ipsec-transport', 'ipsec-tunnel', 'ip-ip', 'gre')][string]$Encapsulation,
        [uint64]$Group,
        [uint64]$IPSec_Profile,
        [uint64]$Tenant,
        [string]$Description,
        [string]$Comments,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('vpn', 'tunnels', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments
        if ($PSCmdlet.ShouldProcess($Id, 'Update VPN tunnel')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NetboxVPNTunnelGroup.ps1

function Set-NetboxVPNTunnelGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[string]$Name,[string]$Slug,[string]$Description,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','tunnel-groups',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update tunnel group')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File Set-NetboxVPNTunnelTermination.ps1

function Set-NetboxVPNTunnelTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[uint64]$Tunnel,[ValidateSet('peer', 'hub', 'spoke')][string]$Role,[string]$Termination_Type,[uint64]$Termination_Id,[uint64]$Outside_IP,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','tunnel-terminations',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update tunnel termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File Set-NetboxWirelessLAN.ps1

function Set-NetboxWirelessLAN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[string]$SSID,[uint64]$Group,[string]$Status,[uint64]$VLAN,[uint64]$Tenant,
        [string]$Auth_Type,[string]$Auth_Cipher,[string]$Auth_PSK,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('wireless','wireless-lans',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update wireless LAN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File Set-NetboxWirelessLANGroup.ps1

function Set-NetboxWirelessLANGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[string]$Name,[string]$Slug,[uint64]$Parent,[string]$Description,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('wireless','wireless-lan-groups',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update wireless LAN group')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File Set-NetboxWirelessLink.ps1

function Set-NetboxWirelessLink {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[uint64]$Interface_A,[uint64]$Interface_B,
        [string]$SSID,[string]$Status,[uint64]$Tenant,[string]$Auth_Type,[string]$Auth_Cipher,[string]$Auth_PSK,
        [string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('wireless','wireless-links',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update wireless link')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File SetupNetboxConfigVariable.ps1

function SetupNetboxConfigVariable {
    [CmdletBinding()]
    param
    (
        [switch]$Overwrite
    )

    Write-Verbose "Checking for NetboxConfig hashtable"
    if ((-not ($script:NetboxConfig)) -or $Overwrite) {
        Write-Verbose "Creating NetboxConfig hashtable"
        $script:NetboxConfig = @{
            'Connected'     = $false
            'Choices'       = @{
            }
            'APIDefinition' = $null
            'ContentTypes' = $null
        }
    }

    Write-Verbose "NetboxConfig hashtable already exists"
}

#endregion

#region File Test-NetboxAPIConnected.ps1


function Test-NetboxAPIConnected {
    [CmdletBinding()]
    param ()

    $script:NetboxConfig.Connected
}

#endregion

#region File ThrowNetboxRESTError.ps1


function ThrowNetboxRESTError {
    $uriSegments = [System.Collections.ArrayList]::new(@('fake', 'url'))

    $URIParameters = @{
    }

    $uri = BuildNewURI -Segments $uriSegments -Parameters $URIParameters

    InvokeNetboxRequest -URI $uri -Raw
}

#endregion

#region File VerifyAPIConnectivity.ps1

function VerifyAPIConnectivity {
    [CmdletBinding()]
    param ()

    $uriSegments = [System.Collections.ArrayList]::new(@('extras'))

    $uri = BuildNewURI -Segments $uriSegments -Parameters @{'format' = 'json' } -SkipConnectedCheck

    InvokeNetboxRequest -URI $uri
}

#endregion

# Build a list of common parameters so we can omit them to build URI parameters
$script:CommonParameterNames = New-Object System.Collections.ArrayList
[void]$script:CommonParameterNames.AddRange(@([System.Management.Automation.PSCmdlet]::CommonParameters))
[void]$script:CommonParameterNames.AddRange(@([System.Management.Automation.PSCmdlet]::OptionalCommonParameters))
[void]$script:CommonParameterNames.Add('Raw')

SetupNetboxConfigVariable
