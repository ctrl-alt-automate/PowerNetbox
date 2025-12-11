<#
.SYNOPSIS
    Creates a new custom field choice set in Netbox.

.DESCRIPTION
    Creates a new custom field choice set in Netbox Extras module.

.PARAMETER Name
    Name of the choice set.

.PARAMETER Description
    Description of the choice set.

.PARAMETER Base_Choices
    Base choices to inherit from.

.PARAMETER Extra_Choices
    Array of extra choices in format @(@("value1", "label1"), @("value2", "label2")).

.PARAMETER Order_Alphabetically
    Whether to order choices alphabetically.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBCustomFieldChoiceSet -Name "Status Options" -Extra_Choices @(@("active", "Active"), @("inactive", "Inactive"))

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBCustomFieldChoiceSet {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$Description,

        [string]$Base_Choices,

        [array]$Extra_Choices,

        [bool]$Order_Alphabetically,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-field-choice-sets'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Custom Field Choice Set')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
