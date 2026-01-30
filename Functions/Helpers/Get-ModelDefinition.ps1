<#
.SYNOPSIS
    Retrieves the API model definition for a Netbox resource.

.DESCRIPTION
    Returns the OpenAPI/Swagger model definition for a specified Netbox resource.
    This is used internally to validate parameters and understand the API schema.

    Can retrieve models by their name (e.g., 'WritableDevice') or by their
    API URI path (e.g., '/api/dcim/devices/').

.PARAMETER ModelName
    The name of the model in the API definition (e.g., 'WritableDevice', 'IPAddress').

.PARAMETER URIPath
    The API URI path to look up the model for (e.g., '/api/dcim/devices/').

.PARAMETER Method
    The HTTP method to get the model definition for. Defaults to 'post'.
    Only applies when using URIPath parameter.

.EXAMPLE
    Get-ModelDefinition -ModelName 'WritableDevice'

    Gets the model definition for the WritableDevice model.

.EXAMPLE
    Get-ModelDefinition -URIPath '/api/dcim/devices/' -Method 'post'

    Gets the POST request model definition for the devices endpoint.

.LINK
    Connect-NBAPI
#>
function Get-ModelDefinition {
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    [OutputType([PSCustomObject])]
    param
    (
        [switch]$Brief,

        [string[]]$Fields,

        [Parameter(ParameterSetName = 'ByName',
                   Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ModelName,

        [Parameter(ParameterSetName = 'ByPath',
                   Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
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
