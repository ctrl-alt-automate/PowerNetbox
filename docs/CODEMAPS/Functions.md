# Functions by Module

Complete listing of all PowerNetbox functions organized by Netbox module.

## Summary

| Module | Functions | Description |
|--------|-----------|-------------|
| [DCIM](#dcim) | 180 | Sites, devices, racks, cables, interfaces |
| [IPAM](#ipam) | 73 | IP addresses, prefixes, VLANs, VRFs |
| [Extras](#extras) | 45 | Tags, webhooks, custom fields |
| [Circuits](#circuits) | 44 | Circuits, providers, terminations |
| [VPN](#vpn) | 40 | Tunnels, L2VPN, IKE/IPsec |
| [Users](#users) | 24 | Users, groups, permissions |
| [Virtualization](#virtualization) | 20 | VMs, clusters |
| [Tenancy](#tenancy) | 20 | Tenants, contacts |
| [Wireless](#wireless) | 12 | Wireless LANs and links |
| [Core](#core) | 8 | Data sources, jobs |
| [Plugins](#plugins) | 14 | Branching plugin |
| [Setup](#setup) | 25 | Connection, configuration |

---

## DCIM

Data Center Infrastructure Management - 180 functions

### Devices & Components

| Resource | Get | New | Set | Remove |
|----------|-----|-----|-----|--------|
| Device | `Get-NBDCIMDevice` | `New-NBDCIMDevice` | `Set-NBDCIMDevice` | `Remove-NBDCIMDevice` |
| DeviceType | `Get-NBDCIMDeviceType` | `New-NBDCIMDeviceType` | `Set-NBDCIMDeviceType` | `Remove-NBDCIMDeviceType` |
| DeviceRole | `Get-NBDCIMDeviceRole` | `New-NBDCIMDeviceRole` | `Set-NBDCIMDeviceRole` | `Remove-NBDCIMDeviceRole` |
| Platform | `Get-NBDCIMPlatform` | `New-NBDCIMPlatform` | `Set-NBDCIMPlatform` | `Remove-NBDCIMPlatform` |
| Manufacturer | `Get-NBDCIMManufacturer` | `New-NBDCIMManufacturer` | `Set-NBDCIMManufacturer` | `Remove-NBDCIMManufacturer` |

### Sites & Locations

| Resource | Get | New | Set | Remove |
|----------|-----|-----|-----|--------|
| Site | `Get-NBDCIMSite` | `New-NBDCIMSite` | `Set-NBDCIMSite` | `Remove-NBDCIMSite` |
| SiteGroup | `Get-NBDCIMSiteGroup` | `New-NBDCIMSiteGroup` | `Set-NBDCIMSiteGroup` | `Remove-NBDCIMSiteGroup` |
| Location | `Get-NBDCIMLocation` | `New-NBDCIMLocation` | `Set-NBDCIMLocation` | `Remove-NBDCIMLocation` |
| Region | `Get-NBDCIMRegion` | `New-NBDCIMRegion` | `Set-NBDCIMRegion` | `Remove-NBDCIMRegion` |

### Racks & Power

| Resource | Get | New | Set | Remove |
|----------|-----|-----|-----|--------|
| Rack | `Get-NBDCIMRack` | `New-NBDCIMRack` | `Set-NBDCIMRack` | `Remove-NBDCIMRack` |
| RackRole | `Get-NBDCIMRackRole` | `New-NBDCIMRackRole` | `Set-NBDCIMRackRole` | `Remove-NBDCIMRackRole` |
| RackReservation | `Get-NBDCIMRackReservation` | `New-NBDCIMRackReservation` | `Set-NBDCIMRackReservation` | `Remove-NBDCIMRackReservation` |
| PowerPanel | `Get-NBDCIMPowerPanel` | `New-NBDCIMPowerPanel` | `Set-NBDCIMPowerPanel` | `Remove-NBDCIMPowerPanel` |
| PowerFeed | `Get-NBDCIMPowerFeed` | `New-NBDCIMPowerFeed` | `Set-NBDCIMPowerFeed` | `Remove-NBDCIMPowerFeed` |

### Interfaces & Connections

| Resource | Get | New | Set | Remove |
|----------|-----|-----|-----|--------|
| Interface | `Get-NBDCIMInterface` | `New-NBDCIMInterface` | `Set-NBDCIMInterface` | `Remove-NBDCIMInterface` |
| Cable | `Get-NBDCIMCable` | `New-NBDCIMCable` | `Set-NBDCIMCable` | `Remove-NBDCIMCable` |
| FrontPort | `Get-NBDCIMFrontPort` | `New-NBDCIMFrontPort` | `Set-NBDCIMFrontPort` | `Remove-NBDCIMFrontPort` |
| RearPort | `Get-NBDCIMRearPort` | `New-NBDCIMRearPort` | `Set-NBDCIMRearPort` | `Remove-NBDCIMRearPort` |

### Special Functions

- `Get-NBDCIMRackElevation` - Get rack elevation (supports SVG/JSON render)
- `Get-NBDCIMConnectedDevice` - Find connected device via cable path
- `Get-NBDCIMDeviceWithConfigContext` - Device with rendered config context

---

## IPAM

IP Address Management - 73 functions

### Addresses & Prefixes

| Resource | Get | New | Set | Remove |
|----------|-----|-----|-----|--------|
| Address | `Get-NBIPAMAddress` | `New-NBIPAMAddress` | `Set-NBIPAMAddress` | `Remove-NBIPAMAddress` |
| Prefix | `Get-NBIPAMPrefix` | `New-NBIPAMPrefix` | `Set-NBIPAMPrefix` | `Remove-NBIPAMPrefix` |
| AddressRange | `Get-NBIPAMAddressRange` | `New-NBIPAMAddressRange` | `Set-NBIPAMAddressRange` | `Remove-NBIPAMAddressRange` |
| Aggregate | `Get-NBIPAMAggregate` | `New-NBIPAMAggregate` | `Set-NBIPAMAggregate` | `Remove-NBIPAMAggregate` |

### VLANs & VRFs

| Resource | Get | New | Set | Remove |
|----------|-----|-----|-----|--------|
| VLAN | `Get-NBIPAMVLAN` | `New-NBIPAMVLAN` | `Set-NBIPAMVLAN` | `Remove-NBIPAMVLAN` |
| VLANGroup | `Get-NBIPAMVLANGroup` | `New-NBIPAMVLANGroup` | `Set-NBIPAMVLANGroup` | `Remove-NBIPAMVLANGroup` |
| VRF | `Get-NBIPAMVRF` | `New-NBIPAMVRF` | `Set-NBIPAMVRF` | `Remove-NBIPAMVRF` |
| RouteTarget | `Get-NBIPAMRouteTarget` | `New-NBIPAMRouteTarget` | `Set-NBIPAMRouteTarget` | `Remove-NBIPAMRouteTarget` |

### ASN & RIR

| Resource | Get | New | Set | Remove |
|----------|-----|-----|-----|--------|
| ASN | `Get-NBIPAMASN` | `New-NBIPAMASN` | `Set-NBIPAMASN` | `Remove-NBIPAMASN` |
| ASNRange | `Get-NBIPAMASNRange` | `New-NBIPAMASNRange` | `Set-NBIPAMASNRange` | `Remove-NBIPAMASNRange` |
| RIR | `Get-NBIPAMRIR` | `New-NBIPAMRIR` | `Set-NBIPAMRIR` | `Remove-NBIPAMRIR` |

### Special Functions

- `Get-NBIPAMAvailableIP` - Get next available IP in prefix
- `Get-NBIPAMAvailablePrefix` - Get next available prefix

---

## Virtualization

Virtual machines and clusters - 20 functions

| Resource | Get | New | Set | Remove |
|----------|-----|-----|-----|--------|
| VirtualMachine | `Get-NBVirtualMachine` | `New-NBVirtualMachine` | `Set-NBVirtualMachine` | `Remove-NBVirtualMachine` |
| VMInterface | `Get-NBVirtualMachineInterface` | `New-NBVirtualMachineInterface` | `Set-NBVirtualMachineInterface` | `Remove-NBVirtualMachineInterface` |
| Cluster | `Get-NBVirtualizationCluster` | `New-NBVirtualizationCluster` | `Set-NBVirtualizationCluster` | `Remove-NBVirtualizationCluster` |
| ClusterGroup | `Get-NBVirtualizationClusterGroup` | `New-NBVirtualizationClusterGroup` | `Set-NBVirtualizationClusterGroup` | `Remove-NBVirtualizationClusterGroup` |
| ClusterType | `Get-NBVirtualizationClusterType` | `New-NBVirtualizationClusterType` | `Set-NBVirtualizationClusterType` | `Remove-NBVirtualizationClusterType` |

---

## Circuits

Circuits and providers - 44 functions

| Resource | Get | New | Set | Remove |
|----------|-----|-----|-----|--------|
| Circuit | `Get-NBCircuit` | `New-NBCircuit` | `Set-NBCircuit` | `Remove-NBCircuit` |
| CircuitType | `Get-NBCircuitType` | `New-NBCircuitType` | `Set-NBCircuitType` | `Remove-NBCircuitType` |
| CircuitTermination | `Get-NBCircuitTermination` | `New-NBCircuitTermination` | `Set-NBCircuitTermination` | `Remove-NBCircuitTermination` |
| Provider | `Get-NBCircuitProvider` | `New-NBCircuitProvider` | `Set-NBCircuitProvider` | `Remove-NBCircuitProvider` |
| ProviderAccount | `Get-NBCircuitProviderAccount` | `New-NBCircuitProviderAccount` | `Set-NBCircuitProviderAccount` | `Remove-NBCircuitProviderAccount` |
| ProviderNetwork | `Get-NBCircuitProviderNetwork` | `New-NBCircuitProviderNetwork` | `Set-NBCircuitProviderNetwork` | `Remove-NBCircuitProviderNetwork` |

---

## Tenancy

Tenants and contacts - 20 functions

| Resource | Get | New | Set | Remove |
|----------|-----|-----|-----|--------|
| Tenant | `Get-NBTenant` | `New-NBTenant` | `Set-NBTenant` | `Remove-NBTenant` |
| TenantGroup | `Get-NBTenantGroup` | `New-NBTenantGroup` | `Set-NBTenantGroup` | `Remove-NBTenantGroup` |
| Contact | `Get-NBContact` | `New-NBContact` | `Set-NBContact` | `Remove-NBContact` |
| ContactRole | `Get-NBContactRole` | `New-NBContactRole` | `Set-NBContactRole` | `Remove-NBContactRole` |
| ContactAssignment | `Get-NBContactAssignment` | `New-NBContactAssignment` | `Set-NBContactAssignment` | `Remove-NBContactAssignment` |

---

## VPN

VPN tunnels and IPsec - 40 functions

| Resource | Get | New | Set | Remove |
|----------|-----|-----|-----|--------|
| Tunnel | `Get-NBVPNTunnel` | `New-NBVPNTunnel` | `Set-NBVPNTunnel` | `Remove-NBVPNTunnel` |
| TunnelGroup | `Get-NBVPNTunnelGroup` | `New-NBVPNTunnelGroup` | `Set-NBVPNTunnelGroup` | `Remove-NBVPNTunnelGroup` |
| TunnelTermination | `Get-NBVPNTunnelTermination` | `New-NBVPNTunnelTermination` | `Set-NBVPNTunnelTermination` | `Remove-NBVPNTunnelTermination` |
| IKEPolicy | `Get-NBVPNIKEPolicy` | `New-NBVPNIKEPolicy` | `Set-NBVPNIKEPolicy` | `Remove-NBVPNIKEPolicy` |
| IKEProposal | `Get-NBVPNIKEProposal` | `New-NBVPNIKEProposal` | `Set-NBVPNIKEProposal` | `Remove-NBVPNIKEProposal` |
| IPSecPolicy | `Get-NBVPNIPSecPolicy` | `New-NBVPNIPSecPolicy` | `Set-NBVPNIPSecPolicy` | `Remove-NBVPNIPSecPolicy` |
| IPSecProfile | `Get-NBVPNIPSecProfile` | `New-NBVPNIPSecProfile` | `Set-NBVPNIPSecProfile` | `Remove-NBVPNIPSecProfile` |
| IPSecProposal | `Get-NBVPNIPSecProposal` | `New-NBVPNIPSecProposal` | `Set-NBVPNIPSecProposal` | `Remove-NBVPNIPSecProposal` |
| L2VPN | `Get-NBVPNL2VPN` | `New-NBVPNL2VPN` | `Set-NBVPNL2VPN` | `Remove-NBVPNL2VPN` |
| L2VPNTermination | `Get-NBVPNL2VPNTermination` | `New-NBVPNL2VPNTermination` | `Set-NBVPNL2VPNTermination` | `Remove-NBVPNL2VPNTermination` |

---

## Wireless

Wireless LANs and links - 12 functions

| Resource | Get | New | Set | Remove |
|----------|-----|-----|-----|--------|
| WirelessLAN | `Get-NBWirelessLAN` | `New-NBWirelessLAN` | `Set-NBWirelessLAN` | `Remove-NBWirelessLAN` |
| WirelessLANGroup | `Get-NBWirelessLANGroup` | `New-NBWirelessLANGroup` | `Set-NBWirelessLANGroup` | `Remove-NBWirelessLANGroup` |
| WirelessLink | `Get-NBWirelessLink` | `New-NBWirelessLink` | `Set-NBWirelessLink` | `Remove-NBWirelessLink` |

---

## Extras

Tags, webhooks, custom fields - 45 functions

| Resource | Get | New | Set | Remove |
|----------|-----|-----|-----|--------|
| Tag | `Get-NBTag` | `New-NBTag` | `Set-NBTag` | `Remove-NBTag` |
| Webhook | `Get-NBWebhook` | `New-NBWebhook` | `Set-NBWebhook` | `Remove-NBWebhook` |
| CustomField | `Get-NBCustomField` | `New-NBCustomField` | `Set-NBCustomField` | `Remove-NBCustomField` |
| CustomFieldChoiceSet | `Get-NBCustomFieldChoiceSet` | `New-NBCustomFieldChoiceSet` | `Set-NBCustomFieldChoiceSet` | `Remove-NBCustomFieldChoiceSet` |
| CustomLink | `Get-NBCustomLink` | `New-NBCustomLink` | `Set-NBCustomLink` | `Remove-NBCustomLink` |
| ConfigContext | `Get-NBConfigContext` | `New-NBConfigContext` | `Set-NBConfigContext` | `Remove-NBConfigContext` |
| ConfigTemplate | `Get-NBConfigTemplate` | `New-NBConfigTemplate` | `Set-NBConfigTemplate` | `Remove-NBConfigTemplate` |
| EventRule | `Get-NBEventRule` | `New-NBEventRule` | `Set-NBEventRule` | `Remove-NBEventRule` |
| ExportTemplate | `Get-NBExportTemplate` | `New-NBExportTemplate` | `Set-NBExportTemplate` | `Remove-NBExportTemplate` |
| JournalEntry | `Get-NBJournalEntry` | `New-NBJournalEntry` | `Set-NBJournalEntry` | `Remove-NBJournalEntry` |
| Bookmark | `Get-NBBookmark` | `New-NBBookmark` | - | `Remove-NBBookmark` |
| ObjectNotification | `Get-NBObjectNotification` | `New-NBObjectNotification` | `Set-NBObjectNotification` | `Remove-NBObjectNotification` |

---

## Core

Data sources and jobs - 8 functions

| Resource | Get | New | Set | Remove |
|----------|-----|-----|-----|--------|
| DataSource | `Get-NBDataSource` | `New-NBDataSource` | `Set-NBDataSource` | `Remove-NBDataSource` |
| DataFile | `Get-NBDataFile` | - | - | - |
| Job | `Get-NBJob` | - | - | - |
| ObjectChange | `Get-NBObjectChange` | - | - | - |
| ObjectType | `Get-NBObjectType` | - | - | - |

---

## Users

Users, groups, permissions - 24 functions

| Resource | Get | New | Set | Remove |
|----------|-----|-----|-----|--------|
| User | `Get-NBUser` | `New-NBUser` | `Set-NBUser` | `Remove-NBUser` |
| Group | `Get-NBGroup` | `New-NBGroup` | `Set-NBGroup` | `Remove-NBGroup` |
| Permission | `Get-NBPermission` | `New-NBPermission` | `Set-NBPermission` | `Remove-NBPermission` |
| Token | `Get-NBToken` | `New-NBToken` | `Set-NBToken` | `Remove-NBToken` |
| Owner | `Get-NBOwner` | `New-NBOwner` | `Set-NBOwner` | `Remove-NBOwner` |
| OwnerGroup | `Get-NBOwnerGroup` | `New-NBOwnerGroup` | `Set-NBOwnerGroup` | `Remove-NBOwnerGroup` |

---

## Plugins

### Branching (netbox-branching)

Requires [netbox-branching](https://github.com/netboxlabs/netbox-branching) plugin.

| Resource | Functions |
|----------|-----------|
| Branch | `Get-NBBranch`, `New-NBBranch`, `Set-NBBranch`, `Remove-NBBranch` |
| Branch Context | `Enter-NBBranch`, `Exit-NBBranch`, `Get-NBBranchContext`, `Invoke-NBInBranch` |
| Branch Operations | `Sync-NBBranch`, `Merge-NBBranch`, `Undo-NBBranchMerge` |
| Events & Changes | `Get-NBBranchEvent`, `Get-NBChangeDiff` |
| Availability | `Test-NBBranchingAvailable` |

---

## Setup

Connection and configuration functions - 25 functions

### Connection

| Function | Purpose |
|----------|---------|
| `Connect-NBAPI` | Establish connection to Netbox |
| `Test-NBAuthentication` | Verify authentication |
| `Get-NBVersion` | Get Netbox version |

### Credentials

| Function | Purpose |
|----------|---------|
| `Get-NBCredential` | Get stored credential |
| `Set-NBCredential` | Store credential |
| `Clear-NBCredential` | Remove credential |

### Configuration

| Function | Purpose |
|----------|---------|
| `Get-NBHostname` | Get configured hostname |
| `Set-NBHostname` | Set hostname |
| `Get-NBHostScheme` | Get scheme (http/https) |
| `Set-NBHostScheme` | Set scheme |
| `Get-NBTimeout` | Get request timeout |
| `Set-NBTimeout` | Set request timeout |

### SSL

| Function | Purpose |
|----------|---------|
| `Set-NBuntrustedSSL` | Allow self-signed certs (Desktop) |
| `Set-NBCipherSSL` | Configure cipher suites |

### GraphQL

| Function | Purpose |
|----------|---------|
| `Invoke-NBGraphQL` | Execute GraphQL query |
