

#region File Aliases.ps1

# Backwards compatibility aliases for renamed functions
# These aliases maintain compatibility with scripts using the old Add-* naming convention

Set-Alias -Name Add-NBDCIMInterface -Value New-NBDCIMInterface
Set-Alias -Name Add-NBDCIMInterfaceConnection -Value New-NBDCIMInterfaceConnection
Set-Alias -Name Add-NBDCIMFrontPort -Value New-NBDCIMFrontPort
Set-Alias -Name Add-NBDCIMRearPort -Value New-NBDCIMRearPort
Set-Alias -Name Add-NBVirtualMachineInterface -Value New-NBVirtualMachineInterface

# Export aliases
Export-ModuleMember -Alias Add-NBDCIMInterface, Add-NBDCIMInterfaceConnection, Add-NBDCIMFrontPort, Add-NBDCIMRearPort, Add-NBVirtualMachineInterface

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
        # Build query string without System.Web dependency (cross-platform)
        $QueryParts = [System.Collections.Generic.List[string]]::new()

        foreach ($param in $Parameters.GetEnumerator()) {
            Write-Verbose " Adding URI parameter $($param.Key):$($param.Value)"
            # URL encode key and value using .NET Uri class (available everywhere)
            $EncodedKey = [System.Uri]::EscapeDataString($param.Key)
            $EncodedValue = [System.Uri]::EscapeDataString([string]$param.Value)
            $QueryParts.Add("$EncodedKey=$EncodedValue")
        }

        $uriBuilder.Query = $QueryParts -join '&'
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
        throw "Not connected to a Netbox API! Please run 'Connect-NBAPI'"
    }
}

#endregion

#region File Clear-NBCredential.ps1

<#
.SYNOPSIS
    Manages redential in Netbox C module.

.DESCRIPTION
    Manages redential in Netbox C module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Clear-NBCredential

    Returns all redential objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Clear-NBCredential {
    [CmdletBinding(ConfirmImpact = 'Medium', SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param
    (
        [switch]$Force
    )

    if ($Force -or ($PSCmdlet.ShouldProcess('Netbox Credentials', 'Clear'))) {
        $script:NetboxConfig.Credential = $null
    }
}

#endregion

#region File Connect-NBAPI.ps1

function Connect-NBAPI {
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
        PS C:\> Connect-NBAPI -Hostname "netbox.domain.com"

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
            $Credential = Get-NBCredential -ErrorAction Stop
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

    # For PowerShell Desktop (5.1), configure TLS and certificate handling
    if ("Desktop" -eq $PSVersionTable.PsEdition) {
        # Enable modern TLS protocols
        Set-NBCipherSSL
        if ($SkipCertificateCheck) {
            # Disable SSL certificate validation
            Set-NBuntrustedSSL
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

    $null = Set-NBHostName -Hostname $uriBuilder.Host
    $null = Set-NBCredential -Credential $Credential
    $null = Set-NBHostScheme -Scheme $uriBuilder.Scheme
    $null = Set-NBHostPort -Port $uriBuilder.Port
    $null = Set-NBInvokeParams -invokeParams $invokeParams
    $null = Set-NBTimeout -TimeoutSeconds $TimeoutSeconds

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
#    $script:NetboxConfig.APIDefinition = Get-NBAPIDefinition
#
#    if ([version]$script:NetboxConfig.APIDefinition.info.version -lt 2.8) {
#        $Script:NetboxConfig.Connected = $false
#        throw "Netbox version is incompatible with this PS module. Requires >=2.8.*, found version $($script:NetboxConfig.APIDefinition.info.version)"
    #    }

    Write-Verbose "Checking Netbox version compatibility"
    $script:NetboxConfig.NetboxVersion = Get-NBVersion
    if ([version]$script:NetboxConfig.NetboxVersion.'netbox-version' -lt 2.8) {
        $Script:NetboxConfig.Connected = $false
        throw "Netbox version is incompatible with this PS module. Requires >=2.8.*, found version $($script:NetboxConfig.NetboxVersion.'netbox-version')"
    } else {
        Write-Verbose "Found compatible version [$($script:NetboxConfig.NetboxVersion.'netbox-version')]!"
    }

    $script:NetboxConfig.Connected = $true
    Write-Verbose "Successfully connected!"

    $script:NetboxConfig.ContentTypes = Get-NBContentType -Limit 500

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

#region File Get-NBAPIDefinition.ps1

<#
.SYNOPSIS
    Retrieves Support objects from Netbox Setup module.

.DESCRIPTION
    Retrieves Support objects from Netbox Setup module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBAPIDefinition

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBAPIDefinition {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
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

#region File Get-NBBookmark.ps1

<#
.SYNOPSIS
    Retrieves bookmarks from Netbox.

.DESCRIPTION
    Retrieves bookmarks from Netbox Extras module.

.PARAMETER Id
    Database ID of the bookmark.

.PARAMETER Object_Type
    Filter by object type.

.PARAMETER Object_Id
    Filter by object ID.

.PARAMETER User_Id
    Filter by user ID.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBBookmark

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBBookmark {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Object_Type,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Object_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$User_Id,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('extras', 'bookmarks', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('extras', 'bookmarks'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBCircuit.ps1


function Get-NBCircuit {
    <#
    .SYNOPSIS
        Gets one or more circuits

    .DESCRIPTION
        A detailed description of the Get-NBCircuit function.

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
        PS C:\> Get-NBCircuit

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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
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

#region File Get-NBCircuitGroup.ps1

<#
.SYNOPSIS
    Retrieves circuit groups from Netbox.

.DESCRIPTION
    Retrieves circuit groups from Netbox Circuits module.

.PARAMETER Id
    Database ID of the circuit group.

.PARAMETER Name
    Filter by name.

.PARAMETER Slug
    Filter by slug.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBCircuitGroup

.EXAMPLE
    Get-NBCircuitGroup -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBCircuitGroup {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-groups', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-groups'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBCircuitGroupAssignment.ps1

<#
.SYNOPSIS
    Retrieves circuit group assignments from Netbox.

.DESCRIPTION
    Retrieves circuit group assignments from Netbox Circuits module.

.PARAMETER Id
    Database ID of the assignment.

.PARAMETER Group_Id
    Filter by circuit group ID.

.PARAMETER Circuit_Id
    Filter by circuit ID.

.PARAMETER Priority
    Filter by priority.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBCircuitGroupAssignment

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBCircuitGroupAssignment {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Group_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Circuit_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Priority,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-group-assignments', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-group-assignments'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBCircuitProvider.ps1

<#
.SYNOPSIS
    Retrieves Providers objects from Netbox Circuits module.

.DESCRIPTION
    Retrieves Providers objects from Netbox Circuits module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBCircuitProvider

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBCircuitProvider {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ParameterSetName = 'ById',
                   Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
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
}

#endregion

#region File Get-NBCircuitProviderAccount.ps1

<#
.SYNOPSIS
    Retrieves provider accounts from Netbox.

.DESCRIPTION
    Retrieves provider accounts from Netbox Circuits module.

.PARAMETER Id
    Database ID of the provider account.

.PARAMETER Name
    Filter by name.

.PARAMETER Provider_Id
    Filter by provider ID.

.PARAMETER Account
    Filter by account number.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBCircuitProviderAccount

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBCircuitProviderAccount {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Provider_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Account,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('circuits', 'provider-accounts', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('circuits', 'provider-accounts'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBCircuitProviderNetwork.ps1

<#
.SYNOPSIS
    Retrieves provider networks from Netbox.

.DESCRIPTION
    Retrieves provider networks from Netbox Circuits module.

.PARAMETER Id
    Database ID of the provider network.

.PARAMETER Name
    Filter by name.

.PARAMETER Provider_Id
    Filter by provider ID.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBCircuitProviderNetwork

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBCircuitProviderNetwork {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Provider_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('circuits', 'provider-networks', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('circuits', 'provider-networks'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBCircuitTermination.ps1

<#
.SYNOPSIS
    Retrieves Terminations objects from Netbox Circuits module.

.DESCRIPTION
    Retrieves Terminations objects from Netbox Circuits module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBCircuitTermination

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBCircuitTermination {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
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

#region File Get-NBCircuitType.ps1

<#
.SYNOPSIS
    Retrieves Types objects from Netbox Circuits module.

.DESCRIPTION
    Retrieves Types objects from Netbox Circuits module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBCircuitType

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBCircuitType {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
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
}

#endregion

#region File Get-NBConfigContext.ps1

<#
.SYNOPSIS
    Retrieves config contexts from Netbox.

.DESCRIPTION
    Retrieves config contexts from Netbox Extras module.

.PARAMETER Id
    Database ID of the config context.

.PARAMETER Name
    Filter by name.

.PARAMETER Is_Active
    Filter by active status.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBConfigContext

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBConfigContext {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Is_Active,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('extras', 'config-contexts', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('extras', 'config-contexts'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBContact.ps1


function Get-NBContact {
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
        PS C:\> Get-NBContact

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param
    (
        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [string]$Name,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
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
}

#endregion

#region File Get-NBContactAssignment.ps1


function Get-NBContactAssignment {
<#
    .SYNOPSIS
        Get a contact Assignment from Netbox

    .DESCRIPTION
        A detailed description of the Get-NBContactAssignment function.

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
        PS C:\> Get-NBContactAssignment

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param
    (
        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [string]$Name,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
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
}

#endregion

#region File Get-NBContactRole.ps1


function Get-NBContactRole {
<#
    .SYNOPSIS
        Get a contact role from Netbox

    .DESCRIPTION
        A detailed description of the Get-NBContactRole function.

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
        PS C:\> Get-NBContactRole

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param
    (
        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [string]$Name,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Description,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
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
}

#endregion

#region File Get-NBContentType.ps1

function Get-NBContentType {
<#
    .SYNOPSIS
        Get a content type definition from Netbox

    .DESCRIPTION
        A detailed description of the Get-NBContentType function.

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
        PS C:\> Get-NBContentType

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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
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

#region File Get-NBCredential.ps1

<#
.SYNOPSIS
    Retrieves Get-NBCredential.ps1 objects from Netbox Setup module.

.DESCRIPTION
    Retrieves Get-NBCredential.ps1 objects from Netbox Setup module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBCredential

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBCredential {
    [CmdletBinding()]
    [OutputType([pscredential])]
    param ()

    if (-not $script:NetboxConfig.Credential) {
        throw "Netbox Credentials not set! You may set with Set-NBCredential"
    }

    $script:NetboxConfig.Credential
}

#endregion

#region File Get-NBCustomField.ps1

<#
.SYNOPSIS
    Retrieves custom fields from Netbox.

.DESCRIPTION
    Retrieves custom fields from Netbox Extras module.

.PARAMETER Id
    Database ID of the custom field.

.PARAMETER Name
    Filter by name.

.PARAMETER Type
    Filter by field type.

.PARAMETER Content_Types
    Filter by content types.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBCustomField

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBCustomField {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Type,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Content_Types,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-fields', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-fields'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBCustomFieldChoiceSet.ps1

<#
.SYNOPSIS
    Retrieves custom field choice sets from Netbox.

.DESCRIPTION
    Retrieves custom field choice sets from Netbox Extras module.

.PARAMETER Id
    Database ID of the choice set.

.PARAMETER Name
    Filter by name.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBCustomFieldChoiceSet

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBCustomFieldChoiceSet {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-field-choice-sets', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-field-choice-sets'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBCustomLink.ps1

<#
.SYNOPSIS
    Retrieves custom links from Netbox.

.DESCRIPTION
    Retrieves custom links from Netbox Extras module.

.PARAMETER Id
    Database ID of the custom link.

.PARAMETER Name
    Filter by name.

.PARAMETER Enabled
    Filter by enabled status.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBCustomLink

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBCustomLink {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Enabled,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-links', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-links'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDataFile.ps1

<#
.SYNOPSIS
    Retrieves data files from Netbox.

.DESCRIPTION
    Retrieves data files from Netbox Core module.

.PARAMETER Id
    Database ID of the data file.

.PARAMETER Source_Id
    Filter by data source ID.

.PARAMETER Path
    Filter by file path.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBDataFile

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDataFile {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Source_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Path,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('core', 'data-files', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('core', 'data-files'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDataSource.ps1

<#
.SYNOPSIS
    Retrieves data sources from Netbox.

.DESCRIPTION
    Retrieves data sources from Netbox Core module.

.PARAMETER Id
    Database ID of the data source.

.PARAMETER Name
    Filter by name.

.PARAMETER Type
    Filter by type (local, git, amazon-s3).

.PARAMETER Enabled
    Filter by enabled status.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBDataSource

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDataSource {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('local', 'git', 'amazon-s3')]
        [string]$Type,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Enabled,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('core', 'data-sources', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('core', 'data-sources'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMCable.ps1

<#
.SYNOPSIS
    Retrieves Cables objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Cables objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMCable

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMCable {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    #region Parameters
    param
    (
        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
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

#region File Get-NBDCIMCableTermination.ps1

<#
.SYNOPSIS
    Retrieves Cable Terminations objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Cable Terminations objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMCableTermination

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMCableTermination {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    #region Parameters
    param
    (
        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
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

#region File Get-NBDCIMConnectedDevice.ps1

<#
.SYNOPSIS
    Retrieves Connected Device objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Connected Device objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMConnectedDevice

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMConnectedDevice {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Peer_Device,
        [Parameter(Mandatory = $true)][string]$Peer_Interface,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','connected-device'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
    }
}

#endregion

#region File Get-NBDCIMConsolePort.ps1

<#
.SYNOPSIS
    Retrieves Console Ports objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Console Ports objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMConsolePort

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMConsolePort {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][uint64]$Device_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Module_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Type,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','console-ports',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','console-ports'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMConsolePortTemplate.ps1

<#
.SYNOPSIS
    Retrieves Console Port Templates objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Console Port Templates objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMConsolePortTemplate

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMConsolePortTemplate {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][uint64]$DeviceType_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$ModuleType_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Type,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','console-port-templates',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','console-port-templates'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMConsoleServerPort.ps1

<#
.SYNOPSIS
    Retrieves Console Server Ports objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Console Server Ports objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMConsoleServerPort

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMConsoleServerPort {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][uint64]$Device_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Module_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Type,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','console-server-ports',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','console-server-ports'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMConsoleServerPortTemplate.ps1

<#
.SYNOPSIS
    Retrieves Console Server Port Templates objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Console Server Port Templates objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMConsoleServerPortTemplate

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMConsoleServerPortTemplate {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][uint64]$DeviceType_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$ModuleType_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Type,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','console-server-port-templates',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','console-server-port-templates'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMDevice.ps1

<#
.SYNOPSIS
    Retrieves Devices objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Devices objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMDevice

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMDevice {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    #region Parameters
    param
    (
        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
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

#region File Get-NBDCIMDeviceBay.ps1

<#
.SYNOPSIS
    Retrieves Device Bays objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Device Bays objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMDeviceBay

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMDeviceBay {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][uint64]$Device_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','device-bays',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','device-bays'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMDeviceBayTemplate.ps1

<#
.SYNOPSIS
    Retrieves Device Bay Templates objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Device Bay Templates objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMDeviceBayTemplate

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMDeviceBayTemplate {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][uint64]$DeviceType_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','device-bay-templates',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','device-bay-templates'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMDeviceRole.ps1

<#
.SYNOPSIS
    Retrieves Devices objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Devices objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMDeviceRole

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMDeviceRole {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Name,

        [string]$Slug,

        [string]$Color,

        [bool]$VM_Role,

        [switch]$Raw
    )

    process {
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
}

#endregion

#region File Get-NBDCIMDeviceType.ps1

<#
.SYNOPSIS
    Retrieves Devices objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Devices objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMDeviceType

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMDeviceType {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    #region Parameters
    param
    (
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
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

    process {
        #endregion Parameters

        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'device-types'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $URI -Raw:$Raw
    }
}

#endregion

#region File Get-NBDCIMFrontPort.ps1

<#
.SYNOPSIS
    Retrieves Front Ports objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Front Ports objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMFrontPort

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMFrontPort {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
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

#region File Get-NBDCIMFrontPortTemplate.ps1

<#
.SYNOPSIS
    Retrieves Front Port Templates objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Front Port Templates objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMFrontPortTemplate

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMFrontPortTemplate {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][uint64]$DeviceType_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$ModuleType_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Type,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','front-port-templates',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','front-port-templates'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMInterface.ps1

<#
.SYNOPSIS
    Retrieves Interfaces objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Interfaces objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMInterface

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMInterface {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
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

#region File Get-NBDCIMInterfaceConnection.ps1

<#
.SYNOPSIS
    Retrieves Interfaces objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Interfaces objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMInterfaceConnection

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMInterfaceConnection {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [uint64]$Id,

        [object]$Connection_Status,

        [uint64]$Site,

        [uint64]$Device,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'interface-connections'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $URI -Raw:$Raw
    }
}

#endregion

#region File Get-NBDCIMInterfaceTemplate.ps1

<#
.SYNOPSIS
    Retrieves Interface Templates objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Interface Templates objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMInterfaceTemplate

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMInterfaceTemplate {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][uint64]$DeviceType_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$ModuleType_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Type,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','interface-templates',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','interface-templates'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMInventoryItem.ps1

<#
.SYNOPSIS
    Retrieves Inventory Items objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Inventory Items objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMInventoryItem

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMInventoryItem {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][uint64]$Device_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Parent_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Manufacturer_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Serial,
        [Parameter(ParameterSetName = 'Query')][string]$Asset_Tag,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','inventory-items',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','inventory-items'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMInventoryItemRole.ps1

<#
.SYNOPSIS
    Retrieves Inventory Item Roles objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Inventory Item Roles objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMInventoryItemRole

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMInventoryItemRole {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][string]$Slug,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','inventory-item-roles',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','inventory-item-roles'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMInventoryItemTemplate.ps1

<#
.SYNOPSIS
    Retrieves Inventory Item Templates objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Inventory Item Templates objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMInventoryItemTemplate

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMInventoryItemTemplate {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][uint64]$DeviceType_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Parent_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','inventory-item-templates',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','inventory-item-templates'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMLocation.ps1

function Get-NBDCIMLocation {
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
        Get-NBDCIMLocation

        Returns all locations

    .EXAMPLE
        Get-NBDCIMLocation -Site_Id 1

        Returns all locations at site with ID 1

    .EXAMPLE
        Get-NBDCIMLocation -Name "Server Room"

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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
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

#region File Get-NBDCIMMACAddress.ps1

<#
.SYNOPSIS
    Retrieves MACAddresses objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves MACAddresses objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMMACAddress

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMMACAddress {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Mac_Address,
        [Parameter(ParameterSetName = 'Query')][uint64]$Assigned_Object_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Assigned_Object_Type,
        [Parameter(ParameterSetName = 'Query')][uint64]$Device_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Virtual_Machine_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','mac-addresses',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','mac-addresses'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMManufacturer.ps1

function Get-NBDCIMManufacturer {
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
        Get-NBDCIMManufacturer

        Returns all manufacturers

    .EXAMPLE
        Get-NBDCIMManufacturer -Name "Cisco"

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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
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

#region File Get-NBDCIMModule.ps1

<#
.SYNOPSIS
    Retrieves Modules objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Modules objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMModule

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMModule {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Device_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Module_Bay_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Module_Type_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Serial,
        [Parameter(ParameterSetName = 'Query')][string]$Asset_Tag,
        [Parameter(ParameterSetName = 'Query')][string]$Status,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','modules',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','modules'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMModuleBay.ps1

<#
.SYNOPSIS
    Retrieves Module Bays objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Module Bays objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMModuleBay

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMModuleBay {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][uint64]$Device_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','module-bays',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','module-bays'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMModuleBayTemplate.ps1

<#
.SYNOPSIS
    Retrieves Module Bay Templates objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Module Bay Templates objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMModuleBayTemplate

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMModuleBayTemplate {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][uint64]$DeviceType_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','module-bay-templates',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','module-bay-templates'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMModuleType.ps1

<#
.SYNOPSIS
    Retrieves Module Types objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Module Types objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMModuleType

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMModuleType {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Model,
        [Parameter(ParameterSetName = 'Query')][uint64]$Manufacturer_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Part_Number,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','module-types',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','module-types'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMModuleTypeProfile.ps1

<#
.SYNOPSIS
    Retrieves Module Type Profiles objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Module Type Profiles objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMModuleTypeProfile

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMModuleTypeProfile {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','module-type-profiles',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','module-type-profiles'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMPlatform.ps1

<#
.SYNOPSIS
    Retrieves Platforms objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Platforms objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMPlatform

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMPlatform {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Name,

        [string]$Slug,

        [uint64]$Manufacturer_Id,

        [string]$Manufacturer,

        [switch]$Raw
    )

    process {
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
}

#endregion

#region File Get-NBDCIMPowerFeed.ps1

<#
.SYNOPSIS
    Retrieves Power Feeds objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Power Feeds objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMPowerFeed

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMPowerFeed {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][uint64]$Power_Panel_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Rack_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Status,
        [Parameter(ParameterSetName = 'Query')][string]$Type,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','power-feeds',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','power-feeds'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMPowerOutlet.ps1

<#
.SYNOPSIS
    Retrieves Power Outlets objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Power Outlets objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMPowerOutlet

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMPowerOutlet {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][uint64]$Device_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Module_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Type,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','power-outlets',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','power-outlets'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMPowerOutletTemplate.ps1

<#
.SYNOPSIS
    Retrieves Power Outlet Templates objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Power Outlet Templates objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMPowerOutletTemplate

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMPowerOutletTemplate {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][uint64]$DeviceType_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$ModuleType_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Type,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','power-outlet-templates',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','power-outlet-templates'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMPowerPanel.ps1

<#
.SYNOPSIS
    Retrieves Power Panels objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Power Panels objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMPowerPanel

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMPowerPanel {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][uint64]$Site_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Location_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','power-panels',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','power-panels'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMPowerPort.ps1

<#
.SYNOPSIS
    Retrieves Power Ports objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Power Ports objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMPowerPort

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMPowerPort {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][uint64]$Device_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Module_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Type,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','power-ports',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','power-ports'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMPowerPortTemplate.ps1

<#
.SYNOPSIS
    Retrieves Power Port Templates objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Power Port Templates objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMPowerPortTemplate

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMPowerPortTemplate {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][uint64]$DeviceType_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$ModuleType_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Type,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','power-port-templates',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','power-port-templates'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMRack.ps1

function Get-NBDCIMRack {
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
        Get-NBDCIMRack

        Returns all racks

    .EXAMPLE
        Get-NBDCIMRack -Site_Id 1

        Returns all racks at site with ID 1

    .EXAMPLE
        Get-NBDCIMRack -Name "Rack-01"

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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
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

#region File Get-NBDCIMRackReservation.ps1

<#
.SYNOPSIS
    Retrieves Rack Reservations objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Rack Reservations objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMRackReservation

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMRackReservation {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Rack_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Site_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$User_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Tenant_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','rack-reservations',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','rack-reservations'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMRackRole.ps1

<#
.SYNOPSIS
    Retrieves Rack Roles objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Rack Roles objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMRackRole

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMRackRole {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][string]$Slug,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','rack-roles',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','rack-roles'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMRackType.ps1

<#
.SYNOPSIS
    Retrieves Rack Types objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Rack Types objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMRackType

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMRackType {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Model,
        [Parameter(ParameterSetName = 'Query')][string]$Slug,
        [Parameter(ParameterSetName = 'Query')][uint64]$Manufacturer_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','rack-types',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','rack-types'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMRearPort.ps1

<#
.SYNOPSIS
    Retrieves Rear Ports objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Rear Ports objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMRearPort

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMRearPort {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
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

#region File Get-NBDCIMRearPortTemplate.ps1

<#
.SYNOPSIS
    Retrieves Rear Port Templates objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Rear Port Templates objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMRearPortTemplate

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMRearPortTemplate {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][uint64]$DeviceType_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$ModuleType_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Type,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','rear-port-templates',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','rear-port-templates'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMRegion.ps1

function Get-NBDCIMRegion {
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
        Get-NBDCIMRegion

        Returns all regions

    .EXAMPLE
        Get-NBDCIMRegion -Name "Europe"

        Returns regions matching the name "Europe"

    .EXAMPLE
        Get-NBDCIMRegion -Parent_Id 1

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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
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

#region File Get-NBDCIMSite.ps1

<#
.SYNOPSIS
    Retrieves Sites objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Sites objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMSite

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMSite {
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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
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

#region File Get-NBDCIMSiteGroup.ps1

function Get-NBDCIMSiteGroup {
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
        Get-NBDCIMSiteGroup

        Returns all site groups

    .EXAMPLE
        Get-NBDCIMSiteGroup -Name "Production"

        Returns site groups matching the name "Production"

    .EXAMPLE
        Get-NBDCIMSiteGroup -Parent_Id 1

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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
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

#region File Get-NBDCIMVirtualChassis.ps1

<#
.SYNOPSIS
    Retrieves Virtual Chassis objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Virtual Chassis objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMVirtualChassis

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMVirtualChassis {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][string]$Domain,
        [Parameter(ParameterSetName = 'Query')][uint64]$Master_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Site_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Region_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Tenant_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','virtual-chassis',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','virtual-chassis'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBDCIMVirtualDeviceContext.ps1

<#
.SYNOPSIS
    Retrieves Virtual Device Contexts objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Virtual Device Contexts objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMVirtualDeviceContext

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMVirtualDeviceContext {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][string]$Status,
        [Parameter(ParameterSetName = 'Query')][uint64]$Device_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Tenant_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Primary_Ip4_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Primary_Ip6_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','virtual-device-contexts',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','virtual-device-contexts'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBEventRule.ps1

<#
.SYNOPSIS
    Retrieves event rules from Netbox.

.DESCRIPTION
    Retrieves event rules from Netbox Extras module.

.PARAMETER Id
    Database ID of the event rule.

.PARAMETER Name
    Filter by name.

.PARAMETER Enabled
    Filter by enabled status.

.PARAMETER Type_Create
    Filter by create event type.

.PARAMETER Type_Update
    Filter by update event type.

.PARAMETER Type_Delete
    Filter by delete event type.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBEventRule

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBEventRule {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Enabled,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Type_Create,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Type_Update,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Type_Delete,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('extras', 'event-rules', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('extras', 'event-rules'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBExportTemplate.ps1

<#
.SYNOPSIS
    Retrieves export templates from Netbox.

.DESCRIPTION
    Retrieves export templates from Netbox Extras module.

.PARAMETER Id
    Database ID of the export template.

.PARAMETER Name
    Filter by name.

.PARAMETER Object_Types
    Filter by object types.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBExportTemplate

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBExportTemplate {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Object_Types,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('extras', 'export-templates', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('extras', 'export-templates'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBGroup.ps1

<#
.SYNOPSIS
    Retrieves groups from Netbox.

.DESCRIPTION
    Retrieves groups from Netbox Users module.

.PARAMETER Id
    Database ID of the group.

.PARAMETER Name
    Filter by name.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBGroup

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBGroup {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('users', 'groups', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('users', 'groups'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBHostname.ps1

<#
.SYNOPSIS
    Retrieves Get-NBHostname.ps1 objects from Netbox Setup module.

.DESCRIPTION
    Retrieves Get-NBHostname.ps1 objects from Netbox Setup module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBHostname

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBHostname {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    Write-Verbose "Getting Netbox hostname"
    if ($null -eq $script:NetboxConfig.Hostname) {
        throw "Netbox Hostname is not set! You may set it with Set-NBHostname -Hostname 'hostname.domain.tld'"
    }

    $script:NetboxConfig.Hostname
}

#endregion

#region File Get-NBHostPort.ps1

<#
.SYNOPSIS
    Retrieves Get-NBHost Port.ps1 objects from Netbox Setup module.

.DESCRIPTION
    Retrieves Get-NBHost Port.ps1 objects from Netbox Setup module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBHostPort

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBHostPort {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    Write-Verbose "Getting Netbox host port"
    if ($null -eq $script:NetboxConfig.HostPort) {
        throw "Netbox host port is not set! You may set it with Set-NBHostPort -Port 'https'"
    }

    $script:NetboxConfig.HostPort
}

#endregion

#region File Get-NBHostScheme.ps1

<#
.SYNOPSIS
    Retrieves Get-NBHost Scheme.ps1 objects from Netbox Setup module.

.DESCRIPTION
    Retrieves Get-NBHost Scheme.ps1 objects from Netbox Setup module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBHostScheme

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBHostScheme {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    Write-Verbose "Getting Netbox host scheme"
    if ($null -eq $script:NetboxConfig.Hostscheme) {
        throw "Netbox host sceme is not set! You may set it with Set-NBHostScheme -Scheme 'https'"
    }

    $script:NetboxConfig.HostScheme
}

#endregion

#region File Get-NBImageAttachment.ps1

<#
.SYNOPSIS
    Retrieves image attachments from Netbox.

.DESCRIPTION
    Retrieves image attachments from Netbox Extras module.

.PARAMETER Id
    Database ID of the image attachment.

.PARAMETER Object_Type
    Filter by object type.

.PARAMETER Object_Id
    Filter by object ID.

.PARAMETER Name
    Filter by name.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBImageAttachment

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBImageAttachment {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Object_Type,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Object_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('extras', 'image-attachments', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('extras', 'image-attachments'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBInvokeParams.ps1

<#
.SYNOPSIS
    Retrieves Get-NBInvoke Params.ps1 objects from Netbox Setup module.

.DESCRIPTION
    Retrieves Get-NBInvoke Params.ps1 objects from Netbox Setup module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBInvokeParams

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBInvokeParams {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    Write-Verbose "Getting Netbox InvokeParams"
    if ($null -eq $script:NetboxConfig.InvokeParams) {
        throw "Netbox Invoke Params is not set! You may set it with Set-NBInvokeParams -InvokeParams ..."
    }

    $script:NetboxConfig.InvokeParams
}

#endregion

#region File Get-NBIPAMAddress.ps1

<#
.SYNOPSIS
    Retrieves Address objects from Netbox IPAM module.

.DESCRIPTION
    Retrieves Address objects from Netbox IPAM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBIPAMAddress

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBIPAMAddress {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ParameterSetName = 'Query',
            Position = 0)]
        [string]$Address,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
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
}

#endregion

#region File Get-NBIPAMAddressRange.ps1

<#
.SYNOPSIS
    Retrieves Range objects from Netbox IPAM module.

.DESCRIPTION
    Retrieves Range objects from Netbox IPAM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBIPAMAddressRange

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBIPAMAddressRange {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [string]$Range,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
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
}

#endregion

#region File Get-NBIPAMAggregate.ps1

<#
.SYNOPSIS
    Retrieves Aggregate objects from Netbox IPAM module.

.DESCRIPTION
    Retrieves Aggregate objects from Netbox IPAM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBIPAMAggregate

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBIPAMAggregate {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

process {
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
}

#endregion

#region File Get-NBIPAMASN.ps1

function Get-NBIPAMASN {
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
        Get-NBIPAMASN

        Returns all ASNs

    .EXAMPLE
        Get-NBIPAMASN -ASN 65001

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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
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

#region File Get-NBIPAMASNRange.ps1

function Get-NBIPAMASNRange {
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
        Get-NBIPAMASNRange

        Returns all ASN ranges

    .EXAMPLE
        Get-NBIPAMASNRange -Name "Private"

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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
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

#region File Get-NBIPAMAvailableIP.ps1


function Get-NBIPAMAvailableIP {
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
        Get-NBIPAMAvailableIP -Prefix_ID (Get-NBIPAMPrefix -Prefix 192.0.2.0/24).id

        Get (Next) Available IP on the Prefix 192.0.2.0/24

    .EXAMPLE
        Get-NBIPAMAvailableIP -Prefix_ID 2 -NumberOfIPs 3

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

#region File Get-NBIPAMFHRPGroup.ps1

<#
.SYNOPSIS
    Retrieves FHRPGroup objects from Netbox IPAM module.

.DESCRIPTION
    Retrieves FHRPGroup objects from Netbox IPAM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBIPAMFHRPGroup

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBIPAMFHRPGroup {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][string]$Protocol,
        [Parameter(ParameterSetName = 'Query')][uint16]$Group_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','fhrp-groups',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('ipam','fhrp-groups'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBIPAMFHRPGroupAssignment.ps1

<#
.SYNOPSIS
    Retrieves FHRPGroup Assignment objects from Netbox IPAM module.

.DESCRIPTION
    Retrieves FHRPGroup Assignment objects from Netbox IPAM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBIPAMFHRPGroupAssignment

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBIPAMFHRPGroupAssignment {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Group_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Interface_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Device_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Virtual_Machine_Id,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','fhrp-group-assignments',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('ipam','fhrp-group-assignments'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBIPAMPrefix.ps1


function Get-NBIPAMPrefix {
<#
    .SYNOPSIS
        A brief description of the Get-NBIPAMPrefix function.

    .DESCRIPTION
        A detailed description of the Get-NBIPAMPrefix function.

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
        PS C:\> Get-NBIPAMPrefix

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

        [Parameter(ParameterSetName = 'ByID',
                   ValueFromPipelineByPropertyName = $true)]
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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
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
}

#endregion

#region File Get-NBIPAMRIR.ps1

<#
.SYNOPSIS
    Retrieves RIR objects from Netbox IPAM module.

.DESCRIPTION
    Retrieves RIR objects from Netbox IPAM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBIPAMRIR

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBIPAMRIR {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][string]$Slug,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [Parameter(ParameterSetName = 'Query')][bool]$Is_Private,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','rirs',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('ipam','rirs'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBIPAMRole.ps1


function Get-NBIPAMRole {
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
        PS C:\> Get-NBIPAMRole

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

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [switch]$Brief,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
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
}

#endregion

#region File Get-NBIPAMRouteTarget.ps1

function Get-NBIPAMRouteTarget {
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
        Get-NBIPAMRouteTarget

        Returns all route targets

    .EXAMPLE
        Get-NBIPAMRouteTarget -Name "65001:100"

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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
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

#region File Get-NBIPAMService.ps1

function Get-NBIPAMService {
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
        Get-NBIPAMService

        Returns all services

    .EXAMPLE
        Get-NBIPAMService -Protocol tcp -Port 443

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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
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

#region File Get-NBIPAMServiceTemplate.ps1

function Get-NBIPAMServiceTemplate {
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
        Get-NBIPAMServiceTemplate

        Returns all service templates

    .EXAMPLE
        Get-NBIPAMServiceTemplate -Name "HTTP"

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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
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

#region File Get-NBIPAMVLAN.ps1

<#
.SYNOPSIS
    Retrieves VLAN objects from Netbox IPAM module.

.DESCRIPTION
    Retrieves VLAN objects from Netbox IPAM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBIPAMVLAN

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBIPAMVLAN {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [ValidateRange(1, 4096)]
        [uint16]$VID,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
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
}

#endregion

#region File Get-NBIPAMVLANGroup.ps1

<#
.SYNOPSIS
    Retrieves VLANGroup objects from Netbox IPAM module.

.DESCRIPTION
    Retrieves VLANGroup objects from Netbox IPAM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBIPAMVLANGroup

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBIPAMVLANGroup {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][string]$Slug,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [Parameter(ParameterSetName = 'Query')][uint64]$Site_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Site,
        [Parameter(ParameterSetName = 'Query')][uint64]$Location_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Rack_Id,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','vlan-groups',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('ipam','vlan-groups'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBIPAMVLANTranslationPolicy.ps1

<#
.SYNOPSIS
    Retrieves VLANTranslation Policy objects from Netbox IPAM module.

.DESCRIPTION
    Retrieves VLANTranslation Policy objects from Netbox IPAM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBIPAMVLANTranslationPolicy

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBIPAMVLANTranslationPolicy {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','vlan-translation-policies',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('ipam','vlan-translation-policies'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBIPAMVLANTranslationRule.ps1

<#
.SYNOPSIS
    Retrieves VLANTranslation Rule objects from Netbox IPAM module.

.DESCRIPTION
    Retrieves VLANTranslation Rule objects from Netbox IPAM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBIPAMVLANTranslationRule

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBIPAMVLANTranslationRule {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Policy_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Local_Vid,
        [Parameter(ParameterSetName = 'Query')][uint64]$Remote_Vid,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','vlan-translation-rules',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('ipam','vlan-translation-rules'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBIPAMVRF.ps1

function Get-NBIPAMVRF {
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
        Get-NBIPAMVRF

        Returns all VRFs

    .EXAMPLE
        Get-NBIPAMVRF -Name "Production"

        Returns VRFs matching the name "Production"

    .EXAMPLE
        Get-NBIPAMVRF -RD "65001:100"

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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
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

#region File Get-NBJob.ps1

<#
.SYNOPSIS
    Retrieves jobs from Netbox.

.DESCRIPTION
    Retrieves background jobs from Netbox Core module.

.PARAMETER Id
    Database ID of the job.

.PARAMETER Object_Type
    Filter by object type.

.PARAMETER Object_Id
    Filter by object ID.

.PARAMETER Name
    Filter by job name.

.PARAMETER Status
    Filter by status (pending, scheduled, running, completed, errored, failed).

.PARAMETER User_Id
    Filter by user ID.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBJob

.EXAMPLE
    Get-NBJob -Status "running"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBJob {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Object_Type,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Object_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('pending', 'scheduled', 'running', 'completed', 'errored', 'failed')]
        [string]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$User_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('core', 'jobs', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('core', 'jobs'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBJournalEntry.ps1

<#
.SYNOPSIS
    Retrieves journal entries from Netbox.

.DESCRIPTION
    Retrieves journal entries from Netbox Extras module.

.PARAMETER Id
    Database ID of the journal entry.

.PARAMETER Assigned_Object_Type
    Filter by assigned object type.

.PARAMETER Assigned_Object_Id
    Filter by assigned object ID.

.PARAMETER Created_By
    Filter by creator user ID.

.PARAMETER Kind
    Filter by kind (info, success, warning, danger).

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBJournalEntry

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBJournalEntry {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Assigned_Object_Type,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Assigned_Object_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Created_By,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('info', 'success', 'warning', 'danger')]
        [string]$Kind,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('extras', 'journal-entries', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('extras', 'journal-entries'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBObjectChange.ps1

<#
.SYNOPSIS
    Retrieves object changes from Netbox.

.DESCRIPTION
    Retrieves object change log entries from Netbox Core module.

.PARAMETER Id
    Database ID of the object change.

.PARAMETER User_Id
    Filter by user ID.

.PARAMETER User_Name
    Filter by username.

.PARAMETER Changed_Object_Type
    Filter by changed object type.

.PARAMETER Changed_Object_Id
    Filter by changed object ID.

.PARAMETER Action
    Filter by action (create, update, delete).

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBObjectChange

.EXAMPLE
    Get-NBObjectChange -Action "create" -Limit 50

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBObjectChange {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$User_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$User_Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Changed_Object_Type,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Changed_Object_Id,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('create', 'update', 'delete')]
        [string]$Action,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('core', 'object-changes', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('core', 'object-changes'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBObjectType.ps1

<#
.SYNOPSIS
    Retrieves object types from Netbox.

.DESCRIPTION
    Retrieves object types (content types) from Netbox Core module.

.PARAMETER Id
    Database ID of the object type.

.PARAMETER App_Label
    Filter by app label (e.g., "dcim", "ipam").

.PARAMETER Model
    Filter by model name (e.g., "device", "ipaddress").

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBObjectType

.EXAMPLE
    Get-NBObjectType -App_Label "dcim"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBObjectType {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$App_Label,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Model,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('core', 'object-types', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('core', 'object-types'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBPermission.ps1

<#
.SYNOPSIS
    Retrieves permissions from Netbox.

.DESCRIPTION
    Retrieves permissions from Netbox Users module.

.PARAMETER Id
    Database ID of the permission.

.PARAMETER Name
    Filter by name.

.PARAMETER Enabled
    Filter by enabled status.

.PARAMETER Object_Types
    Filter by object types.

.PARAMETER Group_Id
    Filter by group ID.

.PARAMETER User_Id
    Filter by user ID.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBPermission

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBPermission {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Enabled,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Object_Types,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Group_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$User_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('users', 'permissions', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('users', 'permissions'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBSavedFilter.ps1

<#
.SYNOPSIS
    Retrieves saved filters from Netbox.

.DESCRIPTION
    Retrieves saved filters from Netbox Extras module.

.PARAMETER Id
    Database ID of the saved filter.

.PARAMETER Name
    Filter by name.

.PARAMETER Slug
    Filter by slug.

.PARAMETER Object_Types
    Filter by object types.

.PARAMETER User_Id
    Filter by user ID.

.PARAMETER Enabled
    Filter by enabled status.

.PARAMETER Shared
    Filter by shared status.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBSavedFilter

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBSavedFilter {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Object_Types,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$User_Id,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Enabled,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Shared,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('extras', 'saved-filters', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('extras', 'saved-filters'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBTag.ps1

<#
.SYNOPSIS
    Retrieves Tags objects from Netbox Extras module.

.DESCRIPTION
    Retrieves Tags objects from Netbox Extras module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBTag

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBTag {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
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

#region File Get-NBTenant.ps1


function Get-NBTenant {
<#
    .SYNOPSIS
        Get a tenent from Netbox

    .DESCRIPTION
        A detailed description of the Get-NBTenant function.

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
        PS C:\> Get-NBTenant

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param
    (
        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [string]$Name,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
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
}

#endregion

#region File Get-NBTenantGroup.ps1

<#
.SYNOPSIS
    Retrieves tenant groups from Netbox.

.DESCRIPTION
    Retrieves tenant groups from the Netbox tenancy module.
    Tenant groups are organizational containers for grouping related tenants.

.PARAMETER Id
    Database ID(s) of the tenant group to retrieve. Accepts pipeline input.

.PARAMETER Name
    Filter by tenant group name.

.PARAMETER Slug
    Filter by tenant group slug.

.PARAMETER Description
    Filter by description.

.PARAMETER Parent_Id
    Filter by parent tenant group ID.

.PARAMETER Query
    General search query.

.PARAMETER Limit
    Maximum number of results to return (1-1000).

.PARAMETER Offset
    Number of results to skip for pagination.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBTenantGroup

    Returns all tenant groups.

.EXAMPLE
    Get-NBTenantGroup -Name "Enterprise*"

    Returns tenant groups matching the name pattern.

.EXAMPLE
    Get-NBTenantGroup -Id 1

    Returns the tenant group with ID 1.

.LINK
    https://netbox.readthedocs.io/en/stable/models/tenancy/tenantgroup/
#>
function Get-NBTenantGroup {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Name,

        [string]$Slug,

        [string]$Description,

        [uint64]$Parent_Id,

        [Alias('q')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'tenant-groups'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $URI -Raw:$Raw
    }
}

#endregion

#region File Get-NBTimeout.ps1

<#
.SYNOPSIS
    Retrieves Get-NBTimeout.ps1 objects from Netbox Setup module.

.DESCRIPTION
    Retrieves Get-NBTimeout.ps1 objects from Netbox Setup module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBTimeout

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBTimeout {
    [CmdletBinding()]
    [OutputType([uint16])]
    param ()

    Write-Verbose "Getting Netbox Timeout"
    if ($null -eq $script:NetboxConfig.Timeout) {
        throw "Netbox Timeout is not set! You may set it with Set-NBTimeout -TimeoutSeconds [uint16]"
    }

    $script:NetboxConfig.Timeout
}

#endregion

#region File Get-NBToken.ps1

<#
.SYNOPSIS
    Retrieves API tokens from Netbox.

.DESCRIPTION
    Retrieves API tokens from Netbox Users module.

.PARAMETER Id
    Database ID of the token.

.PARAMETER User_Id
    Filter by user ID.

.PARAMETER Key
    Filter by token key.

.PARAMETER Write_Enabled
    Filter by write enabled status.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBToken

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBToken {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$User_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Key,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Write_Enabled,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('users', 'tokens', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('users', 'tokens'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBUser.ps1

<#
.SYNOPSIS
    Retrieves users from Netbox.

.DESCRIPTION
    Retrieves users from Netbox Users module.

.PARAMETER Id
    Database ID of the user.

.PARAMETER Username
    Filter by username.

.PARAMETER First_Name
    Filter by first name.

.PARAMETER Last_Name
    Filter by last name.

.PARAMETER Email
    Filter by email.

.PARAMETER Is_Staff
    Filter by staff status.

.PARAMETER Is_Active
    Filter by active status.

.PARAMETER Is_Superuser
    Filter by superuser status.

.PARAMETER Group_Id
    Filter by group ID.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBUser

.EXAMPLE
    Get-NBUser -Username "admin"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBUser {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Username,

        [Parameter(ParameterSetName = 'Query')]
        [string]$First_Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Last_Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Email,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Is_Staff,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Is_Active,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Is_Superuser,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Group_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('users', 'users', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('users', 'users'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBVersion.ps1

<#
.SYNOPSIS
    Retrieves Get-NBVersion.ps1 objects from Netbox Setup module.

.DESCRIPTION
    Retrieves Get-NBVersion.ps1 objects from Netbox Setup module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBVersion

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBVersion {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    $Segments = [System.Collections.ArrayList]::new(@('status'))

    $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary @{
        'format' = 'json'
    }

    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters -SkipConnectedCheck

    InvokeNetboxRequest -URI $URI
}

#endregion

#region File Get-NBVirtualCircuit.ps1

<#
.SYNOPSIS
    Retrieves virtual circuits from Netbox.

.DESCRIPTION
    Retrieves virtual circuits from Netbox Circuits module.

.PARAMETER Id
    Database ID of the virtual circuit.

.PARAMETER Cid
    Circuit ID string.

.PARAMETER Name
    Filter by name.

.PARAMETER Provider_Id
    Filter by provider ID.

.PARAMETER Provider_Network_Id
    Filter by provider network ID.

.PARAMETER Type_Id
    Filter by type ID.

.PARAMETER Tenant_Id
    Filter by tenant ID.

.PARAMETER Status
    Filter by status.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBVirtualCircuit

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBVirtualCircuit {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Cid,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Provider_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Provider_Network_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Type_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('circuits', 'virtual-circuits', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('circuits', 'virtual-circuits'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBVirtualCircuitTermination.ps1

<#
.SYNOPSIS
    Retrieves virtual circuit terminations from Netbox.

.DESCRIPTION
    Retrieves virtual circuit terminations from Netbox Circuits module.

.PARAMETER Id
    Database ID of the termination.

.PARAMETER Virtual_Circuit_Id
    Filter by virtual circuit ID.

.PARAMETER Interface_Id
    Filter by interface ID.

.PARAMETER Role
    Filter by role (peer, hub, spoke).

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBVirtualCircuitTermination

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBVirtualCircuitTermination {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Virtual_Circuit_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Interface_Id,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('peer', 'hub', 'spoke')]
        [string]$Role,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('circuits', 'virtual-circuit-terminations', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('circuits', 'virtual-circuit-terminations'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBVirtualCircuitType.ps1

<#
.SYNOPSIS
    Retrieves virtual circuit types from Netbox.

.DESCRIPTION
    Retrieves virtual circuit types from Netbox Circuits module.

.PARAMETER Id
    Database ID of the virtual circuit type.

.PARAMETER Name
    Filter by name.

.PARAMETER Slug
    Filter by slug.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBVirtualCircuitType

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBVirtualCircuitType {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('circuits', 'virtual-circuit-types', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('circuits', 'virtual-circuit-types'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBVirtualizationCluster.ps1


function Get-NBVirtualizationCluster {
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
        PS C:\> Get-NBVirtualizationCluster

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding()]
    param
    (
        [string]$Name,

        [Alias('q')]
        [string]$Query,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Group,

        [uint64]$Group_Id,

        [string]$Type,

        [uint64]$Type_Id,

        [string]$Site,

        [uint64]$Site_Id,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'clusters'))

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

        $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $uri -Raw:$Raw
    }
}

#endregion

#region File Get-NBVirtualizationClusterGroup.ps1

<#
.SYNOPSIS
    Retrieves Virtualization Cluster objects from Netbox Virtualization module.

.DESCRIPTION
    Retrieves Virtualization Cluster objects from Netbox Virtualization module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBVirtualizationClusterGroup

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBVirtualizationClusterGroup {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [string]$Name,

        [string]$Slug,

        [string]$Description,

        [string]$Query,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'cluster-groups'))

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

        $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $uri -Raw:$Raw
    }
}

#endregion

#region File Get-NBVirtualizationClusterType.ps1

<#
.SYNOPSIS
    Retrieves virtualization cluster types from Netbox.

.DESCRIPTION
    Retrieves cluster types from the Netbox virtualization module.
    Cluster types define the virtualization technology (e.g., VMware vSphere, KVM, Hyper-V).

.PARAMETER Id
    Database ID(s) of the cluster type to retrieve. Accepts pipeline input.

.PARAMETER Name
    Filter by cluster type name.

.PARAMETER Slug
    Filter by cluster type slug.

.PARAMETER Description
    Filter by description.

.PARAMETER Query
    General search query.

.PARAMETER Limit
    Maximum number of results to return (1-1000).

.PARAMETER Offset
    Number of results to skip for pagination.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBVirtualizationClusterType

    Returns all cluster types.

.EXAMPLE
    Get-NBVirtualizationClusterType -Name "VMware*"

    Returns cluster types matching the name pattern.

.EXAMPLE
    Get-NBVirtualizationClusterType -Id 1

    Returns the cluster type with ID 1.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/clustertype/
#>
function Get-NBVirtualizationClusterType {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Name,

        [string]$Slug,

        [string]$Description,

        [Alias('q')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'cluster-types'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $URI -Raw:$Raw
    }
}

#endregion

#region File Get-NBVirtualMachine.ps1


function Get-NBVirtualMachine {
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
        PS C:\> Get-NBVirtualMachine

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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
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

#region File Get-NBVirtualMachineInterface.ps1


function Get-NBVirtualMachineInterface {
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
        PS C:\> Get-NBVirtualMachineInterface

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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
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

#region File Get-NBVPNIKEPolicy.ps1

<#
.SYNOPSIS
    Retrieves IKEPolicy objects from Netbox VPN module.

.DESCRIPTION
    Retrieves IKEPolicy objects from Netbox VPN module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBVPNIKEPolicy

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBVPNIKEPolicy {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,[ValidateRange(1, 1000)]
        [uint16]$Limit,[ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ike-policies',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('vpn','ike-policies')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}

#endregion

#region File Get-NBVPNIKEProposal.ps1

<#
.SYNOPSIS
    Retrieves IKEProposal objects from Netbox VPN module.

.DESCRIPTION
    Retrieves IKEProposal objects from Netbox VPN module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBVPNIKEProposal

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBVPNIKEProposal {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,[ValidateRange(1, 1000)]
        [uint16]$Limit,[ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ike-proposals',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('vpn','ike-proposals')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}

#endregion

#region File Get-NBVPNIPSecPolicy.ps1

<#
.SYNOPSIS
    Retrieves IPSec Policy objects from Netbox VPN module.

.DESCRIPTION
    Retrieves IPSec Policy objects from Netbox VPN module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBVPNIPSecPolicy

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBVPNIPSecPolicy {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,[ValidateRange(1, 1000)]
        [uint16]$Limit,[ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ipsec-policies',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-policies')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}

#endregion

#region File Get-NBVPNIPSecProfile.ps1

<#
.SYNOPSIS
    Retrieves IPSec Profile objects from Netbox VPN module.

.DESCRIPTION
    Retrieves IPSec Profile objects from Netbox VPN module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBVPNIPSecProfile

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBVPNIPSecProfile {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,[ValidateRange(1, 1000)]
        [uint16]$Limit,[ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ipsec-profiles',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-profiles')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}

#endregion

#region File Get-NBVPNIPSecProposal.ps1

<#
.SYNOPSIS
    Retrieves IPSec Proposal objects from Netbox VPN module.

.DESCRIPTION
    Retrieves IPSec Proposal objects from Netbox VPN module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBVPNIPSecProposal

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBVPNIPSecProposal {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,[ValidateRange(1, 1000)]
        [uint16]$Limit,[ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ipsec-proposals',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-proposals')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}

#endregion

#region File Get-NBVPNL2VPN.ps1

<#
.SYNOPSIS
    Retrieves L2VPN objects from Netbox VPN module.

.DESCRIPTION
    Retrieves L2VPN objects from Netbox VPN module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBVPNL2VPN

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBVPNL2VPN {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,[Parameter(ParameterSetName = 'Query')][string]$Slug,
        [Parameter(ParameterSetName = 'Query')][string]$Type,[Parameter(ParameterSetName = 'Query')][uint64]$Tenant_Id,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,[ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','l2vpns',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('vpn','l2vpns')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}

#endregion

#region File Get-NBVPNL2VPNTermination.ps1

<#
.SYNOPSIS
    Retrieves L2VPNTermination objects from Netbox VPN module.

.DESCRIPTION
    Retrieves L2VPNTermination objects from Netbox VPN module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBVPNL2VPNTermination

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBVPNL2VPNTermination {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$L2VPN_Id,[ValidateRange(1, 1000)]
        [uint16]$Limit,[ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','l2vpn-terminations',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('vpn','l2vpn-terminations')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}

#endregion

#region File Get-NBVPNTunnel.ps1

<#
.SYNOPSIS
    Retrieves Tunnel objects from Netbox VPN module.

.DESCRIPTION
    Retrieves Tunnel objects from Netbox VPN module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBVPNTunnel

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBVPNTunnel {
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
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
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

#region File Get-NBVPNTunnelGroup.ps1

<#
.SYNOPSIS
    Retrieves Tunnel Group objects from Netbox VPN module.

.DESCRIPTION
    Retrieves Tunnel Group objects from Netbox VPN module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBVPNTunnelGroup

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBVPNTunnelGroup {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,[Parameter(ParameterSetName = 'Query')][string]$Slug,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,[ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','tunnel-groups',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('vpn','tunnel-groups')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}

#endregion

#region File Get-NBVPNTunnelTermination.ps1

<#
.SYNOPSIS
    Retrieves Tunnel Termination objects from Netbox VPN module.

.DESCRIPTION
    Retrieves Tunnel Termination objects from Netbox VPN module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBVPNTunnelTermination

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBVPNTunnelTermination {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Tunnel_Id,[Parameter(ParameterSetName = 'Query')][string]$Role,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,[ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','tunnel-terminations',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('vpn','tunnel-terminations')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}

#endregion

#region File Get-NBWebhook.ps1

<#
.SYNOPSIS
    Retrieves webhooks from Netbox.

.DESCRIPTION
    Retrieves webhooks from Netbox Extras module.

.PARAMETER Id
    Database ID of the webhook.

.PARAMETER Name
    Filter by name.

.PARAMETER Enabled
    Filter by enabled status.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBWebhook

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBWebhook {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Enabled,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('extras', 'webhooks', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('extras', 'webhooks'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Get-NBWirelessLAN.ps1

<#
.SYNOPSIS
    Retrieves Wireless LAN objects from Netbox Wireless module.

.DESCRIPTION
    Retrieves Wireless LAN objects from Netbox Wireless module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBWirelessLAN

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBWirelessLAN {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$SSID,[Parameter(ParameterSetName = 'Query')][uint64]$Group_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Status,[Parameter(ParameterSetName = 'Query')][uint64]$VLAN_Id,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,[ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('wireless','wireless-lans',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('wireless','wireless-lans')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}

#endregion

#region File Get-NBWirelessLANGroup.ps1

<#
.SYNOPSIS
    Retrieves Wireless LANGroup objects from Netbox Wireless module.

.DESCRIPTION
    Retrieves Wireless LANGroup objects from Netbox Wireless module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBWirelessLANGroup

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBWirelessLANGroup {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,[Parameter(ParameterSetName = 'Query')][string]$Slug,
        [Parameter(ParameterSetName = 'Query')][uint64]$Parent_Id,[ValidateRange(1, 1000)]
        [uint16]$Limit,[ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('wireless','wireless-lan-groups',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('wireless','wireless-lan-groups')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}

#endregion

#region File Get-NBWirelessLink.ps1

<#
.SYNOPSIS
    Retrieves Wireless Link objects from Netbox Wireless module.

.DESCRIPTION
    Retrieves Wireless Link objects from Netbox Wireless module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBWirelessLink

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBWirelessLink {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$SSID,[Parameter(ParameterSetName = 'Query')][string]$Status,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,[ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,[switch]$Raw)
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

    # Explicitly specify UTF-8 encoding for cross-platform consistency
    $reader = [System.IO.StreamReader]::new($Response.GetResponseStream(), [System.Text.Encoding]::UTF8)
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
        [uint16]$Timeout = (Get-NBTimeout),

        [ValidateSet('GET', 'PATCH', 'PUT', 'POST', 'DELETE', 'OPTIONS', IgnoreCase = $true)]
        [string]$Method = 'GET',

        [switch]$Raw
    )

    $creds = Get-NBCredential

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

    $splat += Get-NBInvokeParams

    if ($Body) {
        Write-Verbose "BODY: $($Body | ConvertTo-Json -Compress)"
        $null = $splat.Add('Body', ($Body | ConvertTo-Json -Compress))
    }

    try {
        Write-Verbose "Sending request to $($URI.Uri.AbsoluteUri)"
        $result = Invoke-RestMethod @splat
    } catch {
        $errorMessage = $_.Exception.Message
        $statusCode = $null

        # Try to extract response body for better error messages
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode

            try {
                $stream = $_.Exception.Response.GetResponseStream()
                # Explicitly specify UTF-8 encoding for cross-platform consistency
                $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::UTF8)
                $responseBody = $reader.ReadToEnd()
                $reader.Close()

                if ($responseBody) {
                    $errorData = $responseBody | ConvertFrom-Json -ErrorAction SilentlyContinue
                    if ($errorData.detail) {
                        $errorMessage = $errorData.detail
                    } elseif ($errorData) {
                        $errorMessage = $responseBody
                    }
                }
            } catch {
                # Keep original error message if we can't parse response
                Write-Verbose "Could not parse error response body: $_"
            }
        }

        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            [System.Exception]::new("Netbox API Error ($statusCode): $errorMessage"),
            'NetboxAPIError',
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $URI.Uri.AbsoluteUri
        )
        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

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

#region File New-NBBookmark.ps1

<#
.SYNOPSIS
    Creates a new bookmark in Netbox.

.DESCRIPTION
    Creates a new bookmark in Netbox Extras module.

.PARAMETER Object_Type
    Object type (e.g., "dcim.device").

.PARAMETER Object_Id
    Object ID.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBBookmark -Object_Type "dcim.device" -Object_Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBBookmark {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Object_Type,

        [Parameter(Mandatory = $true)]
        [uint64]$Object_Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'bookmarks'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("$Object_Type $Object_Id", 'Create Bookmark')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBCircuit.ps1

<#
.SYNOPSIS
    Creates a new ircuit in Netbox C module.

.DESCRIPTION
    Creates a new ircuit in Netbox C module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBCircuit

    Returns all ircuit objects.

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

#region File New-NBCircuitGroup.ps1

<#
.SYNOPSIS
    Creates a new circuit group in Netbox.

.DESCRIPTION
    Creates a new circuit group in Netbox.

.PARAMETER Name
    Name of the circuit group.

.PARAMETER Slug
    URL-friendly slug.

.PARAMETER Description
    Description.

.PARAMETER Tenant
    Tenant ID.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBCircuitGroup -Name "WAN Links" -Slug "wan-links"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBCircuitGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$Slug,

        [string]$Description,

        [uint64]$Tenant,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-groups'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Circuit Group')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBCircuitGroupAssignment.ps1

<#
.SYNOPSIS
    Creates a new circuit group assignment in Netbox.

.DESCRIPTION
    Creates a new circuit group assignment in Netbox.

.PARAMETER Group
    Circuit group ID.

.PARAMETER Circuit
    Circuit ID.

.PARAMETER Priority
    Priority (primary, secondary, tertiary, inactive).

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBCircuitGroupAssignment -Group 1 -Circuit 1 -Priority "primary"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBCircuitGroupAssignment {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [uint64]$Group,

        [Parameter(Mandatory = $true)]
        [uint64]$Circuit,

        [ValidateSet('primary', 'secondary', 'tertiary', 'inactive')]
        [string]$Priority,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-group-assignments'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("Group $Group Circuit $Circuit", 'Create Circuit Group Assignment')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBCircuitProvider.ps1

<#
.SYNOPSIS
    Creates a new circuit provider in Netbox.

.DESCRIPTION
    Creates a new circuit provider in Netbox.

.PARAMETER Name
    Name of the provider.

.PARAMETER Slug
    URL-friendly slug.

.PARAMETER Description
    Description of the provider.

.PARAMETER Comments
    Comments.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBCircuitProvider -Name "AT&T" -Slug "att"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBCircuitProvider {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$Slug,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'providers'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Circuit Provider')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBCircuitProviderAccount.ps1

<#
.SYNOPSIS
    Creates a new provider account in Netbox.

.DESCRIPTION
    Creates a new provider account in Netbox.

.PARAMETER Provider
    Provider ID.

.PARAMETER Name
    Name of the account.

.PARAMETER Account
    Account number/identifier.

.PARAMETER Description
    Description.

.PARAMETER Comments
    Comments.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBCircuitProviderAccount -Provider 1 -Name "Main Account" -Account "ACC-001"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBCircuitProviderAccount {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [uint64]$Provider,

        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Account,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'provider-accounts'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Account, 'Create Provider Account')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBCircuitProviderNetwork.ps1

<#
.SYNOPSIS
    Creates a new provider network in Netbox.

.DESCRIPTION
    Creates a new provider network in Netbox.

.PARAMETER Provider
    Provider ID.

.PARAMETER Name
    Name of the network.

.PARAMETER Service_Id
    Service identifier.

.PARAMETER Description
    Description.

.PARAMETER Comments
    Comments.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBCircuitProviderNetwork -Provider 1 -Name "MPLS Network"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBCircuitProviderNetwork {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [uint64]$Provider,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$Service_Id,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'provider-networks'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Provider Network')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBCircuitTermination.ps1

<#
.SYNOPSIS
    Creates a new circuit termination in Netbox.

.DESCRIPTION
    Creates a new circuit termination in Netbox.

.PARAMETER Circuit
    Circuit ID.

.PARAMETER Term_Side
    Termination side (A or Z).

.PARAMETER Site
    Site ID.

.PARAMETER Provider_Network
    Provider network ID.

.PARAMETER Port_Speed
    Port speed in Kbps.

.PARAMETER Upstream_Speed
    Upstream speed in Kbps.

.PARAMETER Xconnect_Id
    Cross-connect ID.

.PARAMETER Pp_Info
    Patch panel info.

.PARAMETER Description
    Description.

.PARAMETER Mark_Connected
    Mark as connected.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBCircuitTermination -Circuit 1 -Term_Side "A" -Site 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBCircuitTermination {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [uint64]$Circuit,

        [Parameter(Mandatory = $true)]
        [ValidateSet('A', 'Z')]
        [string]$Term_Side,

        [uint64]$Site,

        [uint64]$Provider_Network,

        [uint64]$Port_Speed,

        [uint64]$Upstream_Speed,

        [string]$Xconnect_Id,

        [string]$Pp_Info,

        [string]$Description,

        [bool]$Mark_Connected,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-terminations'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("Circuit $Circuit Side $Term_Side", 'Create Circuit Termination')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBCircuitType.ps1

<#
.SYNOPSIS
    Creates a new circuit type in Netbox.

.DESCRIPTION
    Creates a new circuit type in Netbox.

.PARAMETER Name
    Name of the circuit type.

.PARAMETER Slug
    URL-friendly slug. Auto-generated from name if not provided.

.PARAMETER Color
    Color code (6 hex characters).

.PARAMETER Description
    Description of the circuit type.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBCircuitType -Name "MPLS" -Slug "mpls"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBCircuitType {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$Slug,

        [ValidatePattern('^[0-9a-fA-F]{6}$')]
        [string]$Color,

        [string]$Description,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-types'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Circuit Type')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBConfigContext.ps1

<#
.SYNOPSIS
    Creates a new config context in Netbox.

.DESCRIPTION
    Creates a new config context in Netbox Extras module.

.PARAMETER Name
    Name of the config context.

.PARAMETER Weight
    Weight for ordering (0-32767).

.PARAMETER Description
    Description of the config context.

.PARAMETER Is_Active
    Whether the config context is active.

.PARAMETER Data
    Configuration data (hashtable or JSON).

.PARAMETER Regions
    Array of region IDs.

.PARAMETER Site_Groups
    Array of site group IDs.

.PARAMETER Sites
    Array of site IDs.

.PARAMETER Locations
    Array of location IDs.

.PARAMETER Device_Types
    Array of device type IDs.

.PARAMETER Roles
    Array of role IDs.

.PARAMETER Platforms
    Array of platform IDs.

.PARAMETER Cluster_Types
    Array of cluster type IDs.

.PARAMETER Cluster_Groups
    Array of cluster group IDs.

.PARAMETER Clusters
    Array of cluster IDs.

.PARAMETER Tenant_Groups
    Array of tenant group IDs.

.PARAMETER Tenants
    Array of tenant IDs.

.PARAMETER Tags
    Array of tag slugs.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBConfigContext -Name "NTP Servers" -Data @{ntp_servers = @("10.0.0.1", "10.0.0.2")}

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBConfigContext {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [ValidateRange(0, 32767)]
        [uint16]$Weight,

        [string]$Description,

        [bool]$Is_Active,

        [Parameter(Mandatory = $true)]
        $Data,

        [uint64[]]$Regions,

        [uint64[]]$Site_Groups,

        [uint64[]]$Sites,

        [uint64[]]$Locations,

        [uint64[]]$Device_Types,

        [uint64[]]$Roles,

        [uint64[]]$Platforms,

        [uint64[]]$Cluster_Types,

        [uint64[]]$Cluster_Groups,

        [uint64[]]$Clusters,

        [uint64[]]$Tenant_Groups,

        [uint64[]]$Tenants,

        [string[]]$Tags,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'config-contexts'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Config Context')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBContact.ps1


function New-NBContact {
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
        PS C:\> New-NBContact -Name 'Leroy Jenkins' -Email 'leroy.jenkins@example.com'

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

#region File New-NBContactAssignment.ps1


function New-NBContactAssignment {
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
        PS C:\> New-NBContactAssignment -Content_Type 'dcim.location' -Object_id 10 -Contact 15 -Role 10 -Priority 'Primary'

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

#region File New-NBContactRole.ps1


function New-NBContactRole {
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
        PS C:\> New-NBContact -Name 'Leroy Jenkins' -Email 'leroy.jenkins@example.com'

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

#region File New-NBCustomField.ps1

<#
.SYNOPSIS
    Creates a new custom field in Netbox.

.DESCRIPTION
    Creates a new custom field in Netbox Extras module.

.PARAMETER Name
    Internal name of the custom field.

.PARAMETER Label
    Display label for the custom field.

.PARAMETER Type
    Field type (text, longtext, integer, decimal, boolean, date, datetime, url, json, select, multiselect, object, multiobject).

.PARAMETER Object_Types
    Content types this field applies to.

.PARAMETER Group_Name
    Group name for organizing fields.

.PARAMETER Description
    Description of the field.

.PARAMETER Required
    Whether this field is required.

.PARAMETER Search_Weight
    Search weight (0-32767).

.PARAMETER Filter_Logic
    Filter logic (disabled, loose, exact).

.PARAMETER Ui_Visible
    UI visibility (always, if-set, hidden).

.PARAMETER Ui_Editable
    UI editability (yes, no, hidden).

.PARAMETER Is_Cloneable
    Whether the field is cloneable.

.PARAMETER Default
    Default value.

.PARAMETER Weight
    Display weight.

.PARAMETER Validation_Minimum
    Minimum value for numeric fields.

.PARAMETER Validation_Maximum
    Maximum value for numeric fields.

.PARAMETER Validation_Regex
    Validation regex pattern.

.PARAMETER Choice_Set
    Choice set ID for select fields.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBCustomField -Name "asset_id" -Label "Asset ID" -Type "text" -Object_Types @("dcim.device")

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBCustomField {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$Label,

        [Parameter(Mandatory = $true)]
        [ValidateSet('text', 'longtext', 'integer', 'decimal', 'boolean', 'date', 'datetime', 'url', 'json', 'select', 'multiselect', 'object', 'multiobject')]
        [string]$Type,

        [Parameter(Mandatory = $true)]
        [string[]]$Object_Types,

        [string]$Group_Name,

        [string]$Description,

        [bool]$Required,

        [ValidateRange(0, 32767)]
        [uint16]$Search_Weight,

        [ValidateSet('disabled', 'loose', 'exact')]
        [string]$Filter_Logic,

        [ValidateSet('always', 'if-set', 'hidden')]
        [string]$Ui_Visible,

        [ValidateSet('yes', 'no', 'hidden')]
        [string]$Ui_Editable,

        [bool]$Is_Cloneable,

        $Default,

        [uint16]$Weight,

        [int64]$Validation_Minimum,

        [int64]$Validation_Maximum,

        [string]$Validation_Regex,

        [uint64]$Choice_Set,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-fields'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Custom Field')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBCustomFieldChoiceSet.ps1

<#
.SYNOPSIS
    Creates a new custom field choice set in Netbox.

.DESCRIPTION
    Creates a new custom field choice set in Netbox Extras module.

.PARAMETER Name
    Name of the choice set.

.PARAMETER Description
    Description of the choice set.

.PARAMETER Base_Choices
    Base choices to inherit from.

.PARAMETER Extra_Choices
    Array of extra choices in format @(@("value1", "label1"), @("value2", "label2")).

.PARAMETER Order_Alphabetically
    Whether to order choices alphabetically.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBCustomFieldChoiceSet -Name "Status Options" -Extra_Choices @(@("active", "Active"), @("inactive", "Inactive"))

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBCustomFieldChoiceSet {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$Description,

        [string]$Base_Choices,

        [array]$Extra_Choices,

        [bool]$Order_Alphabetically,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-field-choice-sets'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Custom Field Choice Set')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBCustomLink.ps1

<#
.SYNOPSIS
    Creates a new custom link in Netbox.

.DESCRIPTION
    Creates a new custom link in Netbox Extras module.

.PARAMETER Name
    Name of the custom link.

.PARAMETER Object_Types
    Object types this link applies to.

.PARAMETER Enabled
    Whether the link is enabled.

.PARAMETER Link_Text
    Link text (Jinja2 template).

.PARAMETER Link_Url
    Link URL (Jinja2 template).

.PARAMETER Weight
    Display weight.

.PARAMETER Group_Name
    Group name for organizing links.

.PARAMETER Button_Class
    Button CSS class.

.PARAMETER New_Window
    Whether to open in new window.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBCustomLink -Name "External Doc" -Object_Types @("dcim.device") -Link_Text "View Docs" -Link_Url "https://docs.example.com/{{ object.name }}"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBCustomLink {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string[]]$Object_Types,

        [bool]$Enabled,

        [Parameter(Mandatory = $true)]
        [string]$Link_Text,

        [Parameter(Mandatory = $true)]
        [string]$Link_Url,

        [uint16]$Weight,

        [string]$Group_Name,

        [ValidateSet('outline-dark', 'blue', 'indigo', 'purple', 'pink', 'red', 'orange', 'yellow', 'green', 'teal', 'cyan', 'gray', 'black', 'white', 'ghost-dark')]
        [string]$Button_Class,

        [bool]$New_Window,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-links'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Custom Link')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDataSource.ps1

<#
.SYNOPSIS
    Creates a new data source in Netbox.

.DESCRIPTION
    Creates a new data source in Netbox Core module.

.PARAMETER Name
    Name of the data source.

.PARAMETER Type
    Type of data source (local, git, amazon-s3).

.PARAMETER Source_Url
    Source URL for remote data sources.

.PARAMETER Description
    Description of the data source.

.PARAMETER Enabled
    Whether the data source is enabled.

.PARAMETER Ignore_Rules
    Patterns to ignore (one per line).

.PARAMETER Parameters
    Additional parameters (hashtable).

.PARAMETER Comments
    Comments.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBDataSource -Name "Config Repo" -Type "git" -Source_Url "https://github.com/example/configs.git"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDataSource {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('local', 'git', 'amazon-s3')]
        [string]$Type,

        [string]$Source_Url,

        [string]$Description,

        [bool]$Enabled,

        [string]$Ignore_Rules,

        [hashtable]$Parameters,

        [string]$Comments,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('core', 'data-sources'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Data Source')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMCable.ps1

<#
.SYNOPSIS
    Creates a new CIMCable in Netbox D module.

.DESCRIPTION
    Creates a new CIMCable in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMCable

    Returns all CIMCable objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMCable {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$A_Terminations_Type,
        [Parameter(Mandatory = $true)][uint64[]]$A_Terminations,
        [Parameter(Mandatory = $true)][string]$B_Terminations_Type,
        [Parameter(Mandatory = $true)][uint64[]]$B_Terminations,
        [string]$Type,
        [string]$Status,
        [uint64]$Tenant,
        [string]$Label,
        [string]$Color,
        [decimal]$Length,
        [string]$Length_Unit,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','cables'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Label, 'Create cable')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMConsolePort.ps1

<#
.SYNOPSIS
    Creates a new CIMConsolePort in Netbox D module.

.DESCRIPTION
    Creates a new CIMConsolePort in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMConsolePort

    Returns all CIMConsolePort objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMConsolePort {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Device,
        [Parameter(Mandatory = $true)][string]$Name,
        [uint64]$Module,
        [string]$Label,
        [string]$Type,
        [uint16]$Speed,
        [bool]$Mark_Connected,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','console-ports'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create console port')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMConsolePortTemplate.ps1

<#
.SYNOPSIS
    Creates a new CIMConsolePortTemplate in Netbox D module.

.DESCRIPTION
    Creates a new CIMConsolePortTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMConsolePortTemplate

    Returns all CIMConsolePortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMConsolePortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Label,
        [string]$Type,
        [string]$Description,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','console-port-templates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create console port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMConsoleServerPort.ps1

<#
.SYNOPSIS
    Creates a new CIMConsoleServerPort in Netbox D module.

.DESCRIPTION
    Creates a new CIMConsoleServerPort in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMConsoleServerPort

    Returns all CIMConsoleServerPort objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMConsoleServerPort {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Device,
        [Parameter(Mandatory = $true)][string]$Name,
        [uint64]$Module,
        [string]$Label,
        [string]$Type,
        [uint16]$Speed,
        [bool]$Mark_Connected,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','console-server-ports'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create console server port')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMConsoleServerPortTemplate.ps1

<#
.SYNOPSIS
    Creates a new CIMConsoleServerPortTemplate in Netbox D module.

.DESCRIPTION
    Creates a new CIMConsoleServerPortTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMConsoleServerPortTemplate

    Returns all CIMConsoleServerPortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMConsoleServerPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Label,
        [string]$Type,
        [string]$Description,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','console-server-port-templates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create console server port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMDevice.ps1

<#
.SYNOPSIS
    Creates a new CIMDevice in Netbox D module.

.DESCRIPTION
    Creates a new CIMDevice in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMDevice

    Returns all CIMDevice objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function New-NBDCIMDevice {
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

#region File New-NBDCIMDeviceBay.ps1

<#
.SYNOPSIS
    Creates a new CIMDeviceBay in Netbox D module.

.DESCRIPTION
    Creates a new CIMDeviceBay in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMDeviceBay

    Returns all CIMDeviceBay objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMDeviceBay {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Device,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Label,
        [uint64]$Installed_Device,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','device-bays'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create device bay')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMDeviceBayTemplate.ps1

<#
.SYNOPSIS
    Creates a new CIMDeviceBayTemplate in Netbox D module.

.DESCRIPTION
    Creates a new CIMDeviceBayTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMDeviceBayTemplate

    Returns all CIMDeviceBayTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMDeviceBayTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Device_Type,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Label,
        [string]$Description,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','device-bay-templates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create device bay template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMDeviceRole.ps1

<#
.SYNOPSIS
    Creates a new CIMDeviceRole in Netbox D module.

.DESCRIPTION
    Creates a new CIMDeviceRole in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMDeviceRole

    Returns all CIMDeviceRole objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMDeviceRole {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Slug,
        [string]$Color,
        [bool]$VM_Role,
        [uint64]$Config_Template,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','device-roles'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create device role')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMDeviceType.ps1

<#
.SYNOPSIS
    Creates a new CIMDeviceType in Netbox D module.

.DESCRIPTION
    Creates a new CIMDeviceType in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMDeviceType

    Returns all CIMDeviceType objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMDeviceType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Manufacturer,
        [Parameter(Mandatory = $true)][string]$Model,
        [string]$Slug,
        [string]$Part_Number,
        [uint16]$U_Height,
        [bool]$Is_Full_Depth,
        [string]$Subdevice_Role,
        [string]$Airflow,
        [uint16]$Weight,
        [string]$Weight_Unit,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','device-types'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Model, 'Create device type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMFrontPort.ps1

<#
.SYNOPSIS
    Creates a new front port on a device in Netbox.

.DESCRIPTION
    Creates a new front port on a specified device in the Netbox DCIM module.
    Front ports represent the front-facing ports on patch panels or other devices
    that connect to rear ports for pass-through cabling.

.PARAMETER Device
    The database ID of the device to add the front port to.

.PARAMETER Name
    The name of the front port (e.g., 'Port 1', 'Front-01').

.PARAMETER Type
    The connector type of the front port. Common types include:
    - Copper: '8p8c' (RJ-45), '8p6c', '8p4c', '110-punch', 'bnc'
    - Fiber: 'lc', 'lc-apc', 'sc', 'sc-apc', 'st', 'mpo', 'mtrj'
    - Coax: 'f', 'n', 'bnc'
    - Other: 'splice', 'other'

.PARAMETER Rear_Port
    The database ID of the rear port that this front port maps to.
    Required for establishing the pass-through connection.

.PARAMETER Module
    The database ID of the module within the device (for modular devices).

.PARAMETER Label
    A physical label for the port (what's printed on the device).

.PARAMETER Color
    The color of the port in 6-character hex format (e.g., 'ff0000' for red).

.PARAMETER Rear_Port_Position
    The position on the rear port (for rear ports with multiple positions).
    Defaults to 1 if not specified.

.PARAMETER Description
    A description of the front port.

.PARAMETER Mark_Connected
    Whether to mark this port as connected even without a cable object.

.PARAMETER Tags
    Array of tag IDs to assign to this front port.

.EXAMPLE
    New-NBDCIMFrontPort -Device 42 -Name "Port 1" -Type "8p8c" -Rear_Port 100

    Creates a new RJ-45 front port named 'Port 1' on device 42, mapped to rear port 100.

.EXAMPLE
    New-NBDCIMFrontPort -Device 42 -Name "Fiber-01" -Type "lc" -Rear_Port 100 -Color "00ff00"

    Creates a new LC fiber front port with a green color indicator.

.EXAMPLE
    1..24 | ForEach-Object {
        New-NBDCIMFrontPort -Device 42 -Name "Port $_" -Type "8p8c" -Rear_Port (100 + $_)
    }

    Creates 24 front ports on a patch panel, each mapped to a corresponding rear port.

.LINK
    https://netbox.readthedocs.io/en/stable/models/dcim/frontport/
#>
function New-NBDCIMFrontPort {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [uint64]$Device,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('8p8c', '8p6c', '8p4c', '8p2c', '6p6c', '6p4c', '6p2c', '4p4c', '4p2c',
            'gg45', 'tera-4p', 'tera-2p', 'tera-1p', '110-punch', 'bnc', 'f', 'n', 'mrj21',
            'fc', 'lc', 'lc-pc', 'lc-upc', 'lc-apc', 'lsh', 'lsh-pc', 'lsh-upc', 'lsh-apc',
            'lx5', 'lx5-pc', 'lx5-upc', 'lx5-apc', 'mpo', 'mtrj', 'sc', 'sc-pc', 'sc-upc',
            'sc-apc', 'st', 'cs', 'sn', 'sma-905', 'sma-906', 'urm-p2', 'urm-p4', 'urm-p8',
            'splice', 'other', IgnoreCase = $true)]
        [string]$Type,

        [Parameter(Mandatory = $true)]
        [uint64]$Rear_Port,

        [uint64]$Module,

        [string]$Label,

        [ValidatePattern('^[0-9a-fA-F]{6}$')]
        [string]$Color,

        [ValidateRange(1, 1024)]
        [uint16]$Rear_Port_Position,

        [string]$Description,

        [bool]$Mark_Connected,

        [uint64[]]$Tags
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'front-ports'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("Device $Device", "Create front port '$Name'")) {
            InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method POST
        }
    }
}

#endregion

#region File New-NBDCIMFrontPortTemplate.ps1

<#
.SYNOPSIS
    Creates a new CIMFrontPortTemplate in Netbox D module.

.DESCRIPTION
    Creates a new CIMFrontPortTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMFrontPortTemplate

    Returns all CIMFrontPortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMFrontPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Label,
        [Parameter(Mandatory = $true)][string]$Type,
        [string]$Color,
        [Parameter(Mandatory = $true)][uint64]$Rear_Port,
        [uint16]$Rear_Port_Position,
        [string]$Description,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','front-port-templates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create front port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMInterface.ps1

<#
.SYNOPSIS
    Creates a new interface on a device in Netbox.

.DESCRIPTION
    Creates a new network interface on a specified device in the Netbox DCIM module.
    Supports various interface types including physical, virtual, LAG, and wireless interfaces.

.PARAMETER Device
    The database ID of the device to add the interface to.

.PARAMETER Name
    The name of the interface (e.g., 'eth0', 'GigabitEthernet0/1').

.PARAMETER Type
    The interface type. Supports physical types (1000base-t, 10gbase-x-sfpp, etc.),
    virtual types (virtual, bridge, lag), and wireless types (ieee802.11ac, etc.).

.PARAMETER Enabled
    Whether the interface is enabled. Defaults to true if not specified.

.PARAMETER Form_Factor
    Legacy parameter for interface form factor.

.PARAMETER MTU
    Maximum Transmission Unit size (typically 1500 for Ethernet).

.PARAMETER MAC_Address
    The MAC address of the interface in format XX:XX:XX:XX:XX:XX.

.PARAMETER MGMT_Only
    If true, this interface is used for management traffic only.

.PARAMETER LAG
    The database ID of the LAG interface this interface belongs to.

.PARAMETER Description
    A description of the interface.

.PARAMETER Mode
    VLAN mode: 'Access' (untagged), 'Tagged' (trunk), or 'Tagged All'.

.PARAMETER Untagged_VLAN
    VLAN ID for untagged/native VLAN (1-4094).

.PARAMETER Tagged_VLANs
    Array of VLAN IDs for tagged VLANs (1-4094 each).

.EXAMPLE
    New-NBDCIMInterface -Device 42 -Name "eth0" -Type "1000base-t"

    Creates a new 1GbE interface named 'eth0' on device ID 42.

.EXAMPLE
    New-NBDCIMInterface -Device 42 -Name "bond0" -Type "lag" -Description "Server uplink LAG"

    Creates a new LAG interface for link aggregation.

.EXAMPLE
    New-NBDCIMInterface -Device 42 -Name "Gi0/1" -Type "1000base-t" -Mode "Tagged" -Tagged_VLANs 10,20,30

    Creates a trunk interface with multiple tagged VLANs.

.LINK
    https://netbox.readthedocs.io/en/stable/models/dcim/interface/
#>
function New-NBDCIMInterface {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [uint64]$Device,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [ValidateSet('virtual', 'bridge', 'lag', '100base-tx', '1000base-t', '2.5gbase-t', '5gbase-t', '10gbase-t', '10gbase-cx4', '1000base-x-gbic', '1000base-x-sfp', '10gbase-x-sfpp', '10gbase-x-xfp', '10gbase-x-xenpak', '10gbase-x-x2', '25gbase-x-sfp28', '50gbase-x-sfp56', '40gbase-x-qsfpp', '50gbase-x-sfp28', '100gbase-x-cfp', '100gbase-x-cfp2', '200gbase-x-cfp2', '100gbase-x-cfp4', '100gbase-x-cpak', '100gbase-x-qsfp28', '200gbase-x-qsfp56', '400gbase-x-qsfpdd', '400gbase-x-osfp', '1000base-kx', '10gbase-kr', '10gbase-kx4', '25gbase-kr', '40gbase-kr4', '50gbase-kr', '100gbase-kp4', '100gbase-kr2', '100gbase-kr4', 'ieee802.11a', 'ieee802.11g', 'ieee802.11n', 'ieee802.11ac', 'ieee802.11ad', 'ieee802.11ax', 'ieee802.11ay', 'ieee802.15.1', 'other-wireless', 'gsm', 'cdma', 'lte', 'sonet-oc3', 'sonet-oc12', 'sonet-oc48', 'sonet-oc192', 'sonet-oc768', 'sonet-oc1920', 'sonet-oc3840', '1gfc-sfp', '2gfc-sfp', '4gfc-sfp', '8gfc-sfpp', '16gfc-sfpp', '32gfc-sfp28', '64gfc-qsfpp', '128gfc-qsfp28', 'infiniband-sdr', 'infiniband-ddr', 'infiniband-qdr', 'infiniband-fdr10', 'infiniband-fdr', 'infiniband-edr', 'infiniband-hdr', 'infiniband-ndr', 'infiniband-xdr', 't1', 'e1', 't3', 'e3', 'xdsl', 'docsis', 'gpon', 'xg-pon', 'xgs-pon', 'ng-pon2', 'epon', '10g-epon', 'cisco-stackwise', 'cisco-stackwise-plus', 'cisco-flexstack', 'cisco-flexstack-plus', 'cisco-stackwise-80', 'cisco-stackwise-160', 'cisco-stackwise-320', 'cisco-stackwise-480', 'juniper-vcp', 'extreme-summitstack', 'extreme-summitstack-128', 'extreme-summitstack-256', 'extreme-summitstack-512', 'other', IgnoreCase = $true)]
        [string]$Type,

        [bool]$Enabled,

        [object]$Form_Factor,

        [ValidateRange(1, 65535)]
        [uint16]$MTU,

        [ValidatePattern('^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$')]
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

    process {
        # Convert Mode friendly names to API values
        if (-not [System.String]::IsNullOrWhiteSpace($Mode)) {
            $PSBoundParameters.Mode = switch ($Mode) {
                'Access' { 100 }
                'Tagged' { 200 }
                'Tagged All' { 300 }
                default { $_ }
            }
        }

        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'interfaces'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("Device $Device", "Create interface '$Name'")) {
            InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method POST
        }
    }
}

#endregion

#region File New-NBDCIMInterfaceConnection.ps1

<#
.SYNOPSIS
    Creates a new cable connection between two device interfaces in Netbox.

.DESCRIPTION
    Creates a new cable connection between two device interfaces in the Netbox DCIM module.
    This function validates that both interfaces exist before attempting to create the connection.
    The connection is represented as a cable object linking Interface A to Interface B.

.PARAMETER Interface_A
    The database ID of the first interface (A-side of the connection).
    The interface must exist in Netbox or the function will throw an error.

.PARAMETER Interface_B
    The database ID of the second interface (B-side of the connection).
    The interface must exist in Netbox or the function will throw an error.

.PARAMETER Connection_Status
    The status of the connection. Common values include:
    - 'connected' - The connection is active
    - 'planned' - The connection is planned but not yet implemented

.EXAMPLE
    New-NBDCIMInterfaceConnection -Interface_A 101 -Interface_B 102

    Creates a new connection between interface ID 101 and interface ID 102.

.EXAMPLE
    New-NBDCIMInterfaceConnection -Interface_A 101 -Interface_B 102 -Connection_Status 'planned'

    Creates a planned connection between two interfaces.

.EXAMPLE
    $intA = Get-NBDCIMInterface -Device_Id 1 -Name 'eth0'
    $intB = Get-NBDCIMInterface -Device_Id 2 -Name 'eth0'
    New-NBDCIMInterfaceConnection -Interface_A $intA.Id -Interface_B $intB.Id

    Creates a connection between eth0 interfaces on two different devices.

.NOTES
    This function creates a cable object in Netbox. The interface-connections endpoint
    is a legacy endpoint that may be deprecated in future Netbox versions.
    Consider using the cables endpoint directly for new implementations.

.LINK
    https://netbox.readthedocs.io/en/stable/models/dcim/cable/
#>
function New-NBDCIMInterfaceConnection {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [uint64]$Interface_A,

        [Parameter(Mandatory = $true)]
        [uint64]$Interface_B,

        [ValidateSet('connected', 'planned', IgnoreCase = $true)]
        [string]$Connection_Status
    )

    process {
        # Verify both interfaces exist before creating connection
        Write-Verbose "Validating Interface A (ID: $Interface_A) exists..."
        $null = Get-NBDCIMInterface -Id $Interface_A -ErrorAction Stop

        Write-Verbose "Validating Interface B (ID: $Interface_B) exists..."
        $null = Get-NBDCIMInterface -Id $Interface_B -ErrorAction Stop

        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'interface-connections'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("Interface $Interface_A <-> Interface $Interface_B", 'Create connection')) {
            InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method POST
        }
    }
}

#endregion

#region File New-NBDCIMInterfaceTemplate.ps1

<#
.SYNOPSIS
    Creates a new CIMInterfaceTemplate in Netbox D module.

.DESCRIPTION
    Creates a new CIMInterfaceTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMInterfaceTemplate

    Returns all CIMInterfaceTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMInterfaceTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Label,
        [Parameter(Mandatory = $true)][string]$Type,
        [bool]$Enabled,
        [bool]$Mgmt_Only,
        [string]$Description,
        [string]$Poe_Mode,
        [string]$Poe_Type,
        [string]$Rf_Role,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','interface-templates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create interface template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMInventoryItem.ps1

<#
.SYNOPSIS
    Creates a new CIMInventoryItem in Netbox D module.

.DESCRIPTION
    Creates a new CIMInventoryItem in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMInventoryItem

    Returns all CIMInventoryItem objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMInventoryItem {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Device,
        [Parameter(Mandatory = $true)][string]$Name,
        [uint64]$Parent,
        [string]$Label,
        [uint64]$Role,
        [uint64]$Manufacturer,
        [string]$Part_Id,
        [string]$Serial,
        [string]$Asset_Tag,
        [bool]$Discovered,
        [string]$Description,
        [uint64]$Component_Type,
        [uint64]$Component_Id,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','inventory-items'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create inventory item')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMInventoryItemRole.ps1

<#
.SYNOPSIS
    Creates a new CIMInventoryItemRole in Netbox D module.

.DESCRIPTION
    Creates a new CIMInventoryItemRole in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMInventoryItemRole

    Returns all CIMInventoryItemRole objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMInventoryItemRole {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Slug,
        [string]$Color,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','inventory-item-roles'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create inventory item role')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMInventoryItemTemplate.ps1

<#
.SYNOPSIS
    Creates a new CIMInventoryItemTemplate in Netbox D module.

.DESCRIPTION
    Creates a new CIMInventoryItemTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMInventoryItemTemplate

    Returns all CIMInventoryItemTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMInventoryItemTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Device_Type,
        [Parameter(Mandatory = $true)][string]$Name,
        [uint64]$Parent,
        [string]$Label,
        [uint64]$Role,
        [uint64]$Manufacturer,
        [string]$Part_Id,
        [string]$Description,
        [uint64]$Component_Type,
        [string]$Component_Name,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','inventory-item-templates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create inventory item template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMLocation.ps1

function New-NBDCIMLocation {
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
        New-NBDCIMLocation -Name "Server Room" -Slug "server-room" -Site 1

        Creates a new location named "Server Room" at site 1

    .EXAMPLE
        New-NBDCIMLocation -Name "Floor 2" -Slug "floor-2" -Site 1 -Status active

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

#region File New-NBDCIMMACAddress.ps1

<#
.SYNOPSIS
    Creates a new CIMMACAddress in Netbox D module.

.DESCRIPTION
    Creates a new CIMMACAddress in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMMACAddress

    Returns all CIMMACAddress objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMMACAddress {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Mac_Address,
        [uint64]$Assigned_Object_Id,
        [string]$Assigned_Object_Type,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','mac-addresses'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Mac_Address, 'Create MAC address')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMManufacturer.ps1

function New-NBDCIMManufacturer {
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
        New-NBDCIMManufacturer -Name "Cisco" -Slug "cisco"

        Creates a new manufacturer named "Cisco"

    .EXAMPLE
        New-NBDCIMManufacturer -Name "Dell Technologies" -Slug "dell" -Description "Server and storage manufacturer"

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

#region File New-NBDCIMModule.ps1

<#
.SYNOPSIS
    Creates a new CIMModule in Netbox D module.

.DESCRIPTION
    Creates a new CIMModule in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMModule

    Returns all CIMModule objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMModule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Device,
        [Parameter(Mandatory = $true)][uint64]$Module_Bay,
        [Parameter(Mandatory = $true)][uint64]$Module_Type,
        [string]$Status,
        [string]$Serial,
        [string]$Asset_Tag,
        [string]$Description,
        [string]$Comments,
        [bool]$Replicate_Components,
        [bool]$Adopt_Components,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','modules'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("Device $Device", 'Create module')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMModuleBay.ps1

<#
.SYNOPSIS
    Creates a new CIMModuleBay in Netbox D module.

.DESCRIPTION
    Creates a new CIMModuleBay in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMModuleBay

    Returns all CIMModuleBay objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMModuleBay {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Device,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Label,
        [string]$Position,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','module-bays'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create module bay')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMModuleBayTemplate.ps1

<#
.SYNOPSIS
    Creates a new CIMModuleBayTemplate in Netbox D module.

.DESCRIPTION
    Creates a new CIMModuleBayTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMModuleBayTemplate

    Returns all CIMModuleBayTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMModuleBayTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Device_Type,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Label,
        [string]$Position,
        [string]$Description,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','module-bay-templates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create module bay template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMModuleType.ps1

<#
.SYNOPSIS
    Creates a new CIMModuleType in Netbox D module.

.DESCRIPTION
    Creates a new CIMModuleType in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMModuleType

    Returns all CIMModuleType objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMModuleType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Manufacturer,
        [Parameter(Mandatory = $true)][string]$Model,
        [string]$Part_Number,
        [uint16]$Weight,
        [string]$Weight_Unit,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','module-types'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Model, 'Create module type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMModuleTypeProfile.ps1

<#
.SYNOPSIS
    Creates a new CIMModuleTypeProfile in Netbox D module.

.DESCRIPTION
    Creates a new CIMModuleTypeProfile in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMModuleTypeProfile

    Returns all CIMModuleTypeProfile objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMModuleTypeProfile {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','module-type-profiles'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create module type profile')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMPlatform.ps1

<#
.SYNOPSIS
    Creates a new CIMPlatform in Netbox D module.

.DESCRIPTION
    Creates a new CIMPlatform in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMPlatform

    Returns all CIMPlatform objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMPlatform {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Slug,
        [uint64]$Manufacturer,
        [uint64]$Config_Template,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','platforms'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create platform')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMPowerFeed.ps1

<#
.SYNOPSIS
    Creates a new CIMPowerFeed in Netbox D module.

.DESCRIPTION
    Creates a new CIMPowerFeed in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMPowerFeed

    Returns all CIMPowerFeed objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMPowerFeed {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Power_Panel,
        [Parameter(Mandatory = $true)][string]$Name,
        [uint64]$Rack,
        [string]$Status,
        [string]$Type,
        [string]$Supply,
        [string]$Phase,
        [uint16]$Voltage,
        [uint16]$Amperage,
        [uint16]$Max_Utilization,
        [bool]$Mark_Connected,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','power-feeds'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create power feed')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMPowerOutlet.ps1

<#
.SYNOPSIS
    Creates a new CIMPowerOutlet in Netbox D module.

.DESCRIPTION
    Creates a new CIMPowerOutlet in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMPowerOutlet

    Returns all CIMPowerOutlet objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMPowerOutlet {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Device,
        [Parameter(Mandatory = $true)][string]$Name,
        [uint64]$Module,
        [string]$Label,
        [string]$Type,
        [uint64]$Power_Port,
        [string]$Feed_Leg,
        [bool]$Mark_Connected,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','power-outlets'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create power outlet')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMPowerOutletTemplate.ps1

<#
.SYNOPSIS
    Creates a new CIMPowerOutletTemplate in Netbox D module.

.DESCRIPTION
    Creates a new CIMPowerOutletTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMPowerOutletTemplate

    Returns all CIMPowerOutletTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMPowerOutletTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Label,
        [string]$Type,
        [uint64]$Power_Port,
        [string]$Feed_Leg,
        [string]$Description,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','power-outlet-templates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create power outlet template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMPowerPanel.ps1

<#
.SYNOPSIS
    Creates a new CIMPowerPanel in Netbox D module.

.DESCRIPTION
    Creates a new CIMPowerPanel in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMPowerPanel

    Returns all CIMPowerPanel objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMPowerPanel {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Site,
        [Parameter(Mandatory = $true)][string]$Name,
        [uint64]$Location,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','power-panels'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create power panel')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMPowerPort.ps1

<#
.SYNOPSIS
    Creates a new CIMPowerPort in Netbox D module.

.DESCRIPTION
    Creates a new CIMPowerPort in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMPowerPort

    Returns all CIMPowerPort objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMPowerPort {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Device,
        [Parameter(Mandatory = $true)][string]$Name,
        [uint64]$Module,
        [string]$Label,
        [string]$Type,
        [uint16]$Maximum_Draw,
        [uint16]$Allocated_Draw,
        [bool]$Mark_Connected,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','power-ports'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create power port')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMPowerPortTemplate.ps1

<#
.SYNOPSIS
    Creates a new CIMPowerPortTemplate in Netbox D module.

.DESCRIPTION
    Creates a new CIMPowerPortTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMPowerPortTemplate

    Returns all CIMPowerPortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMPowerPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Label,
        [string]$Type,
        [uint16]$Maximum_Draw,
        [uint16]$Allocated_Draw,
        [string]$Description,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','power-port-templates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create power port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMRack.ps1

function New-NBDCIMRack {
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
        New-NBDCIMRack -Name "Rack-01" -Site 1

        Creates a new rack named "Rack-01" at site 1

    .EXAMPLE
        New-NBDCIMRack -Name "Rack-02" -Site 1 -U_Height 48 -Status active

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

#region File New-NBDCIMRackReservation.ps1

<#
.SYNOPSIS
    Creates a new CIMRackReservation in Netbox D module.

.DESCRIPTION
    Creates a new CIMRackReservation in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMRackReservation

    Returns all CIMRackReservation objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMRackReservation {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Rack,
        [Parameter(Mandatory = $true)][uint16[]]$Units,
        [Parameter(Mandatory = $true)][uint64]$User,
        [uint64]$Tenant,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','rack-reservations'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("Rack $Rack", 'Create rack reservation')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMRackRole.ps1

<#
.SYNOPSIS
    Creates a new CIMRackRole in Netbox D module.

.DESCRIPTION
    Creates a new CIMRackRole in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMRackRole

    Returns all CIMRackRole objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMRackRole {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Slug,
        [string]$Color,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','rack-roles'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create rack role')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMRackType.ps1

<#
.SYNOPSIS
    Creates a new CIMRackType in Netbox D module.

.DESCRIPTION
    Creates a new CIMRackType in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMRackType

    Returns all CIMRackType objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMRackType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Manufacturer,
        [Parameter(Mandatory = $true)][string]$Model,
        [string]$Slug,
        [Parameter(Mandatory = $true)][string]$Form_Factor,
        [uint16]$Width,
        [uint16]$U_Height,
        [uint16]$Starting_Unit,
        [uint16]$Outer_Width,
        [uint16]$Outer_Depth,
        [string]$Outer_Unit,
        [uint16]$Weight,
        [uint16]$Max_Weight,
        [string]$Weight_Unit,
        [string]$Mounting_Depth,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','rack-types'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Model, 'Create rack type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMRearPort.ps1

<#
.SYNOPSIS
    Creates a new rear port on a device in Netbox.

.DESCRIPTION
    Creates a new rear port on a specified device in the Netbox DCIM module.
    Rear ports represent the back-facing ports on patch panels or other devices
    that connect to front ports for pass-through cabling.

.PARAMETER Device
    The database ID of the device to add the rear port to.

.PARAMETER Name
    The name of the rear port (e.g., 'Rear 1', 'Back-01').

.PARAMETER Type
    The connector type of the rear port. Common types include:
    - Copper: '8p8c' (RJ-45), '8p6c', '8p4c', '110-punch', 'bnc'
    - Fiber: 'lc', 'lc-apc', 'sc', 'sc-apc', 'st', 'mpo', 'mtrj'
    - Coax: 'f', 'n', 'bnc'
    - Other: 'splice', 'other'

.PARAMETER Module
    The database ID of the module within the device (for modular devices).

.PARAMETER Label
    A physical label for the port (what's printed on the device).

.PARAMETER Color
    The color of the port in 6-character hex format (e.g., 'ff0000' for red).

.PARAMETER Positions
    The number of front port positions this rear port supports.
    Defaults to 1. Use higher values for multi-position rear ports.

.PARAMETER Description
    A description of the rear port.

.PARAMETER Mark_Connected
    Whether to mark this port as connected even without a cable object.

.PARAMETER Tags
    Array of tag IDs to assign to this rear port.

.EXAMPLE
    New-NBDCIMRearPort -Device 42 -Name "Rear 1" -Type "8p8c"

    Creates a new RJ-45 rear port named 'Rear 1' on device 42.

.EXAMPLE
    New-NBDCIMRearPort -Device 42 -Name "Fiber-Rear-01" -Type "lc" -Positions 2

    Creates a new LC fiber rear port that supports 2 front port positions.

.EXAMPLE
    1..24 | ForEach-Object {
        New-NBDCIMRearPort -Device 42 -Name "Rear $_" -Type "8p8c"
    }

    Creates 24 rear ports on a patch panel.

.LINK
    https://netbox.readthedocs.io/en/stable/models/dcim/rearport/
#>
function New-NBDCIMRearPort {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [uint64]$Device,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('8p8c', '8p6c', '8p4c', '8p2c', '6p6c', '6p4c', '6p2c', '4p4c', '4p2c',
            'gg45', 'tera-4p', 'tera-2p', 'tera-1p', '110-punch', 'bnc', 'f', 'n', 'mrj21',
            'fc', 'lc', 'lc-pc', 'lc-upc', 'lc-apc', 'lsh', 'lsh-pc', 'lsh-upc', 'lsh-apc',
            'lx5', 'lx5-pc', 'lx5-upc', 'lx5-apc', 'mpo', 'mtrj', 'sc', 'sc-pc', 'sc-upc',
            'sc-apc', 'st', 'cs', 'sn', 'sma-905', 'sma-906', 'urm-p2', 'urm-p4', 'urm-p8',
            'splice', 'other', IgnoreCase = $true)]
        [string]$Type,

        [uint64]$Module,

        [string]$Label,

        [ValidatePattern('^[0-9a-fA-F]{6}$')]
        [string]$Color,

        [ValidateRange(1, 1024)]
        [uint16]$Positions = 1,

        [string]$Description,

        [bool]$Mark_Connected,

        [uint64[]]$Tags
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'rear-ports'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("Device $Device", "Create rear port '$Name'")) {
            InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method POST
        }
    }
}

#endregion

#region File New-NBDCIMRearPortTemplate.ps1

<#
.SYNOPSIS
    Creates a new CIMRearPortTemplate in Netbox D module.

.DESCRIPTION
    Creates a new CIMRearPortTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMRearPortTemplate

    Returns all CIMRearPortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMRearPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Label,
        [Parameter(Mandatory = $true)][string]$Type,
        [string]$Color,
        [uint16]$Positions,
        [string]$Description,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','rear-port-templates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create rear port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMRegion.ps1

function New-NBDCIMRegion {
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
        New-NBDCIMRegion -Name "Europe" -Slug "europe"

        Creates a new region named "Europe"

    .EXAMPLE
        New-NBDCIMRegion -Name "Netherlands" -Slug "netherlands" -Parent 1

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

#region File New-NBDCIMSite.ps1

<#
    .NOTES
    ===========================================================================
     Created with:  SAPIEN Technologies, Inc., PowerShell Studio 2020 v5.7.181
     Created on:    2020-10-02 15:52
     Created by:    Claussen
     Organization:  NEOnet
     Filename:      New-NBDCIMSite.ps1
    ===========================================================================
    .DESCRIPTION
        A description of the file.
#>



function New-NBDCIMSite {
    <#
    .SYNOPSIS
        Create a new Site to Netbox

    .DESCRIPTION
        Create a new Site to Netbox

    .EXAMPLE
        New-NBDCIMSite -name MySite

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

#region File New-NBDCIMSiteGroup.ps1

function New-NBDCIMSiteGroup {
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
        New-NBDCIMSiteGroup -Name "Production" -Slug "production"

        Creates a new site group named "Production"

    .EXAMPLE
        New-NBDCIMSiteGroup -Name "DR Sites" -Slug "dr-sites" -Parent 1

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

#region File New-NBDCIMVirtualChassis.ps1

<#
.SYNOPSIS
    Creates a new CIMVirtualChassis in Netbox D module.

.DESCRIPTION
    Creates a new CIMVirtualChassis in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMVirtualChassis

    Returns all CIMVirtualChassis objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMVirtualChassis {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Domain,
        [uint64]$Master,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','virtual-chassis'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create virtual chassis')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBDCIMVirtualDeviceContext.ps1

<#
.SYNOPSIS
    Creates a new CIMVirtualDeviceContext in Netbox D module.

.DESCRIPTION
    Creates a new CIMVirtualDeviceContext in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMVirtualDeviceContext

    Returns all CIMVirtualDeviceContext objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMVirtualDeviceContext {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][uint64]$Device,
        [ValidateSet('active','planned','offline')][string]$Status = 'active',
        [string]$Identifier,
        [uint64]$Tenant,
        [uint64]$Primary_Ip4,
        [uint64]$Primary_Ip6,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','virtual-device-contexts'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create virtual device context')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBEventRule.ps1

<#
.SYNOPSIS
    Creates a new event rule in Netbox.

.DESCRIPTION
    Creates a new event rule in Netbox Extras module.

.PARAMETER Name
    Name of the event rule.

.PARAMETER Description
    Description of the event rule.

.PARAMETER Enabled
    Whether the event rule is enabled.

.PARAMETER Object_Types
    Object types this rule applies to.

.PARAMETER Type_Create
    Trigger on create events.

.PARAMETER Type_Update
    Trigger on update events.

.PARAMETER Type_Delete
    Trigger on delete events.

.PARAMETER Type_Job_Start
    Trigger on job start events.

.PARAMETER Type_Job_End
    Trigger on job end events.

.PARAMETER Action_Type
    Action type (webhook, script).

.PARAMETER Action_Object_Type
    Action object type.

.PARAMETER Action_Object_Id
    Action object ID.

.PARAMETER Conditions
    Conditions (JSON logic).

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBEventRule -Name "Notify on device create" -Object_Types @("dcim.device") -Type_Create $true -Action_Type "webhook" -Action_Object_Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBEventRule {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$Description,

        [bool]$Enabled,

        [Parameter(Mandatory = $true)]
        [string[]]$Object_Types,

        [bool]$Type_Create,

        [bool]$Type_Update,

        [bool]$Type_Delete,

        [bool]$Type_Job_Start,

        [bool]$Type_Job_End,

        [Parameter(Mandatory = $true)]
        [ValidateSet('webhook', 'script')]
        [string]$Action_Type,

        [string]$Action_Object_Type,

        [uint64]$Action_Object_Id,

        $Conditions,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'event-rules'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Event Rule')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBExportTemplate.ps1

<#
.SYNOPSIS
    Creates a new export template in Netbox.

.DESCRIPTION
    Creates a new export template in Netbox Extras module.

.PARAMETER Name
    Name of the export template.

.PARAMETER Object_Types
    Object types this template applies to.

.PARAMETER Description
    Description of the template.

.PARAMETER Template_Code
    Jinja2 template code.

.PARAMETER Mime_Type
    MIME type for the export.

.PARAMETER File_Extension
    File extension for the export.

.PARAMETER As_Attachment
    Whether to serve as attachment.

.PARAMETER Data_Source
    Data source ID.

.PARAMETER Data_File
    Data file ID.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBExportTemplate -Name "CSV Export" -Object_Types @("dcim.device") -Template_Code "{% for d in queryset %}{{ d.name }}{% endfor %}"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBExportTemplate {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string[]]$Object_Types,

        [string]$Description,

        [string]$Template_Code,

        [string]$Mime_Type,

        [string]$File_Extension,

        [bool]$As_Attachment,

        [uint64]$Data_Source,

        [uint64]$Data_File,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'export-templates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Export Template')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBGroup.ps1

<#
.SYNOPSIS
    Creates a new group in Netbox.

.DESCRIPTION
    Creates a new group in Netbox Users module.

.PARAMETER Name
    Name of the group.

.PARAMETER Permissions
    Array of permission IDs.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBGroup -Name "Network Admins"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [uint64[]]$Permissions,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('users', 'groups'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Group')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBIPAMAddress.ps1


function New-NBIPAMAddress {
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
        New-NBIPAMAddress -Address 192.0.2.1/32

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

#region File New-NBIPAMAddressRange.ps1



function New-NBIPAMAddressRange {
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
        New-NBIPAMAddressRange -Start_Address 192.0.2.20/24 -End_Address 192.0.2.20/24

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

#region File New-NBIPAMAggregate.ps1

<#
.SYNOPSIS
    Creates a new PAMAggregate in Netbox I module.

.DESCRIPTION
    Creates a new PAMAggregate in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBIPAMAggregate

    Returns all PAMAggregate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBIPAMAggregate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Prefix,
        [Parameter(Mandatory = $true)][uint64]$RIR,
        [uint64]$Tenant,
        [datetime]$Date_Added,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'aggregates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments
        if ($PSCmdlet.ShouldProcess($Prefix, 'Create aggregate')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBIPAMASN.ps1

function New-NBIPAMASN {
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
        New-NBIPAMASN -ASN 65001

        Creates ASN 65001

    .EXAMPLE
        New-NBIPAMASN -ASN 65001 -RIR 1 -Description "Primary ASN"

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

#region File New-NBIPAMASNRange.ps1

function New-NBIPAMASNRange {
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
        New-NBIPAMASNRange -Name "Private" -Slug "private" -RIR 1 -Start 64512 -End 65534

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

#region File New-NBIPAMFHRPGroup.ps1

<#
.SYNOPSIS
    Creates a new PAMFHRPGroup in Netbox I module.

.DESCRIPTION
    Creates a new PAMFHRPGroup in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBIPAMFHRPGroup

    Returns all PAMFHRPGroup objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBIPAMFHRPGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][ValidateSet('vrrp2','vrrp3','carp','clusterxl','hsrp','glbp','other')][string]$Protocol,
        [Parameter(Mandatory = $true)][uint16]$Group_Id,
        [string]$Name,
        [string]$Auth_Type,
        [string]$Auth_Key,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam','fhrp-groups'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("$Protocol Group $Group_Id", 'Create FHRP group')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBIPAMFHRPGroupAssignment.ps1

<#
.SYNOPSIS
    Creates a new PAMFHRPGroupAssignment in Netbox I module.

.DESCRIPTION
    Creates a new PAMFHRPGroupAssignment in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBIPAMFHRPGroupAssignment

    Returns all PAMFHRPGroupAssignment objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBIPAMFHRPGroupAssignment {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Group,
        [Parameter(Mandatory = $true)][string]$Interface_Type,
        [Parameter(Mandatory = $true)][uint64]$Interface_Id,
        [uint16]$Priority,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam','fhrp-group-assignments'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("Group $Group Interface $Interface_Id", 'Create FHRP group assignment')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBIPAMPrefix.ps1

<#
.SYNOPSIS
    Creates a new PAMPrefix in Netbox I module.

.DESCRIPTION
    Creates a new PAMPrefix in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBIPAMPrefix

    Returns all PAMPrefix objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function New-NBIPAMPrefix {
    [CmdletBinding(ConfirmImpact = 'low',
        SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
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

#region File New-NBIPAMRIR.ps1

<#
.SYNOPSIS
    Creates a new PAMRIR in Netbox I module.

.DESCRIPTION
    Creates a new PAMRIR in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBIPAMRIR

    Returns all PAMRIR objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBIPAMRIR {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Slug,
        [bool]$Is_Private,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam','rirs'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create RIR')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBIPAMRole.ps1

<#
.SYNOPSIS
    Creates a new PAMRole in Netbox I module.

.DESCRIPTION
    Creates a new PAMRole in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBIPAMRole

    Returns all PAMRole objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBIPAMRole {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Slug,
        [uint16]$Weight,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'roles'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments
        if ($PSCmdlet.ShouldProcess($Name, 'Create IPAM role')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBIPAMRouteTarget.ps1

function New-NBIPAMRouteTarget {
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
        New-NBIPAMRouteTarget -Name "65001:100"

        Creates a new route target with value "65001:100"

    .EXAMPLE
        New-NBIPAMRouteTarget -Name "65001:200" -Description "Customer A import"

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

#region File New-NBIPAMService.ps1

function New-NBIPAMService {
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
        New-NBIPAMService -Name "HTTPS" -Ports @(443) -Protocol tcp -Device 1

        Creates an HTTPS service on device 1

    .EXAMPLE
        New-NBIPAMService -Name "DNS" -Ports @(53) -Protocol udp -Virtual_Machine 1

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

#region File New-NBIPAMServiceTemplate.ps1

function New-NBIPAMServiceTemplate {
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
        New-NBIPAMServiceTemplate -Name "HTTPS" -Ports @(443) -Protocol tcp

        Creates an HTTPS service template

    .EXAMPLE
        New-NBIPAMServiceTemplate -Name "Web Server" -Ports @(80, 443) -Protocol tcp

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

#region File New-NBIPAMVLAN.ps1

function New-NBIPAMVLAN {
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
        PS C:\> Create-NBIPAMAddress

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

#region File New-NBIPAMVLANGroup.ps1

<#
.SYNOPSIS
    Creates a new PAMVLANGroup in Netbox I module.

.DESCRIPTION
    Creates a new PAMVLANGroup in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBIPAMVLANGroup

    Returns all PAMVLANGroup objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBIPAMVLANGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Slug,
        [uint64]$Scope_Type,
        [uint64]$Scope_Id,
        [ValidateRange(1, 4094)][uint16]$Min_Vid,
        [ValidateRange(1, 4094)][uint16]$Max_Vid,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam','vlan-groups'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create VLAN group')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBIPAMVLANTranslationPolicy.ps1

<#
.SYNOPSIS
    Creates a new PAMVLANTranslationPolicy in Netbox I module.

.DESCRIPTION
    Creates a new PAMVLANTranslationPolicy in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBIPAMVLANTranslationPolicy

    Returns all PAMVLANTranslationPolicy objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBIPAMVLANTranslationPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam','vlan-translation-policies'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create VLAN translation policy')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBIPAMVLANTranslationRule.ps1

<#
.SYNOPSIS
    Creates a new PAMVLANTranslationRule in Netbox I module.

.DESCRIPTION
    Creates a new PAMVLANTranslationRule in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBIPAMVLANTranslationRule

    Returns all PAMVLANTranslationRule objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBIPAMVLANTranslationRule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Policy,
        [Parameter(Mandatory = $true)][ValidateRange(1, 4094)][uint16]$Local_Vid,
        [Parameter(Mandatory = $true)][ValidateRange(1, 4094)][uint16]$Remote_Vid,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam','vlan-translation-rules'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("$Local_Vid -> $Remote_Vid", 'Create VLAN translation rule')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBIPAMVRF.ps1

function New-NBIPAMVRF {
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
        New-NBIPAMVRF -Name "Production"

        Creates a new VRF named "Production"

    .EXAMPLE
        New-NBIPAMVRF -Name "Customer-A" -RD "65001:100" -Enforce_Unique $true

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

#region File New-NBJournalEntry.ps1

<#
.SYNOPSIS
    Creates a new journal entry in Netbox.

.DESCRIPTION
    Creates a new journal entry in Netbox Extras module.

.PARAMETER Assigned_Object_Type
    Object type (e.g., "dcim.device").

.PARAMETER Assigned_Object_Id
    Object ID.

.PARAMETER Comments
    Journal entry comments (required).

.PARAMETER Kind
    Entry kind (info, success, warning, danger).

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBJournalEntry -Assigned_Object_Type "dcim.device" -Assigned_Object_Id 1 -Comments "Device maintenance completed"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBJournalEntry {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Assigned_Object_Type,

        [Parameter(Mandatory = $true)]
        [uint64]$Assigned_Object_Id,

        [Parameter(Mandatory = $true)]
        [string]$Comments,

        [ValidateSet('info', 'success', 'warning', 'danger')]
        [string]$Kind,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'journal-entries'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("$Assigned_Object_Type $Assigned_Object_Id", 'Create Journal Entry')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBPermission.ps1

<#
.SYNOPSIS
    Creates a new permission in Netbox.

.DESCRIPTION
    Creates a new permission in Netbox Users module.

.PARAMETER Name
    Name of the permission.

.PARAMETER Description
    Description of the permission.

.PARAMETER Enabled
    Whether the permission is enabled.

.PARAMETER Object_Types
    Object types this permission applies to.

.PARAMETER Actions
    Allowed actions (view, add, change, delete).

.PARAMETER Constraints
    JSON constraints for filtering objects.

.PARAMETER Groups
    Array of group IDs.

.PARAMETER Users
    Array of user IDs.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBPermission -Name "View Devices" -Object_Types @("dcim.device") -Actions @("view")

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBPermission {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$Description,

        [bool]$Enabled,

        [Parameter(Mandatory = $true)]
        [string[]]$Object_Types,

        [Parameter(Mandatory = $true)]
        [ValidateSet('view', 'add', 'change', 'delete')]
        [string[]]$Actions,

        $Constraints,

        [uint64[]]$Groups,

        [uint64[]]$Users,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('users', 'permissions'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Permission')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBSavedFilter.ps1

<#
.SYNOPSIS
    Creates a new saved filter in Netbox.

.DESCRIPTION
    Creates a new saved filter in Netbox Extras module.

.PARAMETER Name
    Name of the saved filter.

.PARAMETER Slug
    URL-friendly slug.

.PARAMETER Object_Types
    Object types this filter applies to.

.PARAMETER Description
    Description of the filter.

.PARAMETER Weight
    Display weight.

.PARAMETER Enabled
    Whether the filter is enabled.

.PARAMETER Shared
    Whether the filter is shared.

.PARAMETER Parameters
    Filter parameters (hashtable).

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBSavedFilter -Name "Active Devices" -Slug "active-devices" -Object_Types @("dcim.device") -Parameters @{status = "active"}

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBSavedFilter {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Slug,

        [Parameter(Mandatory = $true)]
        [string[]]$Object_Types,

        [string]$Description,

        [uint16]$Weight,

        [bool]$Enabled,

        [bool]$Shared,

        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'saved-filters'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Saved Filter')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBTag.ps1

<#
.SYNOPSIS
    Creates a new tag in Netbox.

.DESCRIPTION
    Creates a new tag in Netbox Extras module.

.PARAMETER Name
    Name of the tag.

.PARAMETER Slug
    URL-friendly slug.

.PARAMETER Color
    Color code (6 hex characters).

.PARAMETER Description
    Description of the tag.

.PARAMETER Object_Types
    Object types this tag can be applied to.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBTag -Name "Production" -Slug "production" -Color "00ff00"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBTag {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$Slug,

        [ValidatePattern('^[0-9a-fA-F]{6}$')]
        [string]$Color,

        [string]$Description,

        [string[]]$Object_Types,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'tags'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Tag')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBTenant.ps1


function New-NBTenant {
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
        PS C:\> New-NBTenant -Name 'Contoso Inc' -Slug 'contoso-inc'

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

#region File New-NBTenantGroup.ps1

<#
.SYNOPSIS
    Creates a new tenant group in Netbox.

.DESCRIPTION
    Creates a new tenant group in the Netbox tenancy module.
    Tenant groups are organizational containers for grouping related tenants.
    Supports hierarchical nesting via the Parent parameter.

.PARAMETER Name
    The name of the tenant group.

.PARAMETER Slug
    URL-friendly unique identifier. If not provided, will be auto-generated from name.

.PARAMETER Parent
    The database ID of the parent tenant group for hierarchical organization.

.PARAMETER Description
    A description of the tenant group.

.PARAMETER Tags
    Array of tag IDs to assign to this tenant group.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBTenantGroup -Name "Enterprise Customers" -Slug "enterprise-customers"

    Creates a new top-level tenant group.

.EXAMPLE
    New-NBTenantGroup -Name "EMEA" -Parent 1 -Description "European customers"

    Creates a nested tenant group under parent ID 1.

.LINK
    https://netbox.readthedocs.io/en/stable/models/tenancy/tenantgroup/
#>
function New-NBTenantGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$Slug,

        [uint64]$Parent,

        [string]$Description,

        [uint64[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        # Auto-generate slug from name if not provided
        if (-not $PSBoundParameters.ContainsKey('Slug')) {
            $PSBoundParameters['Slug'] = ($Name -replace '\s+', '-').ToLower()
        }

        $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'tenant-groups'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create tenant group')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBToken.ps1

<#
.SYNOPSIS
    Creates a new API token in Netbox.

.DESCRIPTION
    Creates a new API token in Netbox Users module.

.PARAMETER User
    User ID for the token.

.PARAMETER Description
    Description of the token.

.PARAMETER Expires
    Expiration date (datetime).

.PARAMETER Key
    Custom token key (auto-generated if not provided).

.PARAMETER Write_Enabled
    Whether write operations are enabled.

.PARAMETER Allowed_Ips
    Array of allowed IP addresses/networks.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBToken -User 1 -Description "API automation"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBToken {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [uint64]$User,

        [string]$Description,

        [datetime]$Expires,

        [string]$Key,

        [bool]$Write_Enabled,

        [string[]]$Allowed_Ips,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('users', 'tokens'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("User $User", 'Create Token')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBUser.ps1

<#
.SYNOPSIS
    Creates a new user in Netbox.

.DESCRIPTION
    Creates a new user in Netbox Users module.

.PARAMETER Username
    Username for the new user.

.PARAMETER Password
    Password for the new user.

.PARAMETER First_Name
    First name.

.PARAMETER Last_Name
    Last name.

.PARAMETER Email
    Email address.

.PARAMETER Is_Staff
    Whether user has staff access.

.PARAMETER Is_Active
    Whether user is active.

.PARAMETER Is_Superuser
    Whether user is a superuser.

.PARAMETER Groups
    Array of group IDs.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBUser -Username "newuser" -Password "SecureP@ss123"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBUser {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Username,

        [Parameter(Mandatory = $true)]
        [string]$Password,

        [string]$First_Name,

        [string]$Last_Name,

        [string]$Email,

        [bool]$Is_Staff,

        [bool]$Is_Active,

        [bool]$Is_Superuser,

        [uint64[]]$Groups,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('users', 'users'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Username, 'Create User')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBVirtualCircuit.ps1

<#
.SYNOPSIS
    Creates a new virtual circuit in Netbox.

.DESCRIPTION
    Creates a new virtual circuit in Netbox.

.PARAMETER Cid
    Circuit ID string.

.PARAMETER Provider_Network
    Provider network ID.

.PARAMETER Provider_Account
    Provider account ID.

.PARAMETER Type
    Virtual circuit type ID.

.PARAMETER Status
    Status (planned, provisioning, active, offline, deprovisioning, decommissioned).

.PARAMETER Tenant
    Tenant ID.

.PARAMETER Description
    Description.

.PARAMETER Comments
    Comments.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBVirtualCircuit -Cid "VC-001" -Provider_Network 1 -Type 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBVirtualCircuit {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Cid,

        [Parameter(Mandatory = $true)]
        [uint64]$Provider_Network,

        [uint64]$Provider_Account,

        [Parameter(Mandatory = $true)]
        [uint64]$Type,

        [ValidateSet('planned', 'provisioning', 'active', 'offline', 'deprovisioning', 'decommissioned')]
        [string]$Status,

        [uint64]$Tenant,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'virtual-circuits'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Cid, 'Create Virtual Circuit')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBVirtualCircuitTermination.ps1

<#
.SYNOPSIS
    Creates a new virtual circuit termination in Netbox.

.DESCRIPTION
    Creates a new virtual circuit termination in Netbox.

.PARAMETER Virtual_Circuit
    Virtual circuit ID.

.PARAMETER Interface
    Interface ID.

.PARAMETER Role
    Role (peer, hub, spoke).

.PARAMETER Description
    Description.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBVirtualCircuitTermination -Virtual_Circuit 1 -Interface 1 -Role "peer"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBVirtualCircuitTermination {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [uint64]$Virtual_Circuit,

        [Parameter(Mandatory = $true)]
        [uint64]$Interface,

        [ValidateSet('peer', 'hub', 'spoke')]
        [string]$Role,

        [string]$Description,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'virtual-circuit-terminations'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("VC $Virtual_Circuit Interface $Interface", 'Create Virtual Circuit Termination')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBVirtualCircuitType.ps1

<#
.SYNOPSIS
    Creates a new virtual circuit type in Netbox.

.DESCRIPTION
    Creates a new virtual circuit type in Netbox.

.PARAMETER Name
    Name of the virtual circuit type.

.PARAMETER Slug
    URL-friendly slug.

.PARAMETER Color
    Color code (6 hex characters).

.PARAMETER Description
    Description.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBVirtualCircuitType -Name "EVPN" -Slug "evpn"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBVirtualCircuitType {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$Slug,

        [ValidatePattern('^[0-9a-fA-F]{6}$')]
        [string]$Color,

        [string]$Description,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'virtual-circuit-types'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Virtual Circuit Type')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBVirtualizationCluster.ps1

<#
.SYNOPSIS
    Creates a new virtualization cluster in Netbox.

.DESCRIPTION
    Creates a new virtualization cluster in the Netbox virtualization module.
    Clusters represent a pool of resources (hypervisors) that host virtual machines.

.PARAMETER Name
    The name of the cluster.

.PARAMETER Type
    The database ID of the cluster type (e.g., VMware vSphere, KVM, Hyper-V).

.PARAMETER Group
    The database ID of the cluster group this cluster belongs to.

.PARAMETER Site
    The database ID of the site where this cluster is located.

.PARAMETER Status
    The operational status of the cluster: planned, staging, active, decommissioning, offline.

.PARAMETER Tenant
    The database ID of the tenant that owns this cluster.

.PARAMETER Description
    A description of the cluster.

.PARAMETER Comments
    Additional comments about the cluster.

.PARAMETER Tags
    Array of tag IDs to assign to this cluster.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVirtualizationCluster -Name "Production vSphere" -Type 1

    Creates a new cluster with the specified name and type.

.EXAMPLE
    $type = Get-NBVirtualizationClusterType -Name "VMware vSphere"
    New-NBVirtualizationCluster -Name "DC1-Cluster" -Type $type.Id -Site 1 -Status "active"

    Creates a new active cluster associated with a site.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/cluster/
#>
function New-NBVirtualizationCluster {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [uint64]$Type,

        [uint64]$Group,

        [uint64]$Site,

        [ValidateSet('planned', 'staging', 'active', 'decommissioning', 'offline', IgnoreCase = $true)]
        [string]$Status,

        [uint64]$Tenant,

        [string]$Description,

        [string]$Comments,

        [uint64[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'clusters'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create virtualization cluster')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBVirtualizationClusterGroup.ps1

<#
.SYNOPSIS
    Creates a new virtualization cluster group in Netbox.

.DESCRIPTION
    Creates a new cluster group in the Netbox virtualization module.
    Cluster groups are organizational containers for grouping related clusters.

.PARAMETER Name
    The name of the cluster group.

.PARAMETER Slug
    URL-friendly unique identifier. If not provided, will be auto-generated from name.

.PARAMETER Description
    A description of the cluster group.

.PARAMETER Tags
    Array of tag IDs to assign to this cluster group.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVirtualizationClusterGroup -Name "Production Clusters" -Slug "production-clusters"

    Creates a new cluster group with the specified name and slug.

.EXAMPLE
    New-NBVirtualizationClusterGroup -Name "DR Sites" -Description "Disaster recovery clusters"

    Creates a new cluster group with auto-generated slug.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/clustergroup/
#>
function New-NBVirtualizationClusterGroup {
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
        # Auto-generate slug from name if not provided
        if (-not $PSBoundParameters.ContainsKey('Slug')) {
            $PSBoundParameters['Slug'] = ($Name -replace '\s+', '-').ToLower()
        }

        $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'cluster-groups'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create cluster group')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBVirtualizationClusterType.ps1

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

#endregion

#region File New-NBVirtualMachine.ps1

<#
.SYNOPSIS
    Creates a new irtualMachine in Netbox V module.

.DESCRIPTION
    Creates a new irtualMachine in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVirtualMachine

    Returns all irtualMachine objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function New-NBVirtualMachine {
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

#region File New-NBVirtualMachineInterface.ps1

<#
.SYNOPSIS
    Creates a new network interface on a virtual machine in Netbox.

.DESCRIPTION
    Creates a new network interface on a specified virtual machine in the Netbox
    Virtualization module. VM interfaces are used to assign IP addresses and
    configure network connectivity for virtual machines.

.PARAMETER Name
    The name of the interface (e.g., 'eth0', 'ens192', 'Ethernet0').

.PARAMETER Virtual_Machine
    The database ID of the virtual machine to add the interface to.

.PARAMETER Enabled
    Whether the interface is enabled. Defaults to $true if not specified.

.PARAMETER MAC_Address
    The MAC address of the interface in format XX:XX:XX:XX:XX:XX.
    Accepts both uppercase and lowercase hex characters.

.PARAMETER MTU
    Maximum Transmission Unit size. Common values:
    - 1500 for standard Ethernet
    - 9000 for jumbo frames
    Valid range: 1-65535

.PARAMETER Description
    A description of the interface.

.PARAMETER Mode
    VLAN mode for the interface:
    - 'access' - Untagged access port
    - 'tagged' - Trunk port with tagged VLANs
    - 'tagged-all' - Trunk port allowing all VLANs

.PARAMETER Untagged_VLAN
    The database ID of the untagged/native VLAN.

.PARAMETER Tagged_VLANs
    Array of database IDs for tagged VLANs (for trunk ports).

.PARAMETER VRF
    The database ID of the VRF for this interface.

.PARAMETER Tags
    Array of tag IDs to assign to this interface.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVirtualMachineInterface -Name "eth0" -Virtual_Machine 42

    Creates a new enabled interface named 'eth0' on VM ID 42.

.EXAMPLE
    New-NBVirtualMachineInterface -Name "ens192" -Virtual_Machine 42 -MAC_Address "00:50:56:AB:CD:EF"

    Creates a new interface with a specific MAC address.

.EXAMPLE
    $vm = Get-NBVirtualMachine -Name "webserver01"
    New-NBVirtualMachineInterface -Name "eth0" -Virtual_Machine $vm.Id -MTU 9000

    Creates a new interface with jumbo frame support on a VM found by name.

.EXAMPLE
    New-NBVirtualMachineInterface -Name "eth0" -Virtual_Machine 42 -Mode "tagged" -Tagged_VLANs 10,20,30

    Creates a trunk interface with multiple tagged VLANs.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/vminterface/
#>
function New-NBVirtualMachineInterface {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [uint64]$Virtual_Machine,

        [bool]$Enabled = $true,

        [ValidatePattern('^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$')]
        [string]$MAC_Address,

        [ValidateRange(1, 65535)]
        [uint16]$MTU,

        [string]$Description,

        [ValidateSet('access', 'tagged', 'tagged-all', IgnoreCase = $true)]
        [string]$Mode,

        [uint64]$Untagged_VLAN,

        [uint64[]]$Tagged_VLANs,

        [uint64]$VRF,

        [uint64[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'interfaces'))

        # Ensure Enabled is always included in the body (defaults to true)
        $PSBoundParameters['Enabled'] = $Enabled

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("VM $Virtual_Machine", "Create interface '$Name'")) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBVPNIKEPolicy.ps1

<#
.SYNOPSIS
    Creates a new PNIKEPolicy in Netbox V module.

.DESCRIPTION
    Creates a new PNIKEPolicy in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVPNIKEPolicy

    Returns all PNIKEPolicy objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBVPNIKEPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true)][string]$Name,[uint16]$Version,[string]$Mode,[uint64[]]$Proposals,
        [string]$Preshared_Key,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','ike-policies')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create IKE policy')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File New-NBVPNIKEProposal.ps1

<#
.SYNOPSIS
    Creates a new PNIKEProposal in Netbox V module.

.DESCRIPTION
    Creates a new PNIKEProposal in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVPNIKEProposal

    Returns all PNIKEProposal objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBVPNIKEProposal {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true)][string]$Name,[string]$Authentication_Method,[string]$Encryption_Algorithm,
        [string]$Authentication_Algorithm,[uint16]$Group,[uint32]$SA_Lifetime,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','ike-proposals')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create IKE proposal')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File New-NBVPNIPSecPolicy.ps1

<#
.SYNOPSIS
    Creates a new PNIPSecPolicy in Netbox V module.

.DESCRIPTION
    Creates a new PNIPSecPolicy in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVPNIPSecPolicy

    Returns all PNIPSecPolicy objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBVPNIPSecPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true)][string]$Name,[uint64[]]$Proposals,[bool]$Pfs_Group,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-policies')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create IPSec policy')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File New-NBVPNIPSecProfile.ps1

<#
.SYNOPSIS
    Creates a new PNIPSecProfile in Netbox V module.

.DESCRIPTION
    Creates a new PNIPSecProfile in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVPNIPSecProfile

    Returns all PNIPSecProfile objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBVPNIPSecProfile {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true)][string]$Name,[string]$Mode,[uint64]$IKE_Policy,[uint64]$IPSec_Policy,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-profiles')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create IPSec profile')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File New-NBVPNIPSecProposal.ps1

<#
.SYNOPSIS
    Creates a new PNIPSecProposal in Netbox V module.

.DESCRIPTION
    Creates a new PNIPSecProposal in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVPNIPSecProposal

    Returns all PNIPSecProposal objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBVPNIPSecProposal {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true)][string]$Name,[string]$Encryption_Algorithm,[string]$Authentication_Algorithm,[uint32]$SA_Lifetime_Seconds,[uint32]$SA_Lifetime_Data,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-proposals')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create IPSec proposal')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File New-NBVPNL2VPN.ps1

<#
.SYNOPSIS
    Creates a new PNL2VPN in Netbox V module.

.DESCRIPTION
    Creates a new PNL2VPN in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVPNL2VPN

    Returns all PNL2VPN objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBVPNL2VPN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true)][string]$Name,[Parameter(Mandatory = $true)][string]$Slug,
        [uint64]$Identifier,[string]$Type,[string]$Status,[uint64]$Tenant,[string]$Description,[string]$Comments,
        [uint64[]]$Import_Targets,[uint64[]]$Export_Targets,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','l2vpns')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create L2VPN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File New-NBVPNL2VPNTermination.ps1

<#
.SYNOPSIS
    Creates a new PNL2VPNTermination in Netbox V module.

.DESCRIPTION
    Creates a new PNL2VPNTermination in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVPNL2VPNTermination

    Returns all PNL2VPNTermination objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBVPNL2VPNTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true)][uint64]$L2VPN,[Parameter(Mandatory = $true)][string]$Assigned_Object_Type,[Parameter(Mandatory = $true)][uint64]$Assigned_Object_Id,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','l2vpn-terminations')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("L2VPN $L2VPN", 'Create L2VPN termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File New-NBVPNTunnel.ps1

<#
.SYNOPSIS
    Creates a new PNTunnel in Netbox V module.

.DESCRIPTION
    Creates a new PNTunnel in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVPNTunnel

    Returns all PNTunnel objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBVPNTunnel {
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

#region File New-NBVPNTunnelGroup.ps1

<#
.SYNOPSIS
    Creates a new PNTunnelGroup in Netbox V module.

.DESCRIPTION
    Creates a new PNTunnelGroup in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVPNTunnelGroup

    Returns all PNTunnelGroup objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBVPNTunnelGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true)][string]$Name,[Parameter(Mandatory = $true)][string]$Slug,[string]$Description,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','tunnel-groups')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create tunnel group')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File New-NBVPNTunnelTermination.ps1

<#
.SYNOPSIS
    Creates a new PNTunnelTermination in Netbox V module.

.DESCRIPTION
    Creates a new PNTunnelTermination in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVPNTunnelTermination

    Returns all PNTunnelTermination objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBVPNTunnelTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true)][uint64]$Tunnel,[Parameter(Mandatory = $true)][ValidateSet('peer', 'hub', 'spoke')][string]$Role,
        [string]$Termination_Type,[uint64]$Termination_Id,[uint64]$Outside_IP,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','tunnel-terminations')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("Tunnel $Tunnel", 'Create tunnel termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File New-NBWebhook.ps1

<#
.SYNOPSIS
    Creates a new webhook in Netbox.

.DESCRIPTION
    Creates a new webhook in Netbox Extras module.

.PARAMETER Name
    Name of the webhook.

.PARAMETER Payload_Url
    URL to send webhook payload to.

.PARAMETER Description
    Description of the webhook.

.PARAMETER Http_Method
    HTTP method (GET, POST, PUT, PATCH, DELETE).

.PARAMETER Http_Content_Type
    HTTP content type.

.PARAMETER Additional_Headers
    Additional HTTP headers.

.PARAMETER Body_Template
    Body template (Jinja2).

.PARAMETER Secret
    Secret for HMAC signature.

.PARAMETER Ssl_Verification
    Whether to verify SSL certificates.

.PARAMETER Ca_File_Path
    Path to CA certificate file.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBWebhook -Name "Slack Notification" -Payload_Url "https://hooks.slack.com/services/xxx"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBWebhook {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Payload_Url,

        [string]$Description,

        [ValidateSet('GET', 'POST', 'PUT', 'PATCH', 'DELETE')]
        [string]$Http_Method,

        [string]$Http_Content_Type,

        [string]$Additional_Headers,

        [string]$Body_Template,

        [string]$Secret,

        [bool]$Ssl_Verification,

        [string]$Ca_File_Path,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'webhooks'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Webhook')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File New-NBWirelessLAN.ps1

<#
.SYNOPSIS
    Creates a new irelessLAN in Netbox W module.

.DESCRIPTION
    Creates a new irelessLAN in Netbox W module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBWirelessLAN

    Returns all irelessLAN objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBWirelessLAN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true)][string]$SSID,[uint64]$Group,[string]$Status,[uint64]$VLAN,[uint64]$Tenant,
        [string]$Auth_Type,[string]$Auth_Cipher,[string]$Auth_PSK,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('wireless','wireless-lans')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($SSID, 'Create wireless LAN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File New-NBWirelessLANGroup.ps1

<#
.SYNOPSIS
    Creates a new irelessLANGroup in Netbox W module.

.DESCRIPTION
    Creates a new irelessLANGroup in Netbox W module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBWirelessLANGroup

    Returns all irelessLANGroup objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBWirelessLANGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true)][string]$Name,[Parameter(Mandatory = $true)][string]$Slug,[uint64]$Parent,[string]$Description,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('wireless','wireless-lan-groups')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create wireless LAN group')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File New-NBWirelessLink.ps1

<#
.SYNOPSIS
    Creates a new irelessLink in Netbox W module.

.DESCRIPTION
    Creates a new irelessLink in Netbox W module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBWirelessLink

    Returns all irelessLink objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBWirelessLink {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true)][uint64]$Interface_A,[Parameter(Mandatory = $true)][uint64]$Interface_B,
        [string]$SSID,[string]$Status,[uint64]$Tenant,[string]$Auth_Type,[string]$Auth_Cipher,[string]$Auth_PSK,
        [string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('wireless','wireless-links')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("$Interface_A to $Interface_B", 'Create wireless link')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File Remove-NBBookmark.ps1

<#
.SYNOPSIS
    Removes a bookmark from Netbox.

.DESCRIPTION
    Deletes a bookmark from Netbox by ID.

.PARAMETER Id
    The ID of the bookmark to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBBookmark -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBBookmark {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'bookmarks', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Bookmark')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBCircuit.ps1

<#
.SYNOPSIS
    Removes a circuit from Netbox.

.DESCRIPTION
    Deletes a circuit from Netbox by ID.

.PARAMETER Id
    The ID of the circuit to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBCircuit -Id 1

.EXAMPLE
    Get-NBCircuit -Id 1 | Remove-NBCircuit

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBCircuit {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuits', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Circuit')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBCircuitGroup.ps1

<#
.SYNOPSIS
    Removes a circuit group from Netbox.

.DESCRIPTION
    Deletes a circuit group from Netbox by ID.

.PARAMETER Id
    The ID of the circuit group to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBCircuitGroup -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBCircuitGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-groups', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Circuit Group')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBCircuitGroupAssignment.ps1

<#
.SYNOPSIS
    Removes a circuit group assignment from Netbox.

.DESCRIPTION
    Deletes a circuit group assignment from Netbox by ID.

.PARAMETER Id
    The ID of the assignment to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBCircuitGroupAssignment -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBCircuitGroupAssignment {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-group-assignments', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Circuit Group Assignment')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBCircuitProvider.ps1

<#
.SYNOPSIS
    Removes a circuit provider from Netbox.

.DESCRIPTION
    Deletes a circuit provider from Netbox by ID.

.PARAMETER Id
    The ID of the provider to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBCircuitProvider -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBCircuitProvider {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'providers', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Circuit Provider')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBCircuitProviderAccount.ps1

<#
.SYNOPSIS
    Removes a provider account from Netbox.

.DESCRIPTION
    Deletes a provider account from Netbox by ID.

.PARAMETER Id
    The ID of the provider account to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBCircuitProviderAccount -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBCircuitProviderAccount {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'provider-accounts', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Provider Account')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBCircuitProviderNetwork.ps1

<#
.SYNOPSIS
    Removes a provider network from Netbox.

.DESCRIPTION
    Deletes a provider network from Netbox by ID.

.PARAMETER Id
    The ID of the provider network to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBCircuitProviderNetwork -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBCircuitProviderNetwork {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'provider-networks', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Provider Network')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBCircuitTermination.ps1

<#
.SYNOPSIS
    Removes a circuit termination from Netbox.

.DESCRIPTION
    Deletes a circuit termination from Netbox by ID.

.PARAMETER Id
    The ID of the circuit termination to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBCircuitTermination -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBCircuitTermination {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-terminations', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Circuit Termination')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBCircuitType.ps1

<#
.SYNOPSIS
    Removes a circuit type from Netbox.

.DESCRIPTION
    Deletes a circuit type from Netbox by ID.

.PARAMETER Id
    The ID of the circuit type to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBCircuitType -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBCircuitType {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-types', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Circuit Type')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBConfigContext.ps1

<#
.SYNOPSIS
    Removes a config context from Netbox.

.DESCRIPTION
    Deletes a config context from Netbox by ID.

.PARAMETER Id
    The ID of the config context to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBConfigContext -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBConfigContext {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'config-contexts', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Config Context')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBContact.ps1

<#
.SYNOPSIS
    Removes a contact from Netbox.

.DESCRIPTION
    Removes a contact from the Netbox tenancy module.
    Supports pipeline input from Get-NBContact.

.PARAMETER Id
    The database ID(s) of the contact(s) to remove. Accepts pipeline input.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBContact -Id 1

    Removes contact ID 1 (with confirmation prompt).

.EXAMPLE
    Remove-NBContact -Id 1, 2, 3 -Force

    Removes multiple contacts without confirmation.

.EXAMPLE
    Get-NBContact -Group_Id 5 | Remove-NBContact

    Removes all contacts in a specific group via pipeline.

.LINK
    https://netbox.readthedocs.io/en/stable/models/tenancy/contact/
#>
function Remove-NBContact {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        foreach ($ContactId in $Id) {
            $CurrentContact = Get-NBContact -Id $ContactId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contacts', $CurrentContact.Id))

            $URI = BuildNewURI -Segments $Segments

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentContact.Name)", 'Delete contact')) {
                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Remove-NBContactAssignment.ps1

<#
.SYNOPSIS
    Removes a contact assignment from Netbox.

.DESCRIPTION
    Removes a contact assignment from the Netbox tenancy module.
    Contact assignments link contacts to objects (sites, devices, circuits, etc.).
    Supports pipeline input from Get-NBContactAssignment.

.PARAMETER Id
    The database ID(s) of the contact assignment(s) to remove. Accepts pipeline input.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBContactAssignment -Id 1

    Removes contact assignment ID 1 (with confirmation prompt).

.EXAMPLE
    Remove-NBContactAssignment -Id 1, 2, 3 -Force

    Removes multiple contact assignments without confirmation.

.EXAMPLE
    Get-NBContactAssignment -Contact_Id 5 | Remove-NBContactAssignment

    Removes all assignments for a specific contact via pipeline.

.LINK
    https://netbox.readthedocs.io/en/stable/models/tenancy/contactassignment/
#>
function Remove-NBContactAssignment {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        foreach ($AssignmentId in $Id) {
            $CurrentAssignment = Get-NBContactAssignment -Id $AssignmentId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contact-assignments', $CurrentAssignment.Id))

            $URI = BuildNewURI -Segments $Segments

            # Build descriptive target for confirmation
            $Target = "Assignment ID $($CurrentAssignment.Id)"
            if ($CurrentAssignment.Contact -and $CurrentAssignment.Object) {
                $Target = "Contact '$($CurrentAssignment.Contact.Name)' -> '$($CurrentAssignment.Object.Name)'"
            }

            if ($Force -or $PSCmdlet.ShouldProcess($Target, 'Delete contact assignment')) {
                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Remove-NBContactRole.ps1

<#
.SYNOPSIS
    Removes a contact role from Netbox.

.DESCRIPTION
    Removes a contact role from the Netbox tenancy module.
    Supports pipeline input from Get-NBContactRole.

.PARAMETER Id
    The database ID(s) of the contact role(s) to remove. Accepts pipeline input.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBContactRole -Id 1

    Removes contact role ID 1 (with confirmation prompt).

.EXAMPLE
    Get-NBContactRole | Where-Object { $_.name -like "Test*" } | Remove-NBContactRole -Force

    Removes all contact roles matching a pattern without confirmation.

.LINK
    https://netbox.readthedocs.io/en/stable/models/tenancy/contactrole/
#>
function Remove-NBContactRole {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        foreach ($RoleId in $Id) {
            $CurrentRole = Get-NBContactRole -Id $RoleId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contact-roles', $CurrentRole.Id))

            $URI = BuildNewURI -Segments $Segments

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentRole.Name)", 'Delete contact role')) {
                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Remove-NBCustomField.ps1

<#
.SYNOPSIS
    Removes a custom field from Netbox.

.DESCRIPTION
    Deletes a custom field from Netbox by ID.

.PARAMETER Id
    The ID of the custom field to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBCustomField -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBCustomField {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-fields', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Custom Field')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBCustomFieldChoiceSet.ps1

<#
.SYNOPSIS
    Removes a custom field choice set from Netbox.

.DESCRIPTION
    Deletes a custom field choice set from Netbox by ID.

.PARAMETER Id
    The ID of the choice set to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBCustomFieldChoiceSet -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBCustomFieldChoiceSet {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-field-choice-sets', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Custom Field Choice Set')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBCustomLink.ps1

<#
.SYNOPSIS
    Removes a custom link from Netbox.

.DESCRIPTION
    Deletes a custom link from Netbox by ID.

.PARAMETER Id
    The ID of the custom link to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBCustomLink -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBCustomLink {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-links', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Custom Link')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDataSource.ps1

<#
.SYNOPSIS
    Removes a data source from Netbox.

.DESCRIPTION
    Deletes a data source from Netbox by ID.

.PARAMETER Id
    The ID of the data source to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBDataSource -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDataSource {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('core', 'data-sources', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Data Source')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMCable.ps1

<#
.SYNOPSIS
    Removes a CIMCable from Netbox D module.

.DESCRIPTION
    Removes a CIMCable from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMCable

    Returns all CIMCable objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMCable {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete cable')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','cables',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMConsolePort.ps1

<#
.SYNOPSIS
    Removes a CIMConsolePort from Netbox D module.

.DESCRIPTION
    Removes a CIMConsolePort from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMConsolePort

    Returns all CIMConsolePort objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMConsolePort {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete console port')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','console-ports',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMConsolePortTemplate.ps1

<#
.SYNOPSIS
    Removes a CIMConsolePortTemplate from Netbox D module.

.DESCRIPTION
    Removes a CIMConsolePortTemplate from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMConsolePortTemplate

    Returns all CIMConsolePortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMConsolePortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete console port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','console-port-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMConsoleServerPort.ps1

<#
.SYNOPSIS
    Removes a CIMConsoleServerPort from Netbox D module.

.DESCRIPTION
    Removes a CIMConsoleServerPort from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMConsoleServerPort

    Returns all CIMConsoleServerPort objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMConsoleServerPort {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete console server port')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','console-server-ports',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMConsoleServerPortTemplate.ps1

<#
.SYNOPSIS
    Removes a CIMConsoleServerPortTemplate from Netbox D module.

.DESCRIPTION
    Removes a CIMConsoleServerPortTemplate from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMConsoleServerPortTemplate

    Returns all CIMConsoleServerPortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMConsoleServerPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete console server port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','console-server-port-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMDevice.ps1


function Remove-NBDCIMDevice {
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
        PS C:\> Remove-NBDCIMDevice -Id $value1

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
            $CurrentDevice = Get-NBDCIMDevice -Id $DeviceID -ErrorAction Stop

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

#region File Remove-NBDCIMDeviceBay.ps1

<#
.SYNOPSIS
    Removes a CIMDeviceBay from Netbox D module.

.DESCRIPTION
    Removes a CIMDeviceBay from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMDeviceBay

    Returns all CIMDeviceBay objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMDeviceBay {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete device bay')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','device-bays',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMDeviceBayTemplate.ps1

<#
.SYNOPSIS
    Removes a CIMDeviceBayTemplate from Netbox D module.

.DESCRIPTION
    Removes a CIMDeviceBayTemplate from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMDeviceBayTemplate

    Returns all CIMDeviceBayTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMDeviceBayTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete device bay template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','device-bay-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMDeviceRole.ps1

<#
.SYNOPSIS
    Removes a CIMDeviceRole from Netbox D module.

.DESCRIPTION
    Removes a CIMDeviceRole from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMDeviceRole

    Returns all CIMDeviceRole objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMDeviceRole {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete device role')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','device-roles',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMDeviceType.ps1

<#
.SYNOPSIS
    Removes a CIMDeviceType from Netbox D module.

.DESCRIPTION
    Removes a CIMDeviceType from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMDeviceType

    Returns all CIMDeviceType objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMDeviceType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete device type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','device-types',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMFrontPort.ps1

<#
.SYNOPSIS
    Removes a CIMFrontPort from Netbox D module.

.DESCRIPTION
    Removes a CIMFrontPort from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMFrontPort

    Returns all CIMFrontPort objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMFrontPort {

    [CmdletBinding(ConfirmImpact = 'High',
        SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
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
            $CurrentPort = Get-NBDCIMFrontPort -Id $FrontPortID -ErrorAction Stop

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

#region File Remove-NBDCIMFrontPortTemplate.ps1

<#
.SYNOPSIS
    Removes a CIMFrontPortTemplate from Netbox D module.

.DESCRIPTION
    Removes a CIMFrontPortTemplate from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMFrontPortTemplate

    Returns all CIMFrontPortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMFrontPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete front port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','front-port-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMInterface.ps1

function Remove-NBDCIMInterface {
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
        		PS C:\> Remove-NBDCIMInterface -Id $value1

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
            $CurrentInterface = Get-NBDCIMInterface -Id $InterfaceId -ErrorAction Stop

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

#region File Remove-NBDCIMInterfaceConnection.ps1

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
        [uint64[]]$Id,

        [switch]$Force
    )

    begin {

    }

    process {
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

#endregion

#region File Remove-NBDCIMInterfaceTemplate.ps1

<#
.SYNOPSIS
    Removes a CIMInterfaceTemplate from Netbox D module.

.DESCRIPTION
    Removes a CIMInterfaceTemplate from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMInterfaceTemplate

    Returns all CIMInterfaceTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMInterfaceTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete interface template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','interface-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMInventoryItem.ps1

<#
.SYNOPSIS
    Removes a CIMInventoryItem from Netbox D module.

.DESCRIPTION
    Removes a CIMInventoryItem from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMInventoryItem

    Returns all CIMInventoryItem objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMInventoryItem {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete inventory item')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','inventory-items',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMInventoryItemRole.ps1

<#
.SYNOPSIS
    Removes a CIMInventoryItemRole from Netbox D module.

.DESCRIPTION
    Removes a CIMInventoryItemRole from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMInventoryItemRole

    Returns all CIMInventoryItemRole objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMInventoryItemRole {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete inventory item role')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','inventory-item-roles',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMInventoryItemTemplate.ps1

<#
.SYNOPSIS
    Removes a CIMInventoryItemTemplate from Netbox D module.

.DESCRIPTION
    Removes a CIMInventoryItemTemplate from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMInventoryItemTemplate

    Returns all CIMInventoryItemTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMInventoryItemTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete inventory item template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','inventory-item-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMLocation.ps1

function Remove-NBDCIMLocation {
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
        Remove-NBDCIMLocation -Id 1

        Deletes location with ID 1

    .EXAMPLE
        Get-NBDCIMLocation -Name "Old Room" | Remove-NBDCIMLocation

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

#region File Remove-NBDCIMMACAddress.ps1

<#
.SYNOPSIS
    Removes a CIMMACAddress from Netbox D module.

.DESCRIPTION
    Removes a CIMMACAddress from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMMACAddress

    Returns all CIMMACAddress objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMMACAddress {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete MAC address')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','mac-addresses',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMManufacturer.ps1

function Remove-NBDCIMManufacturer {
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
        Remove-NBDCIMManufacturer -Id 1

        Deletes manufacturer with ID 1 (with confirmation)

    .EXAMPLE
        Remove-NBDCIMManufacturer -Id 1 -Confirm:$false

        Deletes manufacturer with ID 1 without confirmation

    .EXAMPLE
        Get-NBDCIMManufacturer -Name "OldVendor" | Remove-NBDCIMManufacturer

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
            $CurrentManufacturer = Get-NBDCIMManufacturer -Id $ManufacturerId -ErrorAction Stop

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentManufacturer.Name)", "Delete manufacturer")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'manufacturers', $CurrentManufacturer.Id))

                $URI = BuildNewURI -Segments $Segments

                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Remove-NBDCIMModule.ps1

<#
.SYNOPSIS
    Removes a CIMModule from Netbox D module.

.DESCRIPTION
    Removes a CIMModule from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMModule

    Returns all CIMModule objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMModule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete module')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','modules',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMModuleBay.ps1

<#
.SYNOPSIS
    Removes a CIMModuleBay from Netbox D module.

.DESCRIPTION
    Removes a CIMModuleBay from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMModuleBay

    Returns all CIMModuleBay objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMModuleBay {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete module bay')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','module-bays',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMModuleBayTemplate.ps1

<#
.SYNOPSIS
    Removes a CIMModuleBayTemplate from Netbox D module.

.DESCRIPTION
    Removes a CIMModuleBayTemplate from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMModuleBayTemplate

    Returns all CIMModuleBayTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMModuleBayTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete module bay template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','module-bay-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMModuleType.ps1

<#
.SYNOPSIS
    Removes a CIMModuleType from Netbox D module.

.DESCRIPTION
    Removes a CIMModuleType from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMModuleType

    Returns all CIMModuleType objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMModuleType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete module type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','module-types',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMModuleTypeProfile.ps1

<#
.SYNOPSIS
    Removes a CIMModuleTypeProfile from Netbox D module.

.DESCRIPTION
    Removes a CIMModuleTypeProfile from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMModuleTypeProfile

    Returns all CIMModuleTypeProfile objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMModuleTypeProfile {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete module type profile')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','module-type-profiles',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMPlatform.ps1

<#
.SYNOPSIS
    Removes a CIMPlatform from Netbox D module.

.DESCRIPTION
    Removes a CIMPlatform from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMPlatform

    Returns all CIMPlatform objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMPlatform {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete platform')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','platforms',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMPowerFeed.ps1

<#
.SYNOPSIS
    Removes a CIMPowerFeed from Netbox D module.

.DESCRIPTION
    Removes a CIMPowerFeed from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMPowerFeed

    Returns all CIMPowerFeed objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMPowerFeed {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete power feed')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','power-feeds',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMPowerOutlet.ps1

<#
.SYNOPSIS
    Removes a CIMPowerOutlet from Netbox D module.

.DESCRIPTION
    Removes a CIMPowerOutlet from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMPowerOutlet

    Returns all CIMPowerOutlet objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMPowerOutlet {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete power outlet')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','power-outlets',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMPowerOutletTemplate.ps1

<#
.SYNOPSIS
    Removes a CIMPowerOutletTemplate from Netbox D module.

.DESCRIPTION
    Removes a CIMPowerOutletTemplate from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMPowerOutletTemplate

    Returns all CIMPowerOutletTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMPowerOutletTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete power outlet template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','power-outlet-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMPowerPanel.ps1

<#
.SYNOPSIS
    Removes a CIMPowerPanel from Netbox D module.

.DESCRIPTION
    Removes a CIMPowerPanel from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMPowerPanel

    Returns all CIMPowerPanel objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMPowerPanel {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete power panel')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','power-panels',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMPowerPort.ps1

<#
.SYNOPSIS
    Removes a CIMPowerPort from Netbox D module.

.DESCRIPTION
    Removes a CIMPowerPort from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMPowerPort

    Returns all CIMPowerPort objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMPowerPort {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete power port')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','power-ports',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMPowerPortTemplate.ps1

<#
.SYNOPSIS
    Removes a CIMPowerPortTemplate from Netbox D module.

.DESCRIPTION
    Removes a CIMPowerPortTemplate from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMPowerPortTemplate

    Returns all CIMPowerPortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMPowerPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete power port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','power-port-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMRack.ps1

function Remove-NBDCIMRack {
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
        Remove-NBDCIMRack -Id 1

        Deletes rack with ID 1 (with confirmation)

    .EXAMPLE
        Remove-NBDCIMRack -Id 1 -Confirm:$false

        Deletes rack with ID 1 without confirmation

    .EXAMPLE
        Get-NBDCIMRack -Name "Rack-01" | Remove-NBDCIMRack

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
            $CurrentRack = Get-NBDCIMRack -Id $RackId -ErrorAction Stop

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentRack.Name)", "Delete rack")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'racks', $CurrentRack.Id))

                $URI = BuildNewURI -Segments $Segments

                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Remove-NBDCIMRackReservation.ps1

<#
.SYNOPSIS
    Removes a CIMRackReservation from Netbox D module.

.DESCRIPTION
    Removes a CIMRackReservation from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMRackReservation

    Returns all CIMRackReservation objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMRackReservation {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete rack reservation')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','rack-reservations',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMRackRole.ps1

<#
.SYNOPSIS
    Removes a CIMRackRole from Netbox D module.

.DESCRIPTION
    Removes a CIMRackRole from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMRackRole

    Returns all CIMRackRole objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMRackRole {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete rack role')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','rack-roles',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMRackType.ps1

<#
.SYNOPSIS
    Removes a CIMRackType from Netbox D module.

.DESCRIPTION
    Removes a CIMRackType from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMRackType

    Returns all CIMRackType objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMRackType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete rack type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','rack-types',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMRearPort.ps1

<#
.SYNOPSIS
    Removes a CIMRearPort from Netbox D module.

.DESCRIPTION
    Removes a CIMRearPort from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMRearPort

    Returns all CIMRearPort objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMRearPort {

    [CmdletBinding(ConfirmImpact = 'High',
        SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
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
            $CurrentPort = Get-NBDCIMRearPort -Id $RearPortID -ErrorAction Stop

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

#region File Remove-NBDCIMRearPortTemplate.ps1

<#
.SYNOPSIS
    Removes a CIMRearPortTemplate from Netbox D module.

.DESCRIPTION
    Removes a CIMRearPortTemplate from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMRearPortTemplate

    Returns all CIMRearPortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMRearPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete rear port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','rear-port-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMRegion.ps1

function Remove-NBDCIMRegion {
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
        Remove-NBDCIMRegion -Id 1

        Deletes region with ID 1

    .EXAMPLE
        Get-NBDCIMRegion -Name "Old Region" | Remove-NBDCIMRegion

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

#region File Remove-NBDCIMSite.ps1

<#
    .NOTES
    ===========================================================================
     Created with:  SAPIEN Technologies, Inc., PowerShell Studio 2020 v5.7.181
     Created on:    2020-10-02 15:52
     Created by:    Claussen
     Organization:  NEOnet
     Filename:      New-NBDCIMSite.ps1
    ===========================================================================
    .DESCRIPTION
        A description of the file.
#>


function Remove-NBDCIMSite {
    <#
        .SYNOPSIS
            Remove a Site

        .DESCRIPTION
            Remove a DCIM Site from Netbox

        .EXAMPLE
            Remove-NBDCIMSite -Id 1

            Remove DCM Site with id 1

        .EXAMPLE
            Get-NBDCIMSite -name My Site | Remove-NBDCIMSite -confirm:$false

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
        $CurrentSite = Get-NBDCIMSite -Id $Id -ErrorAction Stop

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

#region File Remove-NBDCIMSiteGroup.ps1

function Remove-NBDCIMSiteGroup {
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
        Remove-NBDCIMSiteGroup -Id 1

        Deletes site group with ID 1

    .EXAMPLE
        Get-NBDCIMSiteGroup -Name "Old Group" | Remove-NBDCIMSiteGroup

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

#region File Remove-NBDCIMVirtualChassis.ps1

<#
.SYNOPSIS
    Removes a CIMVirtualChassis from Netbox D module.

.DESCRIPTION
    Removes a CIMVirtualChassis from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMVirtualChassis

    Returns all CIMVirtualChassis objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMVirtualChassis {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete virtual chassis')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','virtual-chassis',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBDCIMVirtualDeviceContext.ps1

<#
.SYNOPSIS
    Removes a CIMVirtualDeviceContext from Netbox D module.

.DESCRIPTION
    Removes a CIMVirtualDeviceContext from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMVirtualDeviceContext

    Returns all CIMVirtualDeviceContext objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMVirtualDeviceContext {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete virtual device context')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','virtual-device-contexts',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBEventRule.ps1

<#
.SYNOPSIS
    Removes an event rule from Netbox.

.DESCRIPTION
    Deletes an event rule from Netbox by ID.

.PARAMETER Id
    The ID of the event rule to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBEventRule -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBEventRule {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'event-rules', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Event Rule')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBExportTemplate.ps1

<#
.SYNOPSIS
    Removes an export template from Netbox.

.DESCRIPTION
    Deletes an export template from Netbox by ID.

.PARAMETER Id
    The ID of the export template to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBExportTemplate -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBExportTemplate {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'export-templates', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Export Template')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBGroup.ps1

<#
.SYNOPSIS
    Removes a group from Netbox.

.DESCRIPTION
    Deletes a group from Netbox by ID.

.PARAMETER Id
    The ID of the group to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBGroup -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('users', 'groups', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Group')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBImageAttachment.ps1

<#
.SYNOPSIS
    Removes an image attachment from Netbox.

.DESCRIPTION
    Deletes an image attachment from Netbox by ID.

.PARAMETER Id
    The ID of the image attachment to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBImageAttachment -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBImageAttachment {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'image-attachments', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Image Attachment')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBIPAMAddress.ps1


function Remove-NBIPAMAddress {
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
        PS C:\> Remove-NBIPAMAddress -Id $value1

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
            $CurrentIP = Get-NBIPAMAddress -Id $IPId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-addresses', $IPId))

            if ($Force -or $pscmdlet.ShouldProcess($CurrentIP.Address, "Delete")) {
                $URI = BuildNewURI -Segments $Segments

                InvokeNetboxRequest -URI $URI -Method DELETE
            }
        }
    }
}

#endregion

#region File Remove-NBIPAMAddressRange.ps1


function Remove-NBIPAMAddressRange {
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
        PS C:\> Remove-NBIPAMAddressRange -Id 1234

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
            $CurrentRange = Get-NBIPAMAddressRange -Id $Range_Id -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-ranges', $Range_Id))

            if ($Force -or $pscmdlet.ShouldProcess($CurrentRange.start_address, "Delete")) {
                $URI = BuildNewURI -Segments $Segments

                InvokeNetboxRequest -URI $URI -Method DELETE
            }
        }
    }
}

#endregion

#region File Remove-NBIPAMAggregate.ps1

<#
.SYNOPSIS
    Removes a PAMAggregate from Netbox I module.

.DESCRIPTION
    Removes a PAMAggregate from Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBIPAMAggregate

    Returns all PAMAggregate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBIPAMAggregate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete aggregate')) {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'aggregates', $Id))
            $URI = BuildNewURI -Segments $Segments
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBIPAMASN.ps1

function Remove-NBIPAMASN {
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
        Remove-NBIPAMASN -Id 1

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

#region File Remove-NBIPAMASNRange.ps1

function Remove-NBIPAMASNRange {
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
        Remove-NBIPAMASNRange -Id 1

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

#region File Remove-NBIPAMFHRPGroup.ps1

<#
.SYNOPSIS
    Removes a PAMFHRPGroup from Netbox I module.

.DESCRIPTION
    Removes a PAMFHRPGroup from Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBIPAMFHRPGroup

    Returns all PAMFHRPGroup objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBIPAMFHRPGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete FHRP group')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','fhrp-groups',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBIPAMFHRPGroupAssignment.ps1

<#
.SYNOPSIS
    Removes a PAMFHRPGroupAssignment from Netbox I module.

.DESCRIPTION
    Removes a PAMFHRPGroupAssignment from Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBIPAMFHRPGroupAssignment

    Returns all PAMFHRPGroupAssignment objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBIPAMFHRPGroupAssignment {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete FHRP group assignment')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','fhrp-group-assignments',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBIPAMPrefix.ps1

<#
.SYNOPSIS
    Removes a PAMPrefix from Netbox I module.

.DESCRIPTION
    Removes a PAMPrefix from Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBIPAMPrefix

    Returns all PAMPrefix objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBIPAMPrefix {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete prefix')) {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'prefixes', $Id))
            $URI = BuildNewURI -Segments $Segments
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBIPAMRIR.ps1

<#
.SYNOPSIS
    Removes a PAMRIR from Netbox I module.

.DESCRIPTION
    Removes a PAMRIR from Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBIPAMRIR

    Returns all PAMRIR objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBIPAMRIR {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete RIR')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','rirs',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBIPAMRole.ps1

<#
.SYNOPSIS
    Removes a PAMRole from Netbox I module.

.DESCRIPTION
    Removes a PAMRole from Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBIPAMRole

    Returns all PAMRole objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBIPAMRole {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete IPAM role')) {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'roles', $Id))
            $URI = BuildNewURI -Segments $Segments
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBIPAMRouteTarget.ps1

function Remove-NBIPAMRouteTarget {
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
        Remove-NBIPAMRouteTarget -Id 1

        Deletes route target with ID 1

    .EXAMPLE
        Get-NBIPAMRouteTarget -Name "65001:999" | Remove-NBIPAMRouteTarget

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

#region File Remove-NBIPAMService.ps1

function Remove-NBIPAMService {
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
        Remove-NBIPAMService -Id 1

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

#region File Remove-NBIPAMServiceTemplate.ps1

function Remove-NBIPAMServiceTemplate {
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
        Remove-NBIPAMServiceTemplate -Id 1

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

#region File Remove-NBIPAMVLAN.ps1

<#
.SYNOPSIS
    Removes a PAMVLAN from Netbox I module.

.DESCRIPTION
    Removes a PAMVLAN from Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBIPAMVLAN

    Returns all PAMVLAN objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBIPAMVLAN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete VLAN')) {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'vlans', $Id))
            $URI = BuildNewURI -Segments $Segments
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBIPAMVLANGroup.ps1

<#
.SYNOPSIS
    Removes a PAMVLANGroup from Netbox I module.

.DESCRIPTION
    Removes a PAMVLANGroup from Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBIPAMVLANGroup

    Returns all PAMVLANGroup objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBIPAMVLANGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete VLAN group')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','vlan-groups',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBIPAMVLANTranslationPolicy.ps1

<#
.SYNOPSIS
    Removes a PAMVLANTranslationPolicy from Netbox I module.

.DESCRIPTION
    Removes a PAMVLANTranslationPolicy from Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBIPAMVLANTranslationPolicy

    Returns all PAMVLANTranslationPolicy objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBIPAMVLANTranslationPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete VLAN translation policy')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','vlan-translation-policies',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBIPAMVLANTranslationRule.ps1

<#
.SYNOPSIS
    Removes a PAMVLANTranslationRule from Netbox I module.

.DESCRIPTION
    Removes a PAMVLANTranslationRule from Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBIPAMVLANTranslationRule

    Returns all PAMVLANTranslationRule objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBIPAMVLANTranslationRule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete VLAN translation rule')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','vlan-translation-rules',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBIPAMVRF.ps1

function Remove-NBIPAMVRF {
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
        Remove-NBIPAMVRF -Id 1

        Deletes VRF with ID 1

    .EXAMPLE
        Get-NBIPAMVRF -Name "Test-VRF" | Remove-NBIPAMVRF

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

#region File Remove-NBJournalEntry.ps1

<#
.SYNOPSIS
    Removes a journal entry from Netbox.

.DESCRIPTION
    Deletes a journal entry from Netbox by ID.

.PARAMETER Id
    The ID of the journal entry to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBJournalEntry -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBJournalEntry {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'journal-entries', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Journal Entry')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBPermission.ps1

<#
.SYNOPSIS
    Removes a permission from Netbox.

.DESCRIPTION
    Deletes a permission from Netbox by ID.

.PARAMETER Id
    The ID of the permission to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBPermission -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBPermission {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('users', 'permissions', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Permission')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBSavedFilter.ps1

<#
.SYNOPSIS
    Removes a saved filter from Netbox.

.DESCRIPTION
    Deletes a saved filter from Netbox by ID.

.PARAMETER Id
    The ID of the saved filter to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBSavedFilter -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBSavedFilter {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'saved-filters', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Saved Filter')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBTag.ps1

<#
.SYNOPSIS
    Removes a tag from Netbox.

.DESCRIPTION
    Deletes a tag from Netbox by ID.

.PARAMETER Id
    The ID of the tag to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBTag -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBTag {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'tags', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Tag')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBTenant.ps1

<#
.SYNOPSIS
    Removes a tenant from Netbox.

.DESCRIPTION
    Removes a tenant from the Netbox tenancy module.
    Supports pipeline input from Get-NBTenant.

.PARAMETER Id
    The database ID(s) of the tenant(s) to remove. Accepts pipeline input.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBTenant -Id 1

    Removes tenant ID 1 (with confirmation prompt).

.EXAMPLE
    Remove-NBTenant -Id 1, 2, 3 -Force

    Removes multiple tenants without confirmation.

.EXAMPLE
    Get-NBTenant -Group_Id 5 | Remove-NBTenant

    Removes all tenants in a specific group via pipeline.

.LINK
    https://netbox.readthedocs.io/en/stable/models/tenancy/tenant/
#>
function Remove-NBTenant {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        foreach ($TenantId in $Id) {
            $CurrentTenant = Get-NBTenant -Id $TenantId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'tenants', $CurrentTenant.Id))

            $URI = BuildNewURI -Segments $Segments

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentTenant.Name)", 'Delete tenant')) {
                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Remove-NBTenantGroup.ps1

<#
.SYNOPSIS
    Removes a tenant group from Netbox.

.DESCRIPTION
    Removes a tenant group from the Netbox tenancy module.
    Supports pipeline input from Get-NBTenantGroup.

.PARAMETER Id
    The database ID(s) of the tenant group(s) to remove. Accepts pipeline input.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBTenantGroup -Id 1

    Removes tenant group ID 1 (with confirmation prompt).

.EXAMPLE
    Get-NBTenantGroup | Where-Object { $_.tenant_count -eq 0 } | Remove-NBTenantGroup -Force

    Removes all empty tenant groups without confirmation.

.LINK
    https://netbox.readthedocs.io/en/stable/models/tenancy/tenantgroup/
#>
function Remove-NBTenantGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        foreach ($GroupId in $Id) {
            $CurrentGroup = Get-NBTenantGroup -Id $GroupId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'tenant-groups', $CurrentGroup.Id))

            $URI = BuildNewURI -Segments $Segments

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentGroup.Name)", 'Delete tenant group')) {
                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Remove-NBToken.ps1

<#
.SYNOPSIS
    Removes an API token from Netbox.

.DESCRIPTION
    Deletes an API token from Netbox by ID.

.PARAMETER Id
    The ID of the token to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBToken -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBToken {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('users', 'tokens', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Token')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBUser.ps1

<#
.SYNOPSIS
    Removes a user from Netbox.

.DESCRIPTION
    Deletes a user from Netbox by ID.

.PARAMETER Id
    The ID of the user to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBUser -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBUser {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('users', 'users', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete User')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBVirtualCircuit.ps1

<#
.SYNOPSIS
    Removes a virtual circuit from Netbox.

.DESCRIPTION
    Deletes a virtual circuit from Netbox by ID.

.PARAMETER Id
    The ID of the virtual circuit to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBVirtualCircuit -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVirtualCircuit {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'virtual-circuits', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Virtual Circuit')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBVirtualCircuitTermination.ps1

<#
.SYNOPSIS
    Removes a virtual circuit termination from Netbox.

.DESCRIPTION
    Deletes a virtual circuit termination from Netbox by ID.

.PARAMETER Id
    The ID of the termination to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBVirtualCircuitTermination -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVirtualCircuitTermination {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'virtual-circuit-terminations', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Virtual Circuit Termination')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBVirtualCircuitType.ps1

<#
.SYNOPSIS
    Removes a virtual circuit type from Netbox.

.DESCRIPTION
    Deletes a virtual circuit type from Netbox by ID.

.PARAMETER Id
    The ID of the virtual circuit type to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBVirtualCircuitType -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVirtualCircuitType {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'virtual-circuit-types', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Virtual Circuit Type')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBVirtualizationCluster.ps1

<#
.SYNOPSIS
    Removes a virtualization cluster from Netbox.

.DESCRIPTION
    Removes a virtualization cluster from the Netbox virtualization module.
    Supports pipeline input from Get-NBVirtualizationCluster.
    Warning: This will also remove all VMs associated with the cluster.

.PARAMETER Id
    The database ID(s) of the cluster(s) to remove. Accepts pipeline input.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVirtualizationCluster -Id 1

    Removes cluster ID 1 (with confirmation prompt).

.EXAMPLE
    Remove-NBVirtualizationCluster -Id 1, 2, 3 -Force

    Removes multiple clusters without confirmation.

.EXAMPLE
    Get-NBVirtualizationCluster -Name "test-*" | Remove-NBVirtualizationCluster

    Removes all clusters matching the name pattern via pipeline.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/cluster/
#>
function Remove-NBVirtualizationCluster {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        foreach ($ClusterId in $Id) {
            $CurrentCluster = Get-NBVirtualizationCluster -Id $ClusterId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'clusters', $CurrentCluster.Id))

            $URI = BuildNewURI -Segments $Segments

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentCluster.Name)", 'Delete cluster')) {
                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Remove-NBVirtualizationClusterGroup.ps1

<#
.SYNOPSIS
    Removes a virtualization cluster group from Netbox.

.DESCRIPTION
    Removes a cluster group from the Netbox virtualization module.
    Supports pipeline input from Get-NBVirtualizationClusterGroup.

.PARAMETER Id
    The database ID(s) of the cluster group(s) to remove. Accepts pipeline input.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVirtualizationClusterGroup -Id 1

    Removes cluster group ID 1 (with confirmation prompt).

.EXAMPLE
    Get-NBVirtualizationClusterGroup | Where-Object { $_.cluster_count -eq 0 } | Remove-NBVirtualizationClusterGroup -Force

    Removes all empty cluster groups without confirmation.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/clustergroup/
#>
function Remove-NBVirtualizationClusterGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        foreach ($GroupId in $Id) {
            $CurrentGroup = Get-NBVirtualizationClusterGroup -Id $GroupId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'cluster-groups', $CurrentGroup.Id))

            $URI = BuildNewURI -Segments $Segments

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentGroup.Name)", 'Delete cluster group')) {
                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Remove-NBVirtualizationClusterType.ps1

<#
.SYNOPSIS
    Removes a virtualization cluster type from Netbox.

.DESCRIPTION
    Removes a cluster type from the Netbox virtualization module.
    Supports pipeline input from Get-NBVirtualizationClusterType.

.PARAMETER Id
    The database ID(s) of the cluster type(s) to remove. Accepts pipeline input.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVirtualizationClusterType -Id 1

    Removes cluster type ID 1 (with confirmation prompt).

.EXAMPLE
    Get-NBVirtualizationClusterType | Where-Object { $_.cluster_count -eq 0 } | Remove-NBVirtualizationClusterType -Force

    Removes all unused cluster types without confirmation.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/clustertype/
#>
function Remove-NBVirtualizationClusterType {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        foreach ($TypeId in $Id) {
            $CurrentType = Get-NBVirtualizationClusterType -Id $TypeId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'cluster-types', $CurrentType.Id))

            $URI = BuildNewURI -Segments $Segments

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentType.Name)", 'Delete cluster type')) {
                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Remove-NBVirtualMachine.ps1


function Remove-NBVirtualMachine {
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
        PS C:\> Remove-NBVirtualMachine -Id $value1

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
            $CurrentVM = Get-NBVirtualMachine -Id $VMId -ErrorAction Stop

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

#region File Remove-NBVirtualMachineInterface.ps1

<#
.SYNOPSIS
    Removes a virtual machine interface from Netbox.

.DESCRIPTION
    Removes a virtual machine interface from the Netbox virtualization module.
    Supports pipeline input from Get-NBVirtualMachineInterface.
    Warning: This will also remove any IP addresses assigned to the interface.

.PARAMETER Id
    The database ID(s) of the interface(s) to remove. Accepts pipeline input.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVirtualMachineInterface -Id 1

    Removes VM interface ID 1 (with confirmation prompt).

.EXAMPLE
    Remove-NBVirtualMachineInterface -Id 1, 2, 3 -Force

    Removes multiple interfaces without confirmation.

.EXAMPLE
    Get-NBVirtualMachineInterface -Virtual_Machine_Id 5 | Remove-NBVirtualMachineInterface -Force

    Removes all interfaces from VM ID 5 via pipeline.

.EXAMPLE
    Get-NBVirtualMachine -Name "test-vm" | Get-NBVirtualMachineInterface | Remove-NBVirtualMachineInterface

    Removes all interfaces from a VM found by name.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/vminterface/
#>
function Remove-NBVirtualMachineInterface {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        foreach ($InterfaceId in $Id) {
            $CurrentInterface = Get-NBVirtualMachineInterface -Id $InterfaceId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'interfaces', $CurrentInterface.Id))

            $URI = BuildNewURI -Segments $Segments

            # Build descriptive target for confirmation
            $Target = "$($CurrentInterface.Name)"
            if ($CurrentInterface.Virtual_Machine) {
                $Target = "Interface '$($CurrentInterface.Name)' on VM '$($CurrentInterface.Virtual_Machine.Name)'"
            }

            if ($Force -or $PSCmdlet.ShouldProcess($Target, 'Delete interface')) {
                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Remove-NBVPNIKEPolicy.ps1

<#
.SYNOPSIS
    Removes a PNIKEPolicy from Netbox V module.

.DESCRIPTION
    Removes a PNIKEPolicy from Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVPNIKEPolicy

    Returns all PNIKEPolicy objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVPNIKEPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete IKE policy')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ike-policies',$Id)) -Method DELETE -Raw:$Raw } }
}

#endregion

#region File Remove-NBVPNIKEProposal.ps1

<#
.SYNOPSIS
    Removes a PNIKEProposal from Netbox V module.

.DESCRIPTION
    Removes a PNIKEProposal from Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVPNIKEProposal

    Returns all PNIKEProposal objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVPNIKEProposal {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete IKE proposal')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ike-proposals',$Id)) -Method DELETE -Raw:$Raw } }
}

#endregion

#region File Remove-NBVPNIPSecPolicy.ps1

<#
.SYNOPSIS
    Removes a PNIPSecPolicy from Netbox V module.

.DESCRIPTION
    Removes a PNIPSecPolicy from Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVPNIPSecPolicy

    Returns all PNIPSecPolicy objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVPNIPSecPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete IPSec policy')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ipsec-policies',$Id)) -Method DELETE -Raw:$Raw } }
}

#endregion

#region File Remove-NBVPNIPSecProfile.ps1

<#
.SYNOPSIS
    Removes a PNIPSecProfile from Netbox V module.

.DESCRIPTION
    Removes a PNIPSecProfile from Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVPNIPSecProfile

    Returns all PNIPSecProfile objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVPNIPSecProfile {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete IPSec profile')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ipsec-profiles',$Id)) -Method DELETE -Raw:$Raw } }
}

#endregion

#region File Remove-NBVPNIPSecProposal.ps1

<#
.SYNOPSIS
    Removes a PNIPSecProposal from Netbox V module.

.DESCRIPTION
    Removes a PNIPSecProposal from Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVPNIPSecProposal

    Returns all PNIPSecProposal objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVPNIPSecProposal {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete IPSec proposal')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ipsec-proposals',$Id)) -Method DELETE -Raw:$Raw } }
}

#endregion

#region File Remove-NBVPNL2VPN.ps1

<#
.SYNOPSIS
    Removes a PNL2VPN from Netbox V module.

.DESCRIPTION
    Removes a PNL2VPN from Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVPNL2VPN

    Returns all PNL2VPN objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVPNL2VPN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete L2VPN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','l2vpns',$Id)) -Method DELETE -Raw:$Raw } }
}

#endregion

#region File Remove-NBVPNL2VPNTermination.ps1

<#
.SYNOPSIS
    Removes a PNL2VPNTermination from Netbox V module.

.DESCRIPTION
    Removes a PNL2VPNTermination from Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVPNL2VPNTermination

    Returns all PNL2VPNTermination objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVPNL2VPNTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete L2VPN termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','l2vpn-terminations',$Id)) -Method DELETE -Raw:$Raw } }
}

#endregion

#region File Remove-NBVPNTunnel.ps1

<#
.SYNOPSIS
    Removes a PNTunnel from Netbox V module.

.DESCRIPTION
    Removes a PNTunnel from Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVPNTunnel

    Returns all PNTunnel objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVPNTunnel {
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

#region File Remove-NBVPNTunnelGroup.ps1

<#
.SYNOPSIS
    Removes a PNTunnelGroup from Netbox V module.

.DESCRIPTION
    Removes a PNTunnelGroup from Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVPNTunnelGroup

    Returns all PNTunnelGroup objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVPNTunnelGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete tunnel group')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','tunnel-groups',$Id)) -Method DELETE -Raw:$Raw } }
}

#endregion

#region File Remove-NBVPNTunnelTermination.ps1

<#
.SYNOPSIS
    Removes a PNTunnelTermination from Netbox V module.

.DESCRIPTION
    Removes a PNTunnelTermination from Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVPNTunnelTermination

    Returns all PNTunnelTermination objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVPNTunnelTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete tunnel termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','tunnel-terminations',$Id)) -Method DELETE -Raw:$Raw } }
}

#endregion

#region File Remove-NBWebhook.ps1

<#
.SYNOPSIS
    Removes a webhook from Netbox.

.DESCRIPTION
    Deletes a webhook from Netbox by ID.

.PARAMETER Id
    The ID of the webhook to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBWebhook -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBWebhook {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'webhooks', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Webhook')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}

#endregion

#region File Remove-NBWirelessLAN.ps1

<#
.SYNOPSIS
    Removes a irelessLAN from Netbox W module.

.DESCRIPTION
    Removes a irelessLAN from Netbox W module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBWirelessLAN

    Returns all irelessLAN objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBWirelessLAN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete wireless LAN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('wireless','wireless-lans',$Id)) -Method DELETE -Raw:$Raw } }
}

#endregion

#region File Remove-NBWirelessLANGroup.ps1

<#
.SYNOPSIS
    Removes a irelessLANGroup from Netbox W module.

.DESCRIPTION
    Removes a irelessLANGroup from Netbox W module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBWirelessLANGroup

    Returns all irelessLANGroup objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBWirelessLANGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete wireless LAN group')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('wireless','wireless-lan-groups',$Id)) -Method DELETE -Raw:$Raw } }
}

#endregion

#region File Remove-NBWirelessLink.ps1

<#
.SYNOPSIS
    Removes a irelessLink from Netbox W module.

.DESCRIPTION
    Removes a irelessLink from Netbox W module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBWirelessLink

    Returns all irelessLink objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBWirelessLink {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete wireless link')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('wireless','wireless-links',$Id)) -Method DELETE -Raw:$Raw } }
}

#endregion

#region File Set-NBCipherSSL.ps1

function Set-NBCipherSSL {
    <#
    .SYNOPSIS
        Enables modern TLS protocols for PowerShell Desktop (5.1).

    .DESCRIPTION
        Configures ServicePointManager to use TLS 1.2 (and optionally TLS 1.3).
        This is required for PowerShell Desktop (5.1) which defaults to older protocols.
        PowerShell Core (7+) already uses modern TLS by default.

    .NOTES
        This function should only be called on PowerShell Desktop edition.
        SSL3 and TLS 1.0/1.1 are intentionally excluded as they are deprecated.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [CmdletBinding()]
    param()

    # Only apply to Desktop edition (PS 5.1)
    if ($PSVersionTable.PSEdition -ne 'Desktop') {
        Write-Verbose "Skipping TLS configuration - PowerShell Core uses modern TLS by default"
        return
    }

    # Enable TLS 1.2 (required minimum for most modern APIs)
    # TLS 1.3 is available in .NET Framework 4.8+ but may not be on all systems
    try {
        # Try to enable TLS 1.2 and 1.3 if available
        $Protocols = [System.Net.SecurityProtocolType]::Tls12

        # Check if TLS 1.3 is available (requires .NET 4.8+)
        if ([Enum]::IsDefined([System.Net.SecurityProtocolType], 'Tls13')) {
            $Protocols = $Protocols -bor [System.Net.SecurityProtocolType]::Tls13
        }

        [System.Net.ServicePointManager]::SecurityProtocol = $Protocols
        Write-Verbose "Enabled TLS protocols: $([System.Net.ServicePointManager]::SecurityProtocol)"
    } catch {
        # Fallback to TLS 1.2 only
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        Write-Verbose "Enabled TLS 1.2"
    }
}

#endregion

#region File Set-NBCircuit.ps1

<#
.SYNOPSIS
    Updates an existing circuit in Netbox.

.DESCRIPTION
    Updates an existing circuit in Netbox using PATCH method.

.PARAMETER Id
    The ID of the circuit to update.

.PARAMETER CID
    Circuit ID string.

.PARAMETER Provider
    Provider ID.

.PARAMETER Type
    Circuit type ID.

.PARAMETER Status
    Circuit status.

.PARAMETER Description
    Description of the circuit.

.PARAMETER Tenant
    Tenant ID.

.PARAMETER Install_Date
    Installation date.

.PARAMETER Termination_Date
    Termination date.

.PARAMETER Commit_Rate
    Committed rate in Kbps.

.PARAMETER Comments
    Comments.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBCircuit -Id 1 -Description "Updated description"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBCircuit {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$CID,

        [uint64]$Provider,

        [uint64]$Type,

        [string]$Status,

        [string]$Description,

        [uint64]$Tenant,

        [datetime]$Install_Date,

        [datetime]$Termination_Date,

        [ValidateRange(0, 2147483647)]
        [uint64]$Commit_Rate,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuits', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Circuit')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBCircuitGroup.ps1

<#
.SYNOPSIS
    Updates an existing circuit group in Netbox.

.DESCRIPTION
    Updates an existing circuit group in Netbox.

.PARAMETER Id
    The ID of the circuit group to update.

.PARAMETER Name
    Name of the circuit group.

.PARAMETER Slug
    URL-friendly slug.

.PARAMETER Description
    Description.

.PARAMETER Tenant
    Tenant ID.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBCircuitGroup -Id 1 -Description "Updated"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBCircuitGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [string]$Description,

        [uint64]$Tenant,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-groups', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Circuit Group')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBCircuitGroupAssignment.ps1

<#
.SYNOPSIS
    Updates an existing circuit group assignment in Netbox.

.DESCRIPTION
    Updates an existing circuit group assignment in Netbox.

.PARAMETER Id
    The ID of the assignment to update.

.PARAMETER Group
    Circuit group ID.

.PARAMETER Circuit
    Circuit ID.

.PARAMETER Priority
    Priority (primary, secondary, tertiary, inactive).

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBCircuitGroupAssignment -Id 1 -Priority "secondary"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBCircuitGroupAssignment {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [uint64]$Group,

        [uint64]$Circuit,

        [ValidateSet('primary', 'secondary', 'tertiary', 'inactive')]
        [string]$Priority,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-group-assignments', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Circuit Group Assignment')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBCircuitProvider.ps1

<#
.SYNOPSIS
    Updates an existing circuit provider in Netbox.

.DESCRIPTION
    Updates an existing circuit provider in Netbox.

.PARAMETER Id
    The ID of the provider to update.

.PARAMETER Name
    Name of the provider.

.PARAMETER Slug
    URL-friendly slug.

.PARAMETER Description
    Description of the provider.

.PARAMETER Comments
    Comments.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBCircuitProvider -Id 1 -Description "Updated description"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBCircuitProvider {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'providers', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Circuit Provider')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBCircuitProviderAccount.ps1

<#
.SYNOPSIS
    Updates an existing provider account in Netbox.

.DESCRIPTION
    Updates an existing provider account in Netbox.

.PARAMETER Id
    The ID of the provider account to update.

.PARAMETER Provider
    Provider ID.

.PARAMETER Name
    Name of the account.

.PARAMETER Account
    Account number/identifier.

.PARAMETER Description
    Description.

.PARAMETER Comments
    Comments.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBCircuitProviderAccount -Id 1 -Description "Updated"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBCircuitProviderAccount {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [uint64]$Provider,

        [string]$Name,

        [string]$Account,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'provider-accounts', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Provider Account')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBCircuitProviderNetwork.ps1

<#
.SYNOPSIS
    Updates an existing provider network in Netbox.

.DESCRIPTION
    Updates an existing provider network in Netbox.

.PARAMETER Id
    The ID of the provider network to update.

.PARAMETER Provider
    Provider ID.

.PARAMETER Name
    Name of the network.

.PARAMETER Service_Id
    Service identifier.

.PARAMETER Description
    Description.

.PARAMETER Comments
    Comments.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBCircuitProviderNetwork -Id 1 -Description "Updated"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBCircuitProviderNetwork {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [uint64]$Provider,

        [string]$Name,

        [string]$Service_Id,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'provider-networks', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Provider Network')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBCircuitTermination.ps1

<#
.SYNOPSIS
    Updates an existing circuit termination in Netbox.

.DESCRIPTION
    Updates an existing circuit termination in Netbox.

.PARAMETER Id
    The ID of the circuit termination to update.

.PARAMETER Circuit
    Circuit ID.

.PARAMETER Term_Side
    Termination side (A or Z).

.PARAMETER Site
    Site ID.

.PARAMETER Provider_Network
    Provider network ID.

.PARAMETER Port_Speed
    Port speed in Kbps.

.PARAMETER Upstream_Speed
    Upstream speed in Kbps.

.PARAMETER Xconnect_Id
    Cross-connect ID.

.PARAMETER Pp_Info
    Patch panel info.

.PARAMETER Description
    Description.

.PARAMETER Mark_Connected
    Mark as connected.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBCircuitTermination -Id 1 -Port_Speed 10000

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBCircuitTermination {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [uint64]$Circuit,

        [ValidateSet('A', 'Z')]
        [string]$Term_Side,

        [uint64]$Site,

        [uint64]$Provider_Network,

        [uint64]$Port_Speed,

        [uint64]$Upstream_Speed,

        [string]$Xconnect_Id,

        [string]$Pp_Info,

        [string]$Description,

        [bool]$Mark_Connected,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-terminations', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Circuit Termination')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBCircuitType.ps1

<#
.SYNOPSIS
    Updates an existing circuit type in Netbox.

.DESCRIPTION
    Updates an existing circuit type in Netbox.

.PARAMETER Id
    The ID of the circuit type to update.

.PARAMETER Name
    Name of the circuit type.

.PARAMETER Slug
    URL-friendly slug.

.PARAMETER Color
    Color code (6 hex characters).

.PARAMETER Description
    Description of the circuit type.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBCircuitType -Id 1 -Description "Updated description"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBCircuitType {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [ValidatePattern('^[0-9a-fA-F]{6}$')]
        [string]$Color,

        [string]$Description,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-types', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Circuit Type')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBConfigContext.ps1

<#
.SYNOPSIS
    Updates an existing config context in Netbox.

.DESCRIPTION
    Updates an existing config context in Netbox Extras module.

.PARAMETER Id
    The ID of the config context to update.

.PARAMETER Name
    Name of the config context.

.PARAMETER Weight
    Weight for ordering (0-32767).

.PARAMETER Description
    Description of the config context.

.PARAMETER Is_Active
    Whether the config context is active.

.PARAMETER Data
    Configuration data (hashtable or JSON).

.PARAMETER Regions
    Array of region IDs.

.PARAMETER Site_Groups
    Array of site group IDs.

.PARAMETER Sites
    Array of site IDs.

.PARAMETER Locations
    Array of location IDs.

.PARAMETER Device_Types
    Array of device type IDs.

.PARAMETER Roles
    Array of role IDs.

.PARAMETER Platforms
    Array of platform IDs.

.PARAMETER Cluster_Types
    Array of cluster type IDs.

.PARAMETER Cluster_Groups
    Array of cluster group IDs.

.PARAMETER Clusters
    Array of cluster IDs.

.PARAMETER Tenant_Groups
    Array of tenant group IDs.

.PARAMETER Tenants
    Array of tenant IDs.

.PARAMETER Tags
    Array of tag slugs.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBConfigContext -Id 1 -Is_Active $false

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBConfigContext {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [ValidateRange(0, 32767)]
        [uint16]$Weight,

        [string]$Description,

        [bool]$Is_Active,

        $Data,

        [uint64[]]$Regions,

        [uint64[]]$Site_Groups,

        [uint64[]]$Sites,

        [uint64[]]$Locations,

        [uint64[]]$Device_Types,

        [uint64[]]$Roles,

        [uint64[]]$Platforms,

        [uint64[]]$Cluster_Types,

        [uint64[]]$Cluster_Groups,

        [uint64[]]$Clusters,

        [uint64[]]$Tenant_Groups,

        [uint64[]]$Tenants,

        [string[]]$Tags,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'config-contexts', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Config Context')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBContact.ps1


function Set-NBContact {
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
        PS C:\> Set-NBContact -Id 10 -Name 'Leroy Jenkins' -Email 'leroy.jenkins@example.com'

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

            $CurrentContact = Get-NBContact -Id $ContactId -ErrorAction Stop

            if ($Force -or $PSCmdlet.ShouldProcess($CurrentContact.Name, 'Update contact')) {
                InvokeNetboxRequest -URI $URI -Method $Method -Body $URIComponents.Parameters -Raw:$Raw
            }
        }
    }
}





#endregion

#region File Set-NBContactAssignment.ps1



function Set-NBContactAssignment {
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
        PS C:\> Set-NBContactAssignment -Id 11 -Content_Type 'dcim.location' -Object_id 10 -Contact 15 -Role 10 -Priority 'Primary'

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

            $CurrentContactAssignment = Get-NBContactAssignment -Id $ContactAssignmentId -ErrorAction Stop

            if ($PSCmdlet.ShouldProcess($CurrentContactAssignment.Id, 'Update contact assignment')) {
                InvokeNetboxRequest -URI $URI -Method $Method -Body $URIComponents.Parameters -Raw:$Raw
            }
        }
    }
}





#endregion

#region File Set-NBContactRole.ps1


function Set-NBContactRole {
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
        PS C:\> New-NBContact -Name 'Leroy Jenkins' -Email 'leroy.jenkins@example.com'

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

            $CurrentContactRole = Get-NBContactRole -Id $ContactRoleId -ErrorAction Stop

            if ($Force -or $PSCmdlet.ShouldProcess($CurrentContactRole.Name, 'Update contact role')) {
                InvokeNetboxRequest -URI $URI -Method $Method -Body $URIComponents.Parameters -Raw:$Raw
            }
        }
    }
}





#endregion

#region File Set-NBCredential.ps1

<#
.SYNOPSIS
    Updates an existing redential in Netbox C module.

.DESCRIPTION
    Updates an existing redential in Netbox C module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBCredential

    Returns all redential objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBCredential {
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

#region File Set-NBCustomField.ps1

<#
.SYNOPSIS
    Updates an existing custom field in Netbox.

.DESCRIPTION
    Updates an existing custom field in Netbox Extras module.

.PARAMETER Id
    The ID of the custom field to update.

.PARAMETER Name
    Internal name of the custom field.

.PARAMETER Label
    Display label for the custom field.

.PARAMETER Type
    Field type.

.PARAMETER Object_Types
    Content types this field applies to.

.PARAMETER Group_Name
    Group name for organizing fields.

.PARAMETER Description
    Description of the field.

.PARAMETER Required
    Whether this field is required.

.PARAMETER Search_Weight
    Search weight (0-32767).

.PARAMETER Filter_Logic
    Filter logic (disabled, loose, exact).

.PARAMETER Ui_Visible
    UI visibility (always, if-set, hidden).

.PARAMETER Ui_Editable
    UI editability (yes, no, hidden).

.PARAMETER Is_Cloneable
    Whether the field is cloneable.

.PARAMETER Default
    Default value.

.PARAMETER Weight
    Display weight.

.PARAMETER Validation_Minimum
    Minimum value for numeric fields.

.PARAMETER Validation_Maximum
    Maximum value for numeric fields.

.PARAMETER Validation_Regex
    Validation regex pattern.

.PARAMETER Choice_Set
    Choice set ID for select fields.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBCustomField -Id 1 -Label "New Label"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBCustomField {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Label,

        [ValidateSet('text', 'longtext', 'integer', 'decimal', 'boolean', 'date', 'datetime', 'url', 'json', 'select', 'multiselect', 'object', 'multiobject')]
        [string]$Type,

        [string[]]$Object_Types,

        [string]$Group_Name,

        [string]$Description,

        [bool]$Required,

        [ValidateRange(0, 32767)]
        [uint16]$Search_Weight,

        [ValidateSet('disabled', 'loose', 'exact')]
        [string]$Filter_Logic,

        [ValidateSet('always', 'if-set', 'hidden')]
        [string]$Ui_Visible,

        [ValidateSet('yes', 'no', 'hidden')]
        [string]$Ui_Editable,

        [bool]$Is_Cloneable,

        $Default,

        [uint16]$Weight,

        [int64]$Validation_Minimum,

        [int64]$Validation_Maximum,

        [string]$Validation_Regex,

        [uint64]$Choice_Set,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-fields', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Custom Field')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBCustomFieldChoiceSet.ps1

<#
.SYNOPSIS
    Updates an existing custom field choice set in Netbox.

.DESCRIPTION
    Updates an existing custom field choice set in Netbox Extras module.

.PARAMETER Id
    The ID of the choice set to update.

.PARAMETER Name
    Name of the choice set.

.PARAMETER Description
    Description of the choice set.

.PARAMETER Base_Choices
    Base choices to inherit from.

.PARAMETER Extra_Choices
    Array of extra choices.

.PARAMETER Order_Alphabetically
    Whether to order choices alphabetically.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBCustomFieldChoiceSet -Id 1 -Name "Updated Name"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBCustomFieldChoiceSet {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Description,

        [string]$Base_Choices,

        [array]$Extra_Choices,

        [bool]$Order_Alphabetically,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-field-choice-sets', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Custom Field Choice Set')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBCustomLink.ps1

<#
.SYNOPSIS
    Updates an existing custom link in Netbox.

.DESCRIPTION
    Updates an existing custom link in Netbox Extras module.

.PARAMETER Id
    The ID of the custom link to update.

.PARAMETER Name
    Name of the custom link.

.PARAMETER Object_Types
    Object types this link applies to.

.PARAMETER Enabled
    Whether the link is enabled.

.PARAMETER Link_Text
    Link text (Jinja2 template).

.PARAMETER Link_Url
    Link URL (Jinja2 template).

.PARAMETER Weight
    Display weight.

.PARAMETER Group_Name
    Group name for organizing links.

.PARAMETER Button_Class
    Button CSS class.

.PARAMETER New_Window
    Whether to open in new window.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBCustomLink -Id 1 -Enabled $false

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBCustomLink {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string[]]$Object_Types,

        [bool]$Enabled,

        [string]$Link_Text,

        [string]$Link_Url,

        [uint16]$Weight,

        [string]$Group_Name,

        [ValidateSet('outline-dark', 'blue', 'indigo', 'purple', 'pink', 'red', 'orange', 'yellow', 'green', 'teal', 'cyan', 'gray', 'black', 'white', 'ghost-dark')]
        [string]$Button_Class,

        [bool]$New_Window,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-links', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Custom Link')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDataSource.ps1

<#
.SYNOPSIS
    Updates an existing data source in Netbox.

.DESCRIPTION
    Updates an existing data source in Netbox Core module.

.PARAMETER Id
    The ID of the data source to update.

.PARAMETER Name
    Name of the data source.

.PARAMETER Type
    Type of data source (local, git, amazon-s3).

.PARAMETER Source_Url
    Source URL for remote data sources.

.PARAMETER Description
    Description of the data source.

.PARAMETER Enabled
    Whether the data source is enabled.

.PARAMETER Ignore_Rules
    Patterns to ignore (one per line).

.PARAMETER Parameters
    Additional parameters (hashtable).

.PARAMETER Comments
    Comments.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBDataSource -Id 1 -Enabled $false

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDataSource {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [ValidateSet('local', 'git', 'amazon-s3')]
        [string]$Type,

        [string]$Source_Url,

        [string]$Description,

        [bool]$Enabled,

        [string]$Ignore_Rules,

        [hashtable]$Parameters,

        [string]$Comments,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('core', 'data-sources', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Data Source')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMCable.ps1

<#
.SYNOPSIS
    Updates an existing CIMCable in Netbox D module.

.DESCRIPTION
    Updates an existing CIMCable in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMCable

    Returns all CIMCable objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMCable {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Type,
        [string]$Status,
        [uint64]$Tenant,
        [string]$Label,
        [string]$Color,
        [decimal]$Length,
        [string]$Length_Unit,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','cables',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update cable')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMConsolePort.ps1

<#
.SYNOPSIS
    Updates an existing CIMConsolePort in Netbox D module.

.DESCRIPTION
    Updates an existing CIMConsolePort in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMConsolePort

    Returns all CIMConsolePort objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMConsolePort {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device,
        [string]$Name,
        [uint64]$Module,
        [string]$Label,
        [string]$Type,
        [uint16]$Speed,
        [bool]$Mark_Connected,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','console-ports',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update console port')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMConsolePortTemplate.ps1

<#
.SYNOPSIS
    Updates an existing CIMConsolePortTemplate in Netbox D module.

.DESCRIPTION
    Updates an existing CIMConsolePortTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMConsolePortTemplate

    Returns all CIMConsolePortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMConsolePortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [string]$Name,
        [string]$Label,
        [string]$Type,
        [string]$Description,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','console-port-templates',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update console port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMConsoleServerPort.ps1

<#
.SYNOPSIS
    Updates an existing CIMConsoleServerPort in Netbox D module.

.DESCRIPTION
    Updates an existing CIMConsoleServerPort in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMConsoleServerPort

    Returns all CIMConsoleServerPort objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMConsoleServerPort {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device,
        [string]$Name,
        [uint64]$Module,
        [string]$Label,
        [string]$Type,
        [uint16]$Speed,
        [bool]$Mark_Connected,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','console-server-ports',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update console server port')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMConsoleServerPortTemplate.ps1

<#
.SYNOPSIS
    Updates an existing CIMConsoleServerPortTemplate in Netbox D module.

.DESCRIPTION
    Updates an existing CIMConsoleServerPortTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMConsoleServerPortTemplate

    Returns all CIMConsoleServerPortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMConsoleServerPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [string]$Name,
        [string]$Label,
        [string]$Type,
        [string]$Description,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','console-server-port-templates',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update console server port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMDevice.ps1

<#
.SYNOPSIS
    Updates an existing CIMDevice in Netbox D module.

.DESCRIPTION
    Updates an existing CIMDevice in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMDevice

    Returns all CIMDevice objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function Set-NBDCIMDevice {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
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
            $CurrentDevice = Get-NBDCIMDevice -Id $DeviceID -ErrorAction Stop

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

#region File Set-NBDCIMDeviceBay.ps1

<#
.SYNOPSIS
    Updates an existing CIMDeviceBay in Netbox D module.

.DESCRIPTION
    Updates an existing CIMDeviceBay in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMDeviceBay

    Returns all CIMDeviceBay objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMDeviceBay {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device,
        [string]$Name,
        [string]$Label,
        [uint64]$Installed_Device,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','device-bays',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update device bay')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMDeviceBayTemplate.ps1

<#
.SYNOPSIS
    Updates an existing CIMDeviceBayTemplate in Netbox D module.

.DESCRIPTION
    Updates an existing CIMDeviceBayTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMDeviceBayTemplate

    Returns all CIMDeviceBayTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMDeviceBayTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device_Type,
        [string]$Name,
        [string]$Label,
        [string]$Description,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','device-bay-templates',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update device bay template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMDeviceRole.ps1

<#
.SYNOPSIS
    Updates an existing CIMDeviceRole in Netbox D module.

.DESCRIPTION
    Updates an existing CIMDeviceRole in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMDeviceRole

    Returns all CIMDeviceRole objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMDeviceRole {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,
        [string]$Slug,
        [string]$Color,
        [bool]$VM_Role,
        [uint64]$Config_Template,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','device-roles',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update device role')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMDeviceType.ps1

<#
.SYNOPSIS
    Updates an existing CIMDeviceType in Netbox D module.

.DESCRIPTION
    Updates an existing CIMDeviceType in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMDeviceType

    Returns all CIMDeviceType objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMDeviceType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Manufacturer,
        [string]$Model,
        [string]$Slug,
        [string]$Part_Number,
        [uint16]$U_Height,
        [bool]$Is_Full_Depth,
        [string]$Subdevice_Role,
        [string]$Airflow,
        [uint16]$Weight,
        [string]$Weight_Unit,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','device-types',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update device type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMFrontPort.ps1

<#
.SYNOPSIS
    Updates an existing CIMFrontPort in Netbox D module.

.DESCRIPTION
    Updates an existing CIMFrontPort in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMFrontPort

    Returns all CIMFrontPort objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMFrontPort {
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
            $CurrentPort = Get-NBDCIMFrontPort -Id $FrontPortID -ErrorAction Stop

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

#region File Set-NBDCIMFrontPortTemplate.ps1

<#
.SYNOPSIS
    Updates an existing CIMFrontPortTemplate in Netbox D module.

.DESCRIPTION
    Updates an existing CIMFrontPortTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMFrontPortTemplate

    Returns all CIMFrontPortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMFrontPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [string]$Name,
        [string]$Label,
        [string]$Type,
        [string]$Color,
        [uint64]$Rear_Port,
        [uint16]$Rear_Port_Position,
        [string]$Description,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','front-port-templates',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update front port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMInterface.ps1

<#
.SYNOPSIS
    Updates an existing CIMInterface in Netbox D module.

.DESCRIPTION
    Updates an existing CIMInterface in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMInterface

    Returns all CIMInterface objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMInterface {
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
            $CurrentInterface = Get-NBDCIMInterface -Id $InterfaceId -ErrorAction Stop

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

#region File Set-NBDCIMInterfaceConnection.ps1


function Set-NBDCIMInterfaceConnection {
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
        PS C:\> Set-NBDCIMInterfaceConnection -Id $value1

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
            $CurrentConnection = Get-NBDCIMInterfaceConnection -Id $ConnectionID -ErrorAction Stop

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

#region File Set-NBDCIMInterfaceTemplate.ps1

<#
.SYNOPSIS
    Updates an existing CIMInterfaceTemplate in Netbox D module.

.DESCRIPTION
    Updates an existing CIMInterfaceTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMInterfaceTemplate

    Returns all CIMInterfaceTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMInterfaceTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [string]$Name,
        [string]$Label,
        [string]$Type,
        [bool]$Enabled,
        [bool]$Mgmt_Only,
        [string]$Description,
        [string]$Poe_Mode,
        [string]$Poe_Type,
        [string]$Rf_Role,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','interface-templates',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update interface template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMInventoryItem.ps1

<#
.SYNOPSIS
    Updates an existing CIMInventoryItem in Netbox D module.

.DESCRIPTION
    Updates an existing CIMInventoryItem in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMInventoryItem

    Returns all CIMInventoryItem objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMInventoryItem {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device,
        [string]$Name,
        [uint64]$Parent,
        [string]$Label,
        [uint64]$Role,
        [uint64]$Manufacturer,
        [string]$Part_Id,
        [string]$Serial,
        [string]$Asset_Tag,
        [bool]$Discovered,
        [string]$Description,
        [uint64]$Component_Type,
        [uint64]$Component_Id,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','inventory-items',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update inventory item')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMInventoryItemRole.ps1

<#
.SYNOPSIS
    Updates an existing CIMInventoryItemRole in Netbox D module.

.DESCRIPTION
    Updates an existing CIMInventoryItemRole in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMInventoryItemRole

    Returns all CIMInventoryItemRole objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMInventoryItemRole {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,
        [string]$Slug,
        [string]$Color,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','inventory-item-roles',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update inventory item role')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMInventoryItemTemplate.ps1

<#
.SYNOPSIS
    Updates an existing CIMInventoryItemTemplate in Netbox D module.

.DESCRIPTION
    Updates an existing CIMInventoryItemTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMInventoryItemTemplate

    Returns all CIMInventoryItemTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMInventoryItemTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device_Type,
        [string]$Name,
        [uint64]$Parent,
        [string]$Label,
        [uint64]$Role,
        [uint64]$Manufacturer,
        [string]$Part_Id,
        [string]$Description,
        [uint64]$Component_Type,
        [string]$Component_Name,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','inventory-item-templates',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update inventory item template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMLocation.ps1

function Set-NBDCIMLocation {
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
        Set-NBDCIMLocation -Id 1 -Name "Server Room A"

        Updates the name of location 1

    .EXAMPLE
        Set-NBDCIMLocation -Id 1 -Status retired

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

#region File Set-NBDCIMMACAddress.ps1

<#
.SYNOPSIS
    Updates an existing CIMMACAddress in Netbox D module.

.DESCRIPTION
    Updates an existing CIMMACAddress in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMMACAddress

    Returns all CIMMACAddress objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMMACAddress {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Mac_Address,
        [uint64]$Assigned_Object_Id,
        [string]$Assigned_Object_Type,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','mac-addresses',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update MAC address')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMManufacturer.ps1

function Set-NBDCIMManufacturer {
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
        Set-NBDCIMManufacturer -Id 1 -Description "Updated description"

    .EXAMPLE
        Get-NBDCIMManufacturer -Name "Cisco" | Set-NBDCIMManufacturer -Description "Network equipment"
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
            $CurrentManufacturer = Get-NBDCIMManufacturer -Id $ManufacturerId -ErrorAction Stop

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

#region File Set-NBDCIMModule.ps1

<#
.SYNOPSIS
    Updates an existing CIMModule in Netbox D module.

.DESCRIPTION
    Updates an existing CIMModule in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMModule

    Returns all CIMModule objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMModule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device,
        [uint64]$Module_Bay,
        [uint64]$Module_Type,
        [string]$Status,
        [string]$Serial,
        [string]$Asset_Tag,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','modules',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update module')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMModuleBay.ps1

<#
.SYNOPSIS
    Updates an existing CIMModuleBay in Netbox D module.

.DESCRIPTION
    Updates an existing CIMModuleBay in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMModuleBay

    Returns all CIMModuleBay objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMModuleBay {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device,
        [string]$Name,
        [string]$Label,
        [string]$Position,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','module-bays',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update module bay')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMModuleBayTemplate.ps1

<#
.SYNOPSIS
    Updates an existing CIMModuleBayTemplate in Netbox D module.

.DESCRIPTION
    Updates an existing CIMModuleBayTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMModuleBayTemplate

    Returns all CIMModuleBayTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMModuleBayTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device_Type,
        [string]$Name,
        [string]$Label,
        [string]$Position,
        [string]$Description,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','module-bay-templates',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update module bay template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMModuleType.ps1

<#
.SYNOPSIS
    Updates an existing CIMModuleType in Netbox D module.

.DESCRIPTION
    Updates an existing CIMModuleType in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMModuleType

    Returns all CIMModuleType objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMModuleType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Manufacturer,
        [string]$Model,
        [string]$Part_Number,
        [uint16]$Weight,
        [string]$Weight_Unit,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','module-types',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update module type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMModuleTypeProfile.ps1

<#
.SYNOPSIS
    Updates an existing CIMModuleTypeProfile in Netbox D module.

.DESCRIPTION
    Updates an existing CIMModuleTypeProfile in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMModuleTypeProfile

    Returns all CIMModuleTypeProfile objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMModuleTypeProfile {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','module-type-profiles',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update module type profile')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMPlatform.ps1

<#
.SYNOPSIS
    Updates an existing CIMPlatform in Netbox D module.

.DESCRIPTION
    Updates an existing CIMPlatform in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMPlatform

    Returns all CIMPlatform objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMPlatform {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,
        [string]$Slug,
        [uint64]$Manufacturer,
        [uint64]$Config_Template,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','platforms',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update platform')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMPowerFeed.ps1

<#
.SYNOPSIS
    Updates an existing CIMPowerFeed in Netbox D module.

.DESCRIPTION
    Updates an existing CIMPowerFeed in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMPowerFeed

    Returns all CIMPowerFeed objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMPowerFeed {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Power_Panel,
        [string]$Name,
        [uint64]$Rack,
        [string]$Status,
        [string]$Type,
        [string]$Supply,
        [string]$Phase,
        [uint16]$Voltage,
        [uint16]$Amperage,
        [uint16]$Max_Utilization,
        [bool]$Mark_Connected,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','power-feeds',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update power feed')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMPowerOutlet.ps1

<#
.SYNOPSIS
    Updates an existing CIMPowerOutlet in Netbox D module.

.DESCRIPTION
    Updates an existing CIMPowerOutlet in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMPowerOutlet

    Returns all CIMPowerOutlet objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMPowerOutlet {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device,
        [string]$Name,
        [uint64]$Module,
        [string]$Label,
        [string]$Type,
        [uint64]$Power_Port,
        [string]$Feed_Leg,
        [bool]$Mark_Connected,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','power-outlets',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update power outlet')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMPowerOutletTemplate.ps1

<#
.SYNOPSIS
    Updates an existing CIMPowerOutletTemplate in Netbox D module.

.DESCRIPTION
    Updates an existing CIMPowerOutletTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMPowerOutletTemplate

    Returns all CIMPowerOutletTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMPowerOutletTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [string]$Name,
        [string]$Label,
        [string]$Type,
        [uint64]$Power_Port,
        [string]$Feed_Leg,
        [string]$Description,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','power-outlet-templates',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update power outlet template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMPowerPanel.ps1

<#
.SYNOPSIS
    Updates an existing CIMPowerPanel in Netbox D module.

.DESCRIPTION
    Updates an existing CIMPowerPanel in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMPowerPanel

    Returns all CIMPowerPanel objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMPowerPanel {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Site,
        [string]$Name,
        [uint64]$Location,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','power-panels',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update power panel')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMPowerPort.ps1

<#
.SYNOPSIS
    Updates an existing CIMPowerPort in Netbox D module.

.DESCRIPTION
    Updates an existing CIMPowerPort in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMPowerPort

    Returns all CIMPowerPort objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMPowerPort {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device,
        [string]$Name,
        [uint64]$Module,
        [string]$Label,
        [string]$Type,
        [uint16]$Maximum_Draw,
        [uint16]$Allocated_Draw,
        [bool]$Mark_Connected,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','power-ports',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update power port')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMPowerPortTemplate.ps1

<#
.SYNOPSIS
    Updates an existing CIMPowerPortTemplate in Netbox D module.

.DESCRIPTION
    Updates an existing CIMPowerPortTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMPowerPortTemplate

    Returns all CIMPowerPortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMPowerPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [string]$Name,
        [string]$Label,
        [string]$Type,
        [uint16]$Maximum_Draw,
        [uint16]$Allocated_Draw,
        [string]$Description,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','power-port-templates',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update power port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMRack.ps1

function Set-NBDCIMRack {
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
        Set-NBDCIMRack -Id 1 -Description "Updated description"

    .EXAMPLE
        Get-NBDCIMRack -Name "Rack-01" | Set-NBDCIMRack -Status deprecated
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
            $CurrentRack = Get-NBDCIMRack -Id $RackId -ErrorAction Stop

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

#region File Set-NBDCIMRackReservation.ps1

<#
.SYNOPSIS
    Updates an existing CIMRackReservation in Netbox D module.

.DESCRIPTION
    Updates an existing CIMRackReservation in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMRackReservation

    Returns all CIMRackReservation objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMRackReservation {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Rack,
        [uint16[]]$Units,
        [uint64]$User,
        [uint64]$Tenant,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','rack-reservations',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update rack reservation')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMRackRole.ps1

<#
.SYNOPSIS
    Updates an existing CIMRackRole in Netbox D module.

.DESCRIPTION
    Updates an existing CIMRackRole in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMRackRole

    Returns all CIMRackRole objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMRackRole {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,
        [string]$Slug,
        [string]$Color,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','rack-roles',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update rack role')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMRackType.ps1

<#
.SYNOPSIS
    Updates an existing CIMRackType in Netbox D module.

.DESCRIPTION
    Updates an existing CIMRackType in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMRackType

    Returns all CIMRackType objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMRackType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Manufacturer,
        [string]$Model,
        [string]$Slug,
        [string]$Form_Factor,
        [uint16]$Width,
        [uint16]$U_Height,
        [uint16]$Starting_Unit,
        [uint16]$Outer_Width,
        [uint16]$Outer_Depth,
        [string]$Outer_Unit,
        [uint16]$Weight,
        [uint16]$Max_Weight,
        [string]$Weight_Unit,
        [string]$Mounting_Depth,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','rack-types',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update rack type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMRearPort.ps1

<#
.SYNOPSIS
    Updates an existing CIMRearPort in Netbox D module.

.DESCRIPTION
    Updates an existing CIMRearPort in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMRearPort

    Returns all CIMRearPort objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function Set-NBDCIMRearPort {
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
            $CurrentPort = Get-NBDCIMRearPort -Id $RearPortID -ErrorAction Stop

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

#region File Set-NBDCIMRearPortTemplate.ps1

<#
.SYNOPSIS
    Updates an existing CIMRearPortTemplate in Netbox D module.

.DESCRIPTION
    Updates an existing CIMRearPortTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMRearPortTemplate

    Returns all CIMRearPortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMRearPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [string]$Name,
        [string]$Label,
        [string]$Type,
        [string]$Color,
        [uint16]$Positions,
        [string]$Description,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','rear-port-templates',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update rear port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMRegion.ps1

function Set-NBDCIMRegion {
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
        Set-NBDCIMRegion -Id 1 -Name "Western Europe"

        Updates the name of region 1

    .EXAMPLE
        Set-NBDCIMRegion -Id 1 -Description "Western European countries"

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

#region File Set-NBDCIMSite.ps1

function Set-NBDCIMSite {
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
        Set-NBDCIMSite -Id 1 -Description "Updated description"

    .EXAMPLE
        Get-NBDCIMSite -Name "Site1" | Set-NBDCIMSite -Status planned
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
            $CurrentSite = Get-NBDCIMSite -Id $SiteID -ErrorAction Stop

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

#region File Set-NBDCIMSiteGroup.ps1

function Set-NBDCIMSiteGroup {
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
        Set-NBDCIMSiteGroup -Id 1 -Name "Production Sites"

        Updates the name of site group 1

    .EXAMPLE
        Set-NBDCIMSiteGroup -Id 1 -Description "All production sites"

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

#region File Set-NBDCIMVirtualChassis.ps1

<#
.SYNOPSIS
    Updates an existing CIMVirtualChassis in Netbox D module.

.DESCRIPTION
    Updates an existing CIMVirtualChassis in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMVirtualChassis

    Returns all CIMVirtualChassis objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMVirtualChassis {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,
        [string]$Domain,
        [uint64]$Master,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','virtual-chassis',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update virtual chassis')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBDCIMVirtualDeviceContext.ps1

<#
.SYNOPSIS
    Updates an existing CIMVirtualDeviceContext in Netbox D module.

.DESCRIPTION
    Updates an existing CIMVirtualDeviceContext in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMVirtualDeviceContext

    Returns all CIMVirtualDeviceContext objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMVirtualDeviceContext {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,
        [uint64]$Device,
        [ValidateSet('active','planned','offline')][string]$Status,
        [string]$Identifier,
        [uint64]$Tenant,
        [uint64]$Primary_Ip4,
        [uint64]$Primary_Ip6,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','virtual-device-contexts',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update virtual device context')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBEventRule.ps1

<#
.SYNOPSIS
    Updates an existing event rule in Netbox.

.DESCRIPTION
    Updates an existing event rule in Netbox Extras module.

.PARAMETER Id
    The ID of the event rule to update.

.PARAMETER Name
    Name of the event rule.

.PARAMETER Description
    Description of the event rule.

.PARAMETER Enabled
    Whether the event rule is enabled.

.PARAMETER Object_Types
    Object types this rule applies to.

.PARAMETER Type_Create
    Trigger on create events.

.PARAMETER Type_Update
    Trigger on update events.

.PARAMETER Type_Delete
    Trigger on delete events.

.PARAMETER Type_Job_Start
    Trigger on job start events.

.PARAMETER Type_Job_End
    Trigger on job end events.

.PARAMETER Action_Type
    Action type (webhook, script).

.PARAMETER Action_Object_Type
    Action object type.

.PARAMETER Action_Object_Id
    Action object ID.

.PARAMETER Conditions
    Conditions (JSON logic).

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBEventRule -Id 1 -Enabled $false

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBEventRule {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Description,

        [bool]$Enabled,

        [string[]]$Object_Types,

        [bool]$Type_Create,

        [bool]$Type_Update,

        [bool]$Type_Delete,

        [bool]$Type_Job_Start,

        [bool]$Type_Job_End,

        [ValidateSet('webhook', 'script')]
        [string]$Action_Type,

        [string]$Action_Object_Type,

        [uint64]$Action_Object_Id,

        $Conditions,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'event-rules', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Event Rule')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBExportTemplate.ps1

<#
.SYNOPSIS
    Updates an existing export template in Netbox.

.DESCRIPTION
    Updates an existing export template in Netbox Extras module.

.PARAMETER Id
    The ID of the export template to update.

.PARAMETER Name
    Name of the export template.

.PARAMETER Object_Types
    Object types this template applies to.

.PARAMETER Description
    Description of the template.

.PARAMETER Template_Code
    Jinja2 template code.

.PARAMETER Mime_Type
    MIME type for the export.

.PARAMETER File_Extension
    File extension for the export.

.PARAMETER As_Attachment
    Whether to serve as attachment.

.PARAMETER Data_Source
    Data source ID.

.PARAMETER Data_File
    Data file ID.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBExportTemplate -Id 1 -Name "Updated Template"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBExportTemplate {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string[]]$Object_Types,

        [string]$Description,

        [string]$Template_Code,

        [string]$Mime_Type,

        [string]$File_Extension,

        [bool]$As_Attachment,

        [uint64]$Data_Source,

        [uint64]$Data_File,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'export-templates', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Export Template')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBGroup.ps1

<#
.SYNOPSIS
    Updates an existing group in Netbox.

.DESCRIPTION
    Updates an existing group in Netbox Users module.

.PARAMETER Id
    The ID of the group to update.

.PARAMETER Name
    Name of the group.

.PARAMETER Permissions
    Array of permission IDs.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBGroup -Id 1 -Name "Updated Group Name"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [uint64[]]$Permissions,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('users', 'groups', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Group')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBHostName.ps1

<#
.SYNOPSIS
    Updates an existing ostName in Netbox H module.

.DESCRIPTION
    Updates an existing ostName in Netbox H module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBHostName

    Returns all ostName objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBHostName {
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

#region File Set-NBHostPort.ps1

<#
.SYNOPSIS
    Updates an existing ostPort in Netbox H module.

.DESCRIPTION
    Updates an existing ostPort in Netbox H module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBHostPort

    Returns all ostPort objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBHostPort {
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

#region File Set-NBHostScheme.ps1

<#
.SYNOPSIS
    Updates an existing ostScheme in Netbox H module.

.DESCRIPTION
    Updates an existing ostScheme in Netbox H module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBHostScheme

    Returns all ostScheme objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBHostScheme {
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

#region File Set-NBInvokeParams.ps1

<#
.SYNOPSIS
    Updates an existing nvokeParams in Netbox I module.

.DESCRIPTION
    Updates an existing nvokeParams in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBInvokeParams

    Returns all nvokeParams objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBInvokeParams {
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

#region File Set-NBIPAMAddress.ps1

<#
.SYNOPSIS
    Updates an existing PAMAddress in Netbox I module.

.DESCRIPTION
    Updates an existing PAMAddress in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBIPAMAddress

    Returns all PAMAddress objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function Set-NBIPAMAddress {
    [CmdletBinding(ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
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
            $CurrentIP = Get-NBIPAMAddress -Id $IPId -ErrorAction Stop

            if ($Force -or $PSCmdlet.ShouldProcess($CurrentIP.Address, 'Set')) {
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method $Method
            }
        }
    }
}

#endregion

#region File Set-NBIPAMAddressRange.ps1

<#
.SYNOPSIS
    Updates an existing PAMAddressRange in Netbox I module.

.DESCRIPTION
    Updates an existing PAMAddressRange in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBIPAMAddressRange

    Returns all PAMAddressRange objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function Set-NBIPAMAddressRange {
    [CmdletBinding(ConfirmImpact = 'Medium',
                   SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
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
            $CurrentRange = Get-NBIPAMAddressRange -Id $RangeID -ErrorAction Stop

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentRange.Start_Address) - $($CurrentRange.End_Address)", 'Set')) {
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method $Method
            }
        }
    }
}

#endregion

#region File Set-NBIPAMAggregate.ps1

<#
.SYNOPSIS
    Updates an existing PAMAggregate in Netbox I module.

.DESCRIPTION
    Updates an existing PAMAggregate in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBIPAMAggregate

    Returns all PAMAggregate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBIPAMAggregate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Prefix,
        [uint64]$RIR,
        [uint64]$Tenant,
        [datetime]$Date_Added,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'aggregates', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments
        if ($PSCmdlet.ShouldProcess($Id, 'Update aggregate')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBIPAMASN.ps1

function Set-NBIPAMASN {
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
        Set-NBIPAMASN -Id 1 -Description "Updated description"

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

#region File Set-NBIPAMASNRange.ps1

function Set-NBIPAMASNRange {
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
        Set-NBIPAMASNRange -Id 1 -Description "Updated description"

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

#region File Set-NBIPAMFHRPGroup.ps1

<#
.SYNOPSIS
    Updates an existing PAMFHRPGroup in Netbox I module.

.DESCRIPTION
    Updates an existing PAMFHRPGroup in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBIPAMFHRPGroup

    Returns all PAMFHRPGroup objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBIPAMFHRPGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [ValidateSet('vrrp2','vrrp3','carp','clusterxl','hsrp','glbp','other')][string]$Protocol,
        [uint16]$Group_Id,
        [string]$Name,
        [string]$Auth_Type,
        [string]$Auth_Key,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam','fhrp-groups',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update FHRP group')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBIPAMFHRPGroupAssignment.ps1

<#
.SYNOPSIS
    Updates an existing PAMFHRPGroupAssignment in Netbox I module.

.DESCRIPTION
    Updates an existing PAMFHRPGroupAssignment in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBIPAMFHRPGroupAssignment

    Returns all PAMFHRPGroupAssignment objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBIPAMFHRPGroupAssignment {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Group,
        [string]$Interface_Type,
        [uint64]$Interface_Id,
        [uint16]$Priority,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam','fhrp-group-assignments',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update FHRP group assignment')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBIPAMPrefix.ps1

<#
.SYNOPSIS
    Updates an existing PAMPrefix in Netbox I module.

.DESCRIPTION
    Updates an existing PAMPrefix in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBIPAMPrefix

    Returns all PAMPrefix objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function Set-NBIPAMPrefix {
    [CmdletBinding(ConfirmImpact = 'Medium',
                   SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
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
            $CurrentPrefix = Get-NBIPAMPrefix -Id $PrefixId -ErrorAction Stop

            if ($Force -or $PSCmdlet.ShouldProcess($CurrentPrefix.Prefix, 'Set')) {
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method $Method
            }
        }
    }
}









#endregion

#region File Set-NBIPAMRIR.ps1

<#
.SYNOPSIS
    Updates an existing PAMRIR in Netbox I module.

.DESCRIPTION
    Updates an existing PAMRIR in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBIPAMRIR

    Returns all PAMRIR objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBIPAMRIR {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,
        [string]$Slug,
        [bool]$Is_Private,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam','rirs',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update RIR')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBIPAMRole.ps1

<#
.SYNOPSIS
    Updates an existing PAMRole in Netbox I module.

.DESCRIPTION
    Updates an existing PAMRole in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBIPAMRole

    Returns all PAMRole objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBIPAMRole {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,
        [string]$Slug,
        [uint16]$Weight,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'roles', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments
        if ($PSCmdlet.ShouldProcess($Id, 'Update IPAM role')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBIPAMRouteTarget.ps1

function Set-NBIPAMRouteTarget {
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
        Set-NBIPAMRouteTarget -Id 1 -Description "Updated description"

        Updates the description of route target 1

    .EXAMPLE
        Set-NBIPAMRouteTarget -Id 1 -Tenant 5

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

#region File Set-NBIPAMService.ps1

function Set-NBIPAMService {
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
        Set-NBIPAMService -Id 1 -Ports @(443, 8443)

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

#region File Set-NBIPAMServiceTemplate.ps1

function Set-NBIPAMServiceTemplate {
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
        Set-NBIPAMServiceTemplate -Id 1 -Ports @(80, 443, 8080)

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

#region File Set-NBIPAMVLAN.ps1

<#
.SYNOPSIS
    Updates an existing PAMVLAN in Netbox I module.

.DESCRIPTION
    Updates an existing PAMVLAN in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBIPAMVLAN

    Returns all PAMVLAN objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBIPAMVLAN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [ValidateRange(1, 4096)][uint16]$VID,
        [string]$Name,
        [string]$Status,
        [uint64]$Site,
        [uint64]$Group,
        [uint64]$Tenant,
        [uint64]$Role,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'vlans', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments
        if ($PSCmdlet.ShouldProcess($Id, 'Update VLAN')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBIPAMVLANGroup.ps1

<#
.SYNOPSIS
    Updates an existing PAMVLANGroup in Netbox I module.

.DESCRIPTION
    Updates an existing PAMVLANGroup in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBIPAMVLANGroup

    Returns all PAMVLANGroup objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBIPAMVLANGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,
        [string]$Slug,
        [uint64]$Scope_Type,
        [uint64]$Scope_Id,
        [ValidateRange(1, 4094)][uint16]$Min_Vid,
        [ValidateRange(1, 4094)][uint16]$Max_Vid,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam','vlan-groups',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update VLAN group')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBIPAMVLANTranslationPolicy.ps1

<#
.SYNOPSIS
    Updates an existing PAMVLANTranslationPolicy in Netbox I module.

.DESCRIPTION
    Updates an existing PAMVLANTranslationPolicy in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBIPAMVLANTranslationPolicy

    Returns all PAMVLANTranslationPolicy objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBIPAMVLANTranslationPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam','vlan-translation-policies',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update VLAN translation policy')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBIPAMVLANTranslationRule.ps1

<#
.SYNOPSIS
    Updates an existing PAMVLANTranslationRule in Netbox I module.

.DESCRIPTION
    Updates an existing PAMVLANTranslationRule in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBIPAMVLANTranslationRule

    Returns all PAMVLANTranslationRule objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBIPAMVLANTranslationRule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Policy,
        [ValidateRange(1, 4094)][uint16]$Local_Vid,
        [ValidateRange(1, 4094)][uint16]$Remote_Vid,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam','vlan-translation-rules',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update VLAN translation rule')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBIPAMVRF.ps1

function Set-NBIPAMVRF {
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
        Set-NBIPAMVRF -Id 1 -Name "Production-VRF"

        Updates the name of VRF 1

    .EXAMPLE
        Set-NBIPAMVRF -Id 1 -Enforce_Unique $true

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

#region File Set-NBJournalEntry.ps1

<#
.SYNOPSIS
    Updates an existing journal entry in Netbox.

.DESCRIPTION
    Updates an existing journal entry in Netbox Extras module.

.PARAMETER Id
    The ID of the journal entry to update.

.PARAMETER Assigned_Object_Type
    Object type.

.PARAMETER Assigned_Object_Id
    Object ID.

.PARAMETER Comments
    Journal entry comments.

.PARAMETER Kind
    Entry kind (info, success, warning, danger).

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBJournalEntry -Id 1 -Comments "Updated comments"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBJournalEntry {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Assigned_Object_Type,

        [uint64]$Assigned_Object_Id,

        [string]$Comments,

        [ValidateSet('info', 'success', 'warning', 'danger')]
        [string]$Kind,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'journal-entries', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Journal Entry')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBPermission.ps1

<#
.SYNOPSIS
    Updates an existing permission in Netbox.

.DESCRIPTION
    Updates an existing permission in Netbox Users module.

.PARAMETER Id
    The ID of the permission to update.

.PARAMETER Name
    Name of the permission.

.PARAMETER Description
    Description of the permission.

.PARAMETER Enabled
    Whether the permission is enabled.

.PARAMETER Object_Types
    Object types this permission applies to.

.PARAMETER Actions
    Allowed actions (view, add, change, delete).

.PARAMETER Constraints
    JSON constraints for filtering objects.

.PARAMETER Groups
    Array of group IDs.

.PARAMETER Users
    Array of user IDs.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBPermission -Id 1 -Enabled $false

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBPermission {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Description,

        [bool]$Enabled,

        [string[]]$Object_Types,

        [ValidateSet('view', 'add', 'change', 'delete')]
        [string[]]$Actions,

        $Constraints,

        [uint64[]]$Groups,

        [uint64[]]$Users,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('users', 'permissions', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Permission')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBSavedFilter.ps1

<#
.SYNOPSIS
    Updates an existing saved filter in Netbox.

.DESCRIPTION
    Updates an existing saved filter in Netbox Extras module.

.PARAMETER Id
    The ID of the saved filter to update.

.PARAMETER Name
    Name of the saved filter.

.PARAMETER Slug
    URL-friendly slug.

.PARAMETER Object_Types
    Object types this filter applies to.

.PARAMETER Description
    Description of the filter.

.PARAMETER Weight
    Display weight.

.PARAMETER Enabled
    Whether the filter is enabled.

.PARAMETER Shared
    Whether the filter is shared.

.PARAMETER Parameters
    Filter parameters (hashtable).

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBSavedFilter -Id 1 -Enabled $false

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBSavedFilter {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [string[]]$Object_Types,

        [string]$Description,

        [uint16]$Weight,

        [bool]$Enabled,

        [bool]$Shared,

        [hashtable]$Parameters,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'saved-filters', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Saved Filter')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBTag.ps1

<#
.SYNOPSIS
    Updates an existing tag in Netbox.

.DESCRIPTION
    Updates an existing tag in Netbox Extras module.

.PARAMETER Id
    The ID of the tag to update.

.PARAMETER Name
    Name of the tag.

.PARAMETER Slug
    URL-friendly slug.

.PARAMETER Color
    Color code (6 hex characters).

.PARAMETER Description
    Description of the tag.

.PARAMETER Object_Types
    Object types this tag can be applied to.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBTag -Id 1 -Color "ff0000"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBTag {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [ValidatePattern('^[0-9a-fA-F]{6}$')]
        [string]$Color,

        [string]$Description,

        [string[]]$Object_Types,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'tags', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Tag')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBTenant.ps1

<#
.SYNOPSIS
    Updates an existing tenant in Netbox.

.DESCRIPTION
    Updates an existing tenant in the Netbox tenancy module.
    Supports pipeline input from Get-NBTenant.

.PARAMETER Id
    The database ID of the tenant to update. Accepts pipeline input.

.PARAMETER Name
    The new name of the tenant.

.PARAMETER Slug
    URL-friendly unique identifier.

.PARAMETER Group
    The database ID of the tenant group.

.PARAMETER Description
    A description of the tenant.

.PARAMETER Comments
    Additional comments about the tenant.

.PARAMETER Tags
    Array of tag IDs to assign.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBTenant -Id 1 -Description "Updated tenant description"

    Updates the description of tenant ID 1.

.EXAMPLE
    Get-NBTenant -Name "Acme Corp" | Set-NBTenant -Group 2

    Moves a tenant to a different group via pipeline.

.LINK
    https://netbox.readthedocs.io/en/stable/models/tenancy/tenant/
#>
function Set-NBTenant {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Name,

        [string]$Slug,

        [uint64]$Group,

        [string]$Description,

        [string]$Comments,

        [uint64[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        foreach ($TenantId in $Id) {
            $CurrentTenant = Get-NBTenant -Id $TenantId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'tenants', $CurrentTenant.Id))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force', 'Raw'

            $URI = BuildNewURI -Segments $URIComponents.Segments

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentTenant.Name)", 'Update tenant')) {
                InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Set-NBTenantGroup.ps1

<#
.SYNOPSIS
    Updates an existing tenant group in Netbox.

.DESCRIPTION
    Updates an existing tenant group in the Netbox tenancy module.
    Supports pipeline input from Get-NBTenantGroup.

.PARAMETER Id
    The database ID of the tenant group to update. Accepts pipeline input.

.PARAMETER Name
    The new name of the tenant group.

.PARAMETER Slug
    URL-friendly unique identifier.

.PARAMETER Parent
    The database ID of the parent tenant group.

.PARAMETER Description
    A description of the tenant group.

.PARAMETER Tags
    Array of tag IDs to assign.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBTenantGroup -Id 1 -Description "Updated description"

    Updates the description of tenant group ID 1.

.EXAMPLE
    Get-NBTenantGroup -Name "legacy" | Set-NBTenantGroup -Parent 2

    Moves a tenant group under a new parent via pipeline.

.LINK
    https://netbox.readthedocs.io/en/stable/models/tenancy/tenantgroup/
#>
function Set-NBTenantGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Name,

        [string]$Slug,

        [uint64]$Parent,

        [string]$Description,

        [uint64[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        foreach ($GroupId in $Id) {
            $CurrentGroup = Get-NBTenantGroup -Id $GroupId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'tenant-groups', $CurrentGroup.Id))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force', 'Raw'

            $URI = BuildNewURI -Segments $URIComponents.Segments

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentGroup.Name)", 'Update tenant group')) {
                InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Set-NBTimeout.ps1

<#
.SYNOPSIS
    Updates an existing imeout in Netbox T module.

.DESCRIPTION
    Updates an existing imeout in Netbox T module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBTimeout

    Returns all imeout objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function Set-NBTimeout {
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

#region File Set-NBToken.ps1

<#
.SYNOPSIS
    Updates an existing API token in Netbox.

.DESCRIPTION
    Updates an existing API token in Netbox Users module.

.PARAMETER Id
    The ID of the token to update.

.PARAMETER User
    User ID for the token.

.PARAMETER Description
    Description of the token.

.PARAMETER Expires
    Expiration date (datetime).

.PARAMETER Write_Enabled
    Whether write operations are enabled.

.PARAMETER Allowed_Ips
    Array of allowed IP addresses/networks.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBToken -Id 1 -Write_Enabled $false

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBToken {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [uint64]$User,

        [string]$Description,

        [datetime]$Expires,

        [bool]$Write_Enabled,

        [string[]]$Allowed_Ips,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('users', 'tokens', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Token')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBUnstrustedSSL.ps1

Function Set-NBUntrustedSSL {
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

#region File Set-NBuntrustedSSL.ps1

function Set-NBuntrustedSSL {
    <#
    .SYNOPSIS
        Disables SSL certificate validation for PowerShell Desktop (5.1).

    .DESCRIPTION
        Configures ServicePointManager to skip SSL certificate validation.
        This is only used for PowerShell Desktop (5.1) when -SkipCertificateCheck
        is specified. PowerShell Core (7+) uses the -SkipCertificateCheck parameter
        on Invoke-RestMethod directly.

    .NOTES
        This function should only be called on PowerShell Desktop edition.
        Security Warning: Only use in development/testing environments.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [CmdletBinding()]
    param()

    # Only apply to Desktop edition (PS 5.1)
    if ($PSVersionTable.PSEdition -ne 'Desktop') {
        Write-Verbose "Skipping certificate callback - not needed for PowerShell Core"
        return
    }

    # Check if callback is already set
    if ([System.Net.ServicePointManager]::ServerCertificateValidationCallback) {
        Write-Verbose "Certificate validation callback already configured"
        return
    }

    # Create callback to accept all certificates
    $CertCallback = @"
using System;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;

public class NetboxTrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@

    # Only add type if not already loaded
    if (-not ([System.Management.Automation.PSTypeName]'NetboxTrustAllCertsPolicy').Type) {
        try {
            Add-Type -TypeDefinition $CertCallback -ErrorAction Stop
        } catch {
            Write-Verbose "Type already exists or could not be added: $_"
        }
    }

    try {
        [System.Net.ServicePointManager]::CertificatePolicy = [NetboxTrustAllCertsPolicy]::new()
        Write-Verbose "Certificate validation disabled for this session"
    } catch {
        Write-Warning "Could not set certificate policy: $_"
    }
}

#endregion

#region File Set-NBUser.ps1

<#
.SYNOPSIS
    Updates an existing user in Netbox.

.DESCRIPTION
    Updates an existing user in Netbox Users module.

.PARAMETER Id
    The ID of the user to update.

.PARAMETER Username
    Username.

.PARAMETER Password
    Password.

.PARAMETER First_Name
    First name.

.PARAMETER Last_Name
    Last name.

.PARAMETER Email
    Email address.

.PARAMETER Is_Staff
    Whether user has staff access.

.PARAMETER Is_Active
    Whether user is active.

.PARAMETER Is_Superuser
    Whether user is a superuser.

.PARAMETER Groups
    Array of group IDs.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBUser -Id 1 -Is_Active $false

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBUser {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Username,

        [string]$Password,

        [string]$First_Name,

        [string]$Last_Name,

        [string]$Email,

        [bool]$Is_Staff,

        [bool]$Is_Active,

        [bool]$Is_Superuser,

        [uint64[]]$Groups,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('users', 'users', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update User')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBVirtualCircuit.ps1

<#
.SYNOPSIS
    Updates an existing virtual circuit in Netbox.

.DESCRIPTION
    Updates an existing virtual circuit in Netbox.

.PARAMETER Id
    The ID of the virtual circuit to update.

.PARAMETER Cid
    Circuit ID string.

.PARAMETER Provider_Network
    Provider network ID.

.PARAMETER Provider_Account
    Provider account ID.

.PARAMETER Type
    Virtual circuit type ID.

.PARAMETER Status
    Status (planned, provisioning, active, offline, deprovisioning, decommissioned).

.PARAMETER Tenant
    Tenant ID.

.PARAMETER Description
    Description.

.PARAMETER Comments
    Comments.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBVirtualCircuit -Id 1 -Status "active"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBVirtualCircuit {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Cid,

        [uint64]$Provider_Network,

        [uint64]$Provider_Account,

        [uint64]$Type,

        [ValidateSet('planned', 'provisioning', 'active', 'offline', 'deprovisioning', 'decommissioned')]
        [string]$Status,

        [uint64]$Tenant,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'virtual-circuits', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Virtual Circuit')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBVirtualCircuitTermination.ps1

<#
.SYNOPSIS
    Updates an existing virtual circuit termination in Netbox.

.DESCRIPTION
    Updates an existing virtual circuit termination in Netbox.

.PARAMETER Id
    The ID of the termination to update.

.PARAMETER Virtual_Circuit
    Virtual circuit ID.

.PARAMETER Interface
    Interface ID.

.PARAMETER Role
    Role (peer, hub, spoke).

.PARAMETER Description
    Description.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBVirtualCircuitTermination -Id 1 -Role "hub"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBVirtualCircuitTermination {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [uint64]$Virtual_Circuit,

        [uint64]$Interface,

        [ValidateSet('peer', 'hub', 'spoke')]
        [string]$Role,

        [string]$Description,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'virtual-circuit-terminations', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Virtual Circuit Termination')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBVirtualCircuitType.ps1

<#
.SYNOPSIS
    Updates an existing virtual circuit type in Netbox.

.DESCRIPTION
    Updates an existing virtual circuit type in Netbox.

.PARAMETER Id
    The ID of the virtual circuit type to update.

.PARAMETER Name
    Name of the virtual circuit type.

.PARAMETER Slug
    URL-friendly slug.

.PARAMETER Color
    Color code (6 hex characters).

.PARAMETER Description
    Description.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBVirtualCircuitType -Id 1 -Description "Updated"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBVirtualCircuitType {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [ValidatePattern('^[0-9a-fA-F]{6}$')]
        [string]$Color,

        [string]$Description,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'virtual-circuit-types', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Virtual Circuit Type')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBVirtualizationCluster.ps1

<#
.SYNOPSIS
    Updates an existing virtualization cluster in Netbox.

.DESCRIPTION
    Updates an existing virtualization cluster in the Netbox virtualization module.
    Supports pipeline input from Get-NBVirtualizationCluster.

.PARAMETER Id
    The database ID of the cluster to update. Accepts pipeline input.

.PARAMETER Name
    The new name of the cluster.

.PARAMETER Type
    The database ID of the cluster type.

.PARAMETER Group
    The database ID of the cluster group.

.PARAMETER Site
    The database ID of the site.

.PARAMETER Status
    The operational status: planned, staging, active, decommissioning, offline.

.PARAMETER Tenant
    The database ID of the tenant.

.PARAMETER Description
    A description of the cluster.

.PARAMETER Comments
    Additional comments about the cluster.

.PARAMETER Tags
    Array of tag IDs to assign.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVirtualizationCluster -Id 1 -Description "Updated description"

    Updates the description of cluster ID 1.

.EXAMPLE
    Get-NBVirtualizationCluster -Name "prod-cluster" | Set-NBVirtualizationCluster -Status "active"

    Updates a cluster found by name via pipeline.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/cluster/
#>
function Set-NBVirtualizationCluster {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Name,

        [uint64]$Type,

        [uint64]$Group,

        [uint64]$Site,

        [ValidateSet('planned', 'staging', 'active', 'decommissioning', 'offline', IgnoreCase = $true)]
        [string]$Status,

        [uint64]$Tenant,

        [string]$Description,

        [string]$Comments,

        [uint64[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        foreach ($ClusterId in $Id) {
            $CurrentCluster = Get-NBVirtualizationCluster -Id $ClusterId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'clusters', $CurrentCluster.Id))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force', 'Raw'

            $URI = BuildNewURI -Segments $URIComponents.Segments

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentCluster.Name)", 'Update cluster')) {
                InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Set-NBVirtualizationClusterGroup.ps1

<#
.SYNOPSIS
    Updates an existing virtualization cluster group in Netbox.

.DESCRIPTION
    Updates an existing cluster group in the Netbox virtualization module.
    Supports pipeline input from Get-NBVirtualizationClusterGroup.

.PARAMETER Id
    The database ID of the cluster group to update. Accepts pipeline input.

.PARAMETER Name
    The new name of the cluster group.

.PARAMETER Slug
    URL-friendly unique identifier.

.PARAMETER Description
    A description of the cluster group.

.PARAMETER Tags
    Array of tag IDs to assign.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVirtualizationClusterGroup -Id 1 -Description "Updated description"

    Updates the description of cluster group ID 1.

.EXAMPLE
    Get-NBVirtualizationClusterGroup -Name "prod" | Set-NBVirtualizationClusterGroup -Name "Production"

    Updates a cluster group found by name via pipeline.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/clustergroup/
#>
function Set-NBVirtualizationClusterGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Name,

        [string]$Slug,

        [string]$Description,

        [uint64[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        foreach ($GroupId in $Id) {
            $CurrentGroup = Get-NBVirtualizationClusterGroup -Id $GroupId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'cluster-groups', $CurrentGroup.Id))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force', 'Raw'

            $URI = BuildNewURI -Segments $URIComponents.Segments

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentGroup.Name)", 'Update cluster group')) {
                InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Set-NBVirtualizationClusterType.ps1

<#
.SYNOPSIS
    Updates an existing virtualization cluster type in Netbox.

.DESCRIPTION
    Updates an existing cluster type in the Netbox virtualization module.
    Supports pipeline input from Get-NBVirtualizationClusterType.

.PARAMETER Id
    The database ID of the cluster type to update. Accepts pipeline input.

.PARAMETER Name
    The new name of the cluster type.

.PARAMETER Slug
    URL-friendly unique identifier.

.PARAMETER Description
    A description of the cluster type.

.PARAMETER Tags
    Array of tag IDs to assign.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVirtualizationClusterType -Id 1 -Description "VMware vSphere 8.0"

    Updates the description of cluster type ID 1.

.EXAMPLE
    Get-NBVirtualizationClusterType -Slug "kvm" | Set-NBVirtualizationClusterType -Name "KVM/QEMU"

    Updates a cluster type found by slug via pipeline.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/clustertype/
#>
function Set-NBVirtualizationClusterType {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Name,

        [string]$Slug,

        [string]$Description,

        [uint64[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        foreach ($TypeId in $Id) {
            $CurrentType = Get-NBVirtualizationClusterType -Id $TypeId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'cluster-types', $CurrentType.Id))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force', 'Raw'

            $URI = BuildNewURI -Segments $URIComponents.Segments

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentType.Name)", 'Update cluster type')) {
                InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
            }
        }
    }
}

#endregion

#region File Set-NBVirtualMachine.ps1

<#
.SYNOPSIS
    Updates an existing irtualMachine in Netbox V module.

.DESCRIPTION
    Updates an existing irtualMachine in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVirtualMachine

    Returns all irtualMachine objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function Set-NBVirtualMachine {
    [CmdletBinding(ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
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

        #$CurrentVM = Get-NBVirtualMachine -Id $Id -ErrorAction Stop

        Write-Verbose "Finished obtaining VM"

        if ($Force -or $pscmdlet.ShouldProcess($ID, "Set properties on VM ID")) {
            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force'

            $URI = BuildNewURI -Segments $URIComponents.Segments

            InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH
        }
    }
}

#endregion

#region File Set-NBVirtualMachineInterface.ps1

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

    Returns all irtualMachineInterface objects.

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
            $CurrentVMI = Get-NBVirtualMachineInterface -Id $VMI_ID -ErrorAction Stop
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

#region File Set-NBVPNIKEPolicy.ps1

<#
.SYNOPSIS
    Updates an existing PNIKEPolicy in Netbox V module.

.DESCRIPTION
    Updates an existing PNIKEPolicy in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVPNIKEPolicy

    Returns all PNIKEPolicy objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBVPNIKEPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,[uint16]$Version,[string]$Mode,[uint64[]]$Proposals,[string]$Preshared_Key,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','ike-policies',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update IKE policy')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File Set-NBVPNIKEProposal.ps1

<#
.SYNOPSIS
    Updates an existing PNIKEProposal in Netbox V module.

.DESCRIPTION
    Updates an existing PNIKEProposal in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVPNIKEProposal

    Returns all PNIKEProposal objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBVPNIKEProposal {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[string]$Name,
        [string]$Authentication_Method,[string]$Encryption_Algorithm,[string]$Authentication_Algorithm,[uint16]$Group,[uint32]$SA_Lifetime,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','ike-proposals',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update IKE proposal')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File Set-NBVPNIPSecPolicy.ps1

<#
.SYNOPSIS
    Updates an existing PNIPSecPolicy in Netbox V module.

.DESCRIPTION
    Updates an existing PNIPSecPolicy in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVPNIPSecPolicy

    Returns all PNIPSecPolicy objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBVPNIPSecPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[string]$Name,[uint64[]]$Proposals,[bool]$Pfs_Group,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-policies',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update IPSec policy')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File Set-NBVPNIPSecProfile.ps1

<#
.SYNOPSIS
    Updates an existing PNIPSecProfile in Netbox V module.

.DESCRIPTION
    Updates an existing PNIPSecProfile in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVPNIPSecProfile

    Returns all PNIPSecProfile objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBVPNIPSecProfile {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[string]$Name,[string]$Mode,[uint64]$IKE_Policy,[uint64]$IPSec_Policy,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-profiles',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update IPSec profile')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File Set-NBVPNIPSecProposal.ps1

<#
.SYNOPSIS
    Updates an existing PNIPSecProposal in Netbox V module.

.DESCRIPTION
    Updates an existing PNIPSecProposal in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVPNIPSecProposal

    Returns all PNIPSecProposal objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBVPNIPSecProposal {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[string]$Name,[string]$Encryption_Algorithm,[string]$Authentication_Algorithm,[uint32]$SA_Lifetime_Seconds,[uint32]$SA_Lifetime_Data,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-proposals',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update IPSec proposal')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File Set-NBVPNL2VPN.ps1

<#
.SYNOPSIS
    Updates an existing PNL2VPN in Netbox V module.

.DESCRIPTION
    Updates an existing PNL2VPN in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVPNL2VPN

    Returns all PNL2VPN objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBVPNL2VPN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,[string]$Slug,[uint64]$Identifier,[string]$Type,[string]$Status,[uint64]$Tenant,
        [string]$Description,[string]$Comments,[uint64[]]$Import_Targets,[uint64[]]$Export_Targets,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','l2vpns',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update L2VPN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File Set-NBVPNL2VPNTermination.ps1

<#
.SYNOPSIS
    Updates an existing PNL2VPNTermination in Netbox V module.

.DESCRIPTION
    Updates an existing PNL2VPNTermination in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVPNL2VPNTermination

    Returns all PNL2VPNTermination objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBVPNL2VPNTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[uint64]$L2VPN,[string]$Assigned_Object_Type,[uint64]$Assigned_Object_Id,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','l2vpn-terminations',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update L2VPN termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File Set-NBVPNTunnel.ps1

<#
.SYNOPSIS
    Updates an existing PNTunnel in Netbox V module.

.DESCRIPTION
    Updates an existing PNTunnel in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVPNTunnel

    Returns all PNTunnel objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBVPNTunnel {
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

#region File Set-NBVPNTunnelGroup.ps1

<#
.SYNOPSIS
    Updates an existing PNTunnelGroup in Netbox V module.

.DESCRIPTION
    Updates an existing PNTunnelGroup in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVPNTunnelGroup

    Returns all PNTunnelGroup objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBVPNTunnelGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[string]$Name,[string]$Slug,[string]$Description,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','tunnel-groups',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update tunnel group')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File Set-NBVPNTunnelTermination.ps1

<#
.SYNOPSIS
    Updates an existing PNTunnelTermination in Netbox V module.

.DESCRIPTION
    Updates an existing PNTunnelTermination in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVPNTunnelTermination

    Returns all PNTunnelTermination objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBVPNTunnelTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[uint64]$Tunnel,[ValidateSet('peer', 'hub', 'spoke')][string]$Role,[string]$Termination_Type,[uint64]$Termination_Id,[uint64]$Outside_IP,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','tunnel-terminations',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update tunnel termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File Set-NBWebhook.ps1

<#
.SYNOPSIS
    Updates an existing webhook in Netbox.

.DESCRIPTION
    Updates an existing webhook in Netbox Extras module.

.PARAMETER Id
    The ID of the webhook to update.

.PARAMETER Name
    Name of the webhook.

.PARAMETER Payload_Url
    URL to send webhook payload to.

.PARAMETER Description
    Description of the webhook.

.PARAMETER Http_Method
    HTTP method (GET, POST, PUT, PATCH, DELETE).

.PARAMETER Http_Content_Type
    HTTP content type.

.PARAMETER Additional_Headers
    Additional HTTP headers.

.PARAMETER Body_Template
    Body template (Jinja2).

.PARAMETER Secret
    Secret for HMAC signature.

.PARAMETER Ssl_Verification
    Whether to verify SSL certificates.

.PARAMETER Ca_File_Path
    Path to CA certificate file.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBWebhook -Id 1 -Ssl_Verification $true

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBWebhook {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Payload_Url,

        [string]$Description,

        [ValidateSet('GET', 'POST', 'PUT', 'PATCH', 'DELETE')]
        [string]$Http_Method,

        [string]$Http_Content_Type,

        [string]$Additional_Headers,

        [string]$Body_Template,

        [string]$Secret,

        [bool]$Ssl_Verification,

        [string]$Ca_File_Path,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'webhooks', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Webhook')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}

#endregion

#region File Set-NBWirelessLAN.ps1

<#
.SYNOPSIS
    Updates an existing irelessLAN in Netbox W module.

.DESCRIPTION
    Updates an existing irelessLAN in Netbox W module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBWirelessLAN

    Returns all irelessLAN objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBWirelessLAN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[string]$SSID,[uint64]$Group,[string]$Status,[uint64]$VLAN,[uint64]$Tenant,
        [string]$Auth_Type,[string]$Auth_Cipher,[string]$Auth_PSK,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('wireless','wireless-lans',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update wireless LAN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File Set-NBWirelessLANGroup.ps1

<#
.SYNOPSIS
    Updates an existing irelessLANGroup in Netbox W module.

.DESCRIPTION
    Updates an existing irelessLANGroup in Netbox W module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBWirelessLANGroup

    Returns all irelessLANGroup objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBWirelessLANGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[string]$Name,[string]$Slug,[uint64]$Parent,[string]$Description,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('wireless','wireless-lan-groups',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update wireless LAN group')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}

#endregion

#region File Set-NBWirelessLink.ps1

<#
.SYNOPSIS
    Updates an existing irelessLink in Netbox W module.

.DESCRIPTION
    Updates an existing irelessLink in Netbox W module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBWirelessLink

    Returns all irelessLink objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBWirelessLink {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
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

#region File Test-NBAPIConnected.ps1

<#
.SYNOPSIS
    Manages PIConnected in Netbox A module.

.DESCRIPTION
    Manages PIConnected in Netbox A module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Test-NBAPIConnected

    Returns all PIConnected objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function Test-NBAPIConnected {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
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
