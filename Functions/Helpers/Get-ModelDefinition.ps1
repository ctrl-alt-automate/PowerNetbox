
function Get-ModelDefinition {
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    [OutputType([PSCustomObject])]
    param
    (
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
