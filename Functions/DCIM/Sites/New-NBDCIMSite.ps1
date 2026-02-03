<#
    .NOTES
    ===========================================================================
     Created with:  SAPIEN Technologies, Inc., PowerShell Studio 2020 v5.7.181
     Created on:    2020-10-02 15:52
     Created by:    Claussen
     Organization:  NEOnet
     Filename:      New-NBDCIMSite.ps1
    ===========================================================================
    .DESCRIPTION
        A description of the file.
#>



function New-NBDCIMSite {
    <#
    .SYNOPSIS
        Create a new Site to Netbox

    .DESCRIPTION
        Create a new Site to Netbox

    .EXAMPLE
        New-NBDCIMSite -name MySite

        Add new Site MySite on Netbox

    #>

    [CmdletBinding(ConfirmImpact = 'Low',
        SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$Slug,

        [string]$Facility,

        [uint64]$ASN,

        [decimal]$Latitude,

        [decimal]$Longitude,

        [string]$Contact_Name,

        [string]$Contact_Phone,

        [string]$Contact_Email,

        [uint64]$Tenant_Group,

        [uint64]$Tenant,

        [string]$Status,

        [uint64]$Region,

        [string]$Description,

        [string]$Comments,

        [uint64]$Owner,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating DCIM Site"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'sites'))
        $Method = 'POST'

        if (-not $PSBoundParameters.ContainsKey('slug')) {
            $PSBoundParameters.Add('slug', $name)
        }

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($name, 'Create new Site')) {
            InvokeNetboxRequest -URI $URI -Method $Method -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
