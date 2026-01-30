function Connect-NBAPI {
<#
    .SYNOPSIS
        Connects to the Netbox API and ensures Credential work properly

    .DESCRIPTION
        Connects to the Netbox API and ensures Credential work properly

    .PARAMETER Hostname
        The hostname for the resource such as netbox.domain.com

    .PARAMETER Credential
        A PSCredential object. Put the API token in the Password field. The Username field is ignored.

        Supports both token formats:
        - v1 (legacy): 40-character hex token, uses 'Token' auth header
        - v2 (4.5+): Starts with 'nbt_', uses 'Bearer' auth header

        The correct auth header is automatically detected based on token format.

        Example: $cred = [PSCredential]::new('api', (ConvertTo-SecureString 'your-api-token' -AsPlainText -Force))

    .PARAMETER Scheme
        Scheme for the URI such as HTTP or HTTPS. Defaults to HTTPS

    .PARAMETER Port
        Port for the resource. Value between 1-65535

    .PARAMETER URI
        The full URI for the resource such as "https://netbox.domain.com:8443"

    .PARAMETER SkipCertificateCheck
        Skip SSL/TLS certificate validation. Use this for self-signed certificates or test environments.
        On PowerShell Core (7+), uses the native -SkipCertificateCheck parameter.
        On PowerShell Desktop (5.1), uses a custom certificate policy callback.

    .PARAMETER TimeoutSeconds
        The number of seconds before the HTTP call times out. Defaults to 30 seconds

    .PARAMETER CacheContentTypes
        If specified, caches content types during connection. This makes an additional API call
        but can be useful for custom scripts that need content type information.
        By default, content types are not cached to improve connection speed.

    .EXAMPLE
        PS C:\> Connect-NBAPI -Hostname "netbox.domain.com"

        This will prompt for Credential, then proceed to attempt a connection to Netbox

#>

    [CmdletBinding(DefaultParameterSetName = 'Manual')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ParameterSetName = 'Manual',
                   Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
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
        [ValidateNotNullOrEmpty()]
        [string]$URI,

        [Parameter(Mandatory = $false)]
        [switch]$SkipCertificateCheck = $false,

        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 65535)]
        [uint16]$TimeoutSeconds = 30,

        [Parameter(Mandatory = $false)]
        [switch]$CacheContentTypes = $false
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

    # Add AllowInsecureRedirect for PS 7.4+ (handles http:// redirects when connecting via https://)
    # Some Netbox instances return http:// URLs in Location headers even when accessed via https://
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -gt 7 -or ($psVersion.Major -eq 7 -and $psVersion.Minor -ge 4)) {
        $invokeParams['AllowInsecureRedirect'] = $true
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

    Write-Verbose "Checking Netbox version compatibility"
    $script:NetboxConfig.NetboxVersion = Get-NBVersion
    $versionString = $script:NetboxConfig.NetboxVersion.'netbox-version'
    $script:NetboxConfig.ParsedVersion = ConvertTo-NetboxVersion -VersionString $versionString

    if ($null -eq $script:NetboxConfig.ParsedVersion) {
        Write-Warning "Could not parse Netbox version '$versionString', assuming compatible"
    } elseif ($script:NetboxConfig.ParsedVersion -lt [version]'4.3') {
        $Script:NetboxConfig.Connected = $false
        throw "Netbox version is incompatible with this PS module. Requires >=4.3, found version $versionString"
    } else {
        Write-Verbose "Found compatible version [$versionString] (parsed: $($script:NetboxConfig.ParsedVersion))!"
    }

    $script:NetboxConfig.Connected = $true
    Write-Verbose "Successfully connected!"

    # Only cache content types if explicitly requested (saves an API call)
    if ($CacheContentTypes) {
        Write-Verbose "Caching content types..."
        $script:NetboxConfig.ContentTypes = Get-NBContentType -Limit 500
    }

    Write-Verbose "Connection process completed"
}