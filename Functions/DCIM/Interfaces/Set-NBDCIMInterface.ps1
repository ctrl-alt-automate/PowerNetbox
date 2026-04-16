<#
.SYNOPSIS
    Updates an existing DCIM Interface in Netbox DCIM module.

.DESCRIPTION
    Updates an existing DCIM Interface in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMInterface

    Updates an existing DCIM Interface object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMInterface {
    [CmdletBinding(ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [uint64]$Device,

        [string]$Name,

        [bool]$Enabled,

        [ValidateSet('virtual', 'bridge', 'lag', '100base-fx', '100base-lfx', '100base-tx', '100base-t1', '1000base-bx10-d', '1000base-bx10-u', '1000base-cwdm', '1000base-cx', '1000base-dwdm', '1000base-ex', '1000base-sx', '1000base-lsx', '1000base-lx', '1000base-lx10', '1000base-t', '1000base-tx', '1000base-zx', '2.5gbase-t', '5gbase-t', '10gbase-br-d', '10gbase-br-u', '10gbase-cu', '10gbase-cx4', '10gbase-er', '10gbase-lr', '10gbase-lrm', '10gbase-lx4', '10gbase-sr', '10gbase-t', '10gbase-zr', '25gbase-cr', '25gbase-er', '25gbase-lr', '25gbase-sr', '25gbase-t', '40gbase-cr4', '40gbase-er4', '40gbase-fr4', '40gbase-lr4', '40gbase-sr4', '40gbase-sr4-bd', '50gbase-cr', '50gbase-er', '50gbase-fr', '50gbase-lr', '50gbase-sr', '100gbase-cr1', '100gbase-cr2', '100gbase-cr4', '100gbase-cr10', '100gbase-cwdm4', '100gbase-dr', '100gbase-fr1', '100gbase-er4', '100gbase-lr1', '100gbase-lr4', '100gbase-sr1', '100gbase-sr1.2', '100gbase-sr2', '100gbase-sr4', '100gbase-sr10', '100gbase-zr', '200gbase-cr2', '200gbase-cr4', '200gbase-sr2', '200gbase-sr4', '200gbase-dr4', '200gbase-fr4', '200gbase-lr4', '200gbase-er4', '200gbase-vr2', '400gbase-cr4', '400gbase-dr4', '400gbase-er8', '400gbase-fr4', '400gbase-fr8', '400gbase-lr4', '400gbase-lr8', '400gbase-sr4', '400gbase-sr4_2', '400gbase-sr8', '400gbase-sr16', '400gbase-vr4', '400gbase-zr', '800gbase-cr8', '800gbase-dr8', '800gbase-sr8', '800gbase-vr8', '1.6tbase-cr8', '1.6tbase-dr8', '1.6tbase-dr8-2', '100base-x-sfp', '1000base-x-gbic', '1000base-x-sfp', '2.5gbase-x-sfp', '10gbase-x-sfpp', '10gbase-x-xfp', '10gbase-x-xenpak', '10gbase-x-x2', '25gbase-x-sfp28', '50gbase-x-sfp56', '40gbase-x-qsfpp', '50gbase-x-sfp28', '100gbase-x-cfp', '100gbase-x-cfp2', '100gbase-x-cfp4', '100gbase-x-cxp', '100gbase-x-cpak', '100gbase-x-dsfp', '100gbase-x-sfpdd', '100gbase-x-qsfp28', '100gbase-x-qsfpdd', '200gbase-x-cfp2', '200gbase-x-qsfp56', '200gbase-x-qsfpdd', '400gbase-x-cfp2', '400gbase-x-qsfp112', '400gbase-x-qsfpdd', '400gbase-x-osfp', '400gbase-x-osfp-rhs', '400gbase-x-cdfp', '400gbase-x-cfp8', '800gbase-x-qsfpdd', '800gbase-x-osfp', '1.6tbase-x-osfp1600', '1.6tbase-x-osfp1600-rhs', '1.6tbase-x-qsfpdd1600', '1000base-kx', '2.5gbase-kx', '5gbase-kr', '10gbase-kr', '10gbase-kx4', '25gbase-kr', '40gbase-kr4', '50gbase-kr', '100gbase-kp4', '100gbase-kr2', '100gbase-kr4', '1.6tbase-kr8', 'ieee802.11a', 'ieee802.11g', 'ieee802.11n', 'ieee802.11ac', 'ieee802.11ad', 'ieee802.11ax', 'ieee802.11ay', 'ieee802.11be', 'ieee802.15.1', 'ieee802.15.4', 'other-wireless', 'gsm', 'cdma', 'lte', '4g', '5g', 'sonet-oc3', 'sonet-oc12', 'sonet-oc48', 'sonet-oc192', 'sonet-oc768', 'sonet-oc1920', 'sonet-oc3840', '1gfc-sfp', '2gfc-sfp', '4gfc-sfp', '8gfc-sfpp', '16gfc-sfpp', '32gfc-sfp28', '32gfc-sfpp', '64gfc-qsfpp', '64gfc-sfpdd', '64gfc-sfpp', '128gfc-qsfp28', 'infiniband-sdr', 'infiniband-ddr', 'infiniband-qdr', 'infiniband-fdr10', 'infiniband-fdr', 'infiniband-edr', 'infiniband-hdr', 'infiniband-ndr', 'infiniband-xdr', 't1', 'e1', 't3', 'e3', 'xdsl', 'docsis', 'moca', 'bpon', 'epon', '10g-epon', 'gpon', 'xg-pon', 'xgs-pon', 'ng-pon2', '25g-pon', '50g-pon', 'cisco-stackwise', 'cisco-stackwise-plus', 'cisco-flexstack', 'cisco-flexstack-plus', 'cisco-stackwise-80', 'cisco-stackwise-160', 'cisco-stackwise-320', 'cisco-stackwise-480', 'cisco-stackwise-1t', 'juniper-vcp', 'extreme-summitstack', 'extreme-summitstack-128', 'extreme-summitstack-256', 'extreme-summitstack-512', 'other', IgnoreCase = $true)]
        [string]$Type,

        [string]$Label,

        [Nullable[uint64]]$Parent,

        [Nullable[uint64]]$Bridge,

        [Nullable[uint64]]$LAG,

        [Nullable[uint64]]$Speed,

        [ValidateSet('full', 'half', 'auto','', IgnoreCase = $false)]
        [AllowEmptyString()]
        [string]$Duplex,

        [bool]$Mark_Connected,

        [string]$WWN,

        [string[]]$VDCS,

        [ValidateRange(1, 65535)]
        [Nullable[uint16]]$MTU,

        [string]$MAC_Address,

        [Nullable[UInt64]]$Primary_MAC_Address,

        [bool]$MGMT_Only,

        [string]$Description,

        [ValidateSet('pd', 'pse','', IgnoreCase = $false)]
        [AllowEmptyString()]
        [string]$POE_Mode,

        [ValidateSet('type1-ieee802.3af', 'type2-ieee802.3at', 'type3-ieee802.3bt', 'type4-ieee802.3bt', 'passive-24v-2pair', 'passive-24v-4pair', 'passive-48v-2pair', 'passive-48v-4pair','', IgnoreCase = $true)]
        [AllowEmptyString()]
        [string]$POE_Type,

        [ValidateSet('access', 'tagged', 'tagged-all', 'q-in-q','100','200','300','', IgnoreCase = $false)]
        [AllowEmptyString()]
        [string]$Mode,

        [string]$Vlan_Group,

        [Nullable[uint64]]$Untagged_VLAN,

        [uint64[]]$Tagged_VLANs,

        [Nullable[uint64]]$QinQ_SVLAN,

        [string]$VRF,

        [ValidateSet('ap', 'station','', IgnoreCase = $false)]
        [AllowEmptyString()]
        [string]$RF_Role,

        [string]$RF_Channel,

        [ValidateRange(1, 1000000)]
        [Nullable[int]]$RF_Channel_Frequency,

        [ValidateRange(1, 10000)]
        [Nullable[int]]$RF_Channel_Width,

        [Nullable[int]]$TX_Power,

        [string]$Changelog_Message,

        [Nullable[uint64]]$Owner,

        [switch]$Force,

        [object[]]$Tags,

        [switch]$Raw
    )

    begin {
        if (-not [System.String]::IsNullOrWhiteSpace($Mode)) {
            $PSBoundParameters.Mode = switch ($Mode) {
                'Access' {
                    'access'
                    break
                }

                '100' {
                    'access'
                    break
                }

                'Tagged' {
                    'tagged'
                    break
                }

                '200' {
                    'tagged'
                    break
                }

                'Tagged All' {
                    'tagged-all'
                    break
                }

                '300' {
                    'tagged-all'
                    break
                }

                'Q-in-Q' {
                    'q-in-q'
                    break
                }

                default {
                    $_
                }
            }
        }
        #Validate wwn format.
        if ($PSBoundParameters.ContainsKey('WWN') -and -not [string]::IsNullOrWhiteSpace($WWN)) {
            if ($WWN -notmatch '^([0-9a-fA-F]{2}:){7}[0-9a-fA-F]{2}$') {
                throw "Invalid WWN format. Expected format is 8 groups of 2 hex digits separated by colons (e.g., 'AA:BB:CC:DD:EE:FF:00:11')"
            }
        }
        #Validate MAC address format.
        if ($PSBoundParameters.ContainsKey('MAC_Address') -and -not [string]::IsNullOrWhiteSpace($MAC_Address)) {
            if ($MAC_Address -notmatch '^([0-9a-fA-F]{2}:){5}([0-9a-fA-F]{2})$') {
                throw "Invalid MAC address format. Expected format is 6 groups of 2 hex digits separated by colons (e.g., 'AA:BB:CC:DD:EE:FF')"
            }
        }
    }

    process {
        Write-Verbose "Updating DCIM Interface"
        foreach ($InterfaceId in $Id) {

            $Segments = [System.Collections.ArrayList]::new(@('dcim', 'interfaces', $InterfaceId))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

            $URI = BuildNewURI -Segments $Segments

            if ($Force -or $PSCmdlet.ShouldProcess("Interface ID $InterfaceId", "Set")) {
                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH -Raw:$Raw
            }
        }
    }

}
