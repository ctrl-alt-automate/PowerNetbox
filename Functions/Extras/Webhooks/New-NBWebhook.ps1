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
