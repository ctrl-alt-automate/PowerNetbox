# Function Naming Convention

All PowerNetbox functions follow a consistent naming pattern.

## Pattern

```
[Verb]-NB[Module][Resource]
```

| Part | Description | Example |
|------|-------------|---------|
| Verb | PowerShell approved verb | `Get`, `New`, `Set`, `Remove` |
| NB | Module prefix | Always `NB` |
| Module | Netbox module | `DCIM`, `IPAM`, `Virtual`, etc. |
| Resource | API resource | `Device`, `Address`, `Site`, etc. |

## Verbs

| Verb | HTTP Method | Description |
|------|-------------|-------------|
| `Get-` | GET | Retrieve resources |
| `New-` | POST | Create resources |
| `Set-` | PATCH | Update resources |
| `Remove-` | DELETE | Delete resources |

## Module Prefixes

| Prefix | Netbox Module | Example |
|--------|---------------|---------|
| `DCIM` | Data Center Infrastructure | `Get-NBDCIMDevice` |
| `IPAM` | IP Address Management | `Get-NBIPAMAddress` |
| `Virtual` | Virtualization | `Get-NBVirtualMachine` |
| `Circuit` | Circuits | `Get-NBCircuit` |
| `Tenant` | Tenancy | `Get-NBTenant` |
| `VPN` | VPN | `Get-NBVPNTunnel` |
| `Wireless` | Wireless | `Get-NBWirelessLAN` |
| `Tag` | Extras | `Get-NBTag` |
| `User` | Users | `Get-NBUser` |

## Examples by Module

### DCIM

```powershell
Get-NBDCIMDevice          # Devices
Get-NBDCIMSite            # Sites
Get-NBDCIMRack            # Racks
Get-NBDCIMInterface       # Interfaces
Get-NBDCIMCable           # Cables
Get-NBDCIMManufacturer    # Manufacturers
Get-NBDCIMPlatform        # Platforms
```

### IPAM

```powershell
Get-NBIPAMAddress         # IP Addresses
Get-NBIPAMPrefix          # Prefixes
Get-NBIPAMVlan            # VLANs
Get-NBIPAMVrf             # VRFs
Get-NBIPAMAggregate       # Aggregates
```

### Virtualization

```powershell
Get-NBVirtualMachine           # VMs
Get-NBVirtualMachineInterface  # VM Interfaces
Get-NBCluster                  # Clusters
Get-NBClusterGroup             # Cluster Groups
Get-NBClusterType              # Cluster Types
```

### Circuits

```powershell
Get-NBCircuit             # Circuits
Get-NBCircuitType         # Circuit Types
Get-NBCircuitProvider     # Providers
Get-NBCircuitTermination  # Terminations
```

## Finding Functions

```powershell
# List all functions
Get-Command -Module PowerNetbox

# Find DCIM functions
Get-Command -Module PowerNetbox -Name '*DCIM*'

# Find all Get functions
Get-Command -Module PowerNetbox -Verb Get

# Count functions by verb
Get-Command -Module PowerNetbox | Group-Object Verb | Sort-Object Count -Descending
```

## Mapping to Netbox API

| Function | API Endpoint |
|----------|--------------|
| `Get-NBDCIMDevice` | `GET /api/dcim/devices/` |
| `New-NBDCIMDevice` | `POST /api/dcim/devices/` |
| `Set-NBDCIMDevice` | `PATCH /api/dcim/devices/{id}/` |
| `Remove-NBDCIMDevice` | `DELETE /api/dcim/devices/{id}/` |
| `Get-NBIPAMAddress` | `GET /api/ipam/ip-addresses/` |
| `Get-NBVirtualMachine` | `GET /api/virtualization/virtual-machines/` |
