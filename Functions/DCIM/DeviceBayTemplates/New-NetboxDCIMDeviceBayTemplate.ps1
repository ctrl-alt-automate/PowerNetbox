function New-NetboxDCIMDeviceBayTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
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
