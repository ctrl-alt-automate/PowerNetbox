function New-NetboxDCIMFrontPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
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
