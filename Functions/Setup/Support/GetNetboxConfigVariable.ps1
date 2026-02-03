function GetNetboxConfigVariable {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return $script:NetboxConfig
}
