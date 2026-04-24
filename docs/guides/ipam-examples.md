# IPAM Examples

Examples for IP Address Management (IPAM) operations.

## IP Addresses

### List All IP Addresses

```powershell
Get-NBIPAMAddress
```

### Get IP by Address

```powershell
Get-NBIPAMAddress -Address '10.0.0.1'
```

### Get IPs in a Prefix

```powershell
Get-NBIPAMAddress -Parent '10.0.0.0/24'
```

### Get Active IPs

```powershell
Get-NBIPAMAddress -Status 'active'
```

### Create an IP Address

```powershell
New-NBIPAMAddress -Address '10.0.0.1/24' -Description 'Web Server' -Status 'active'
```

### Create IP with Tenant

```powershell
New-NBIPAMAddress -Address '10.0.0.2/24' -Tenant 1 -Description 'Database Server'
```

### Update an IP Address

```powershell
Set-NBIPAMAddress -Id 1 -Description 'Updated description' -Status 'reserved'
```

### Assign IP to Interface

```powershell
Set-NBIPAMAddress -Id 1 `
    -Assigned_Object_Type 'dcim.interface' `
    -Assigned_Object_Id 5
```

### Delete an IP Address

```powershell
Remove-NBIPAMAddress -Id 1 -Confirm
```

## Prefixes

### List All Prefixes

```powershell
Get-NBIPAMPrefix
```

### Get Prefix by CIDR

```powershell
Get-NBIPAMPrefix -Prefix '10.0.0.0/24'
```

### Get Prefixes in a VRF

```powershell
Get-NBIPAMPrefix -Vrf 1
```

### Create a Prefix

```powershell
New-NBIPAMPrefix -Prefix '192.168.1.0/24' -Site 1 -Status 'active' -Description 'Office LAN'
```

### Get Available IPs in Prefix

```powershell
# First get the prefix
$prefix = Get-NBIPAMPrefix -Prefix '10.0.0.0/24'

# Then query available IPs (via raw API)
$uri = "$($prefix.url)available-ips/"
# Note: Use Netbox UI or API directly for this operation
```

## VLANs

### List All VLANs

```powershell
Get-NBIPAMVlan
```

### Get VLAN by VID

```powershell
Get-NBIPAMVlan -Vid 100
```

### Get VLANs in a Site

```powershell
Get-NBIPAMVlan -Site 1
```

### Create a VLAN

```powershell
New-NBIPAMVlan -Vid 100 -Name 'Management' -Site 1 -Status 'active'
```

### Update a VLAN

```powershell
Set-NBIPAMVlan -Id 1 -Description 'Management VLAN'
```

## VRFs

### List All VRFs

```powershell
Get-NBIPAMVrf
```

### Create a VRF

```powershell
New-NBIPAMVrf -Name 'Customer-A' -Rd '65000:100' -Description 'Customer A routing domain'
```

### Get Prefixes in VRF

```powershell
$vrf = Get-NBIPAMVrf -Name 'Customer-A'
Get-NBIPAMPrefix -Vrf $vrf.id
```

## Aggregates & RIRs

### List RIRs

```powershell
Get-NBIPAMRIR
```

### Create an Aggregate

```powershell
New-NBIPAMAggregate -Prefix '10.0.0.0/8' -Rir 1 -Description 'Private range'
```

## IP Ranges

### List IP Ranges

```powershell
Get-NBIPAMRange
```

### Create an IP Range

```powershell
New-NBIPAMRange -Start_Address '10.0.0.100' -End_Address '10.0.0.200' -Description 'DHCP Pool'
```

## Roles

### List IPAM Roles

```powershell
Get-NBIPAMRole
```

### Create a Role

```powershell
New-NBIPAMRole -Name 'Production' -Slug 'production'
```

## Services

### List Services

```powershell
Get-NBIPAMService
```

### Create a Service

```powershell
New-NBIPAMService -Name 'HTTP' -Device 1 -Ports @(80, 443) -Protocol 'tcp'
```

## Bulk Operations

### Export All IPs to CSV

```powershell
Get-NBIPAMAddress |
    Select-Object address, status, description, @{N='tenant';E={$_.tenant.name}} |
    Export-Csv -Path 'ip-addresses.csv' -NoTypeInformation
```

### Import IPs from CSV

```powershell
# ips.csv: Address,Description,Status
Import-Csv ips.csv | ForEach-Object {
    New-NBIPAMAddress -Address $_.Address -Description $_.Description -Status $_.Status
}
```

### Find Duplicate IPs

```powershell
Get-NBIPAMAddress |
    Group-Object address |
    Where-Object { $_.Count -gt 1 } |
    Select-Object Name, Count
```

### Find Unassigned IPs

```powershell
Get-NBIPAMAddress | Where-Object { -not $_.assigned_object }
```

### Count IPs per Status

```powershell
Get-NBIPAMAddress |
    Group-Object status |
    Select-Object @{N='Status';E={$_.Name}}, Count |
    Sort-Object Count -Descending
```

### VLAN Usage Report

```powershell
Get-NBIPAMVlan |
    Select-Object vid, name, @{N='site';E={$_.site.name}}, status |
    Sort-Object vid |
    Format-Table -AutoSize
```
