function Get-NetboxDCIMRackReservation {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Rack_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Site_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$User_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Tenant_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [Parameter(ParameterSetName = 'Query')][uint16]$Limit,
        [Parameter(ParameterSetName = 'Query')][uint16]$Offset,
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
