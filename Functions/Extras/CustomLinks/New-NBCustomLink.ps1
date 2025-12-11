<#
.SYNOPSIS
    Creates a new custom link in Netbox.

.DESCRIPTION
    Creates a new custom link in Netbox Extras module.

.PARAMETER Name
    Name of the custom link.

.PARAMETER Object_Types
    Object types this link applies to.

.PARAMETER Enabled
    Whether the link is enabled.

.PARAMETER Link_Text
    Link text (Jinja2 template).

.PARAMETER Link_Url
    Link URL (Jinja2 template).

.PARAMETER Weight
    Display weight.

.PARAMETER Group_Name
    Group name for organizing links.

.PARAMETER Button_Class
    Button CSS class.

.PARAMETER New_Window
    Whether to open in new window.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBCustomLink -Name "External Doc" -Object_Types @("dcim.device") -Link_Text "View Docs" -Link_Url "https://docs.example.com/{{ object.name }}"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBCustomLink {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string[]]$Object_Types,

        [bool]$Enabled,

        [Parameter(Mandatory = $true)]
        [string]$Link_Text,

        [Parameter(Mandatory = $true)]
        [string]$Link_Url,

        [uint16]$Weight,

        [string]$Group_Name,

        [ValidateSet('outline-dark', 'blue', 'indigo', 'purple', 'pink', 'red', 'orange', 'yellow', 'green', 'teal', 'cyan', 'gray', 'black', 'white', 'ghost-dark')]
        [string]$Button_Class,

        [bool]$New_Window,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-links'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Custom Link')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
