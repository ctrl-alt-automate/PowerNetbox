function New-NetboxDCIMCable {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
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
