<#
    .NOTES
    ===========================================================================
     Created with:  SAPIEN Technologies, Inc., PowerShell Studio 2020 v5.7.181
     Created on:    2020-10-02 15:52
     Created by:    Claussen
     Organization:  NEOnet
     Filename:      New-NBDDCIM Site.ps1
    ===========================================================================
    .DESCRIPTION
        A description of the file.
#>


function Remove-NBDCIMSite {
    <#
        .SYNOPSIS
            Remove a Site

        .DESCRIPTION
            Remove a DCIM Site from Netbox

        .EXAMPLE
            Remove-NBDDCIM Site -Id 1

            Remove DCM Site with id 1

        .EXAMPLE
            Get-NBDDCIM Site -name My Site | Remove-NBDDCIM Site -confirm:$false

            Remove DCM Site with name My Site without confirmation

    #>

    [CmdletBinding(ConfirmImpact = 'High',
        SupportsShouldProcess = $true)]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id

    )

    begin {

    }

    process {
        Write-Verbose "Removing DCIM Site"
        $CurrentSite = Get-NBDDCIM Site -Id $Id -ErrorAction Stop

        if ($pscmdlet.ShouldProcess("$($CurrentSite.Name)/$($CurrentSite.Id)", "Remove Site")) {
            $Segments = [System.Collections.ArrayList]::new(@('dcim', 'sites', $CurrentSite.Id))

            $URI = BuildNewURI -Segments $Segments

            InvokeNetboxRequest -URI $URI -Method DELETE
        }
    }

    end {

    }
}
