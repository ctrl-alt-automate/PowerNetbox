function New-NBIPAMFHRPGroupAssignment {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param(
        [Parameter(Mandatory = $true)][uint64]$Group,
        [Parameter(Mandatory = $true)][string]$Interface_Type,
        [Parameter(Mandatory = $true)][uint64]$Interface_Id,
        [uint16]$Priority,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam','fhrp-group-assignments'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("Group $Group Interface $Interface_Id", 'Create FHRP group assignment')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
