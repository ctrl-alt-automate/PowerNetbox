function Get-NBIPAMFHRPGroupAssignment {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param(
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Group_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Interface_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Device_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Virtual_Machine_Id,
        [Parameter(ParameterSetName = 'Query')][uint16]$Limit,
        [Parameter(ParameterSetName = 'Query')][uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','fhrp-group-assignments',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('ipam','fhrp-group-assignments'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}
