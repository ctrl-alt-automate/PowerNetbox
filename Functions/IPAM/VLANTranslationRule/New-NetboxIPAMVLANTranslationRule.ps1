function New-NetboxIPAMVLANTranslationRule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
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
