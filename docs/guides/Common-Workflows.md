# Common Workflows

Real-world examples and use cases for PowerNetbox.

## Bulk Import from CSV

PowerNetbox supports native bulk operations for high-performance imports. See [Bulk Operations](Bulk-Operations.md) for comprehensive examples.

### Import Devices (Bulk Mode)

```powershell
# devices.csv:
# Name,Role,Device_Type,Site,Status
# server01,1,1,1,active
# server02,1,1,1,active

# Fast bulk import - batches requests automatically
Import-Csv devices.csv | New-NBDCIMDevice -BatchSize 100 -Force
```

### Import IP Addresses

```powershell
# ips.csv:
# Address,Description,Tenant
# 10.0.0.1/24,Web Server,1
# 10.0.0.2/24,Database Server,1

Import-Csv ips.csv | ForEach-Object {
    New-NBIPAMAddress -Address $_.Address -Description $_.Description -Tenant $_.Tenant
}
```

### Import VLANs (Bulk Mode)

```powershell
# vlans.csv:
# VID,Name,Status,Site
# 100,Management,active,1
# 101,Production,active,1

Import-Csv vlans.csv | New-NBIPAMVLAN -BatchSize 50 -Force
```

## Create VM with Interface and IP

```powershell
# Create VM
$vm = New-NBVirtualMachine -Name 'web-server-01' -Cluster 1 -Status 'active'

# Add interface
$interface = New-NBVirtualMachineInterface -Name 'eth0' -Virtual_Machine $vm.id

# Create IP address
$ip = New-NBIPAMAddress -Address '192.168.1.100/24'

# Assign IP to interface
Set-NBIPAMAddress -Id $ip.id `
    -Assigned_Object_Type 'virtualization.vminterface' `
    -Assigned_Object_Id $interface.id
```

## Inventory Report

### Export All Devices to CSV

```powershell
Get-NBDCIMDevice |
    Select-Object name, device_type, site, status, primary_ip4 |
    Export-Csv -Path 'device-inventory.csv' -NoTypeInformation
```

### Count Devices by Site

```powershell
Get-NBDCIMDevice |
    Group-Object -Property { $_.site.name } |
    Select-Object Name, Count |
    Sort-Object Count -Descending
```

### Find Devices Without IP

```powershell
Get-NBDCIMDevice | Where-Object { -not $_.primary_ip4 }
```

## IP Address Management

### Find Available IPs in Prefix

```powershell
# Get available IPs from a prefix
Get-NBIPAMPrefix -Prefix '10.0.0.0/24' | ForEach-Object {
    # Request next available IP
    $nextIP = Invoke-RestMethod -Uri "$($_.url)available-ips/" -Method POST
    $nextIP
}
```

### Find Duplicate IPs

```powershell
Get-NBIPAMAddress |
    Group-Object address |
    Where-Object { $_.Count -gt 1 } |
    Select-Object Name, Count
```

## Pipeline Operations

### Update Multiple Devices (Bulk Mode)

```powershell
# Bulk update all planned devices to active
$updates = Get-NBDCIMDevice -Status 'planned' | ForEach-Object {
    [PSCustomObject]@{
        Id     = $_.id
        Status = 'active'
    }
}
$updates | Set-NBDCIMDevice -BatchSize 50 -Force

# Add tag to all servers
$updates = Get-NBDCIMDevice -Name 'server*' | ForEach-Object {
    [PSCustomObject]@{
        Id   = $_.id
        Tags = @(1, 2)  # Tag IDs
    }
}
$updates | Set-NBDCIMDevice -Force
```

### Bulk Delete

```powershell
# Remove all planned devices (with confirmation)
Get-NBDCIMDevice -Status 'planned' | Remove-NBDCIMDevice -Confirm

# Remove without confirmation (use with caution!)
Get-NBDCIMDevice -Status 'decommissioning' | Remove-NBDCIMDevice -BatchSize 50 -Force
```

## Reporting

### Generate Site Summary

```powershell
$sites = Get-NBDCIMSite

foreach ($site in $sites) {
    $deviceCount = (Get-NBDCIMDevice -Site $site.id).Count
    $rackCount = (Get-NBDCIMRack -Site $site.id).Count

    [PSCustomObject]@{
        Site = $site.name
        Devices = $deviceCount
        Racks = $rackCount
    }
}
```

### VLAN Usage Report

```powershell
Get-NBIPAMVlan | Select-Object vid, name, site, tenant, status |
    Sort-Object vid |
    Format-Table -AutoSize
```

## Error Handling

```powershell
try {
    $device = New-NBDCIMDevice -Name 'server01' -Device_Type 1 -Site 1
    Write-Host "Created device: $($device.name)" -ForegroundColor Green
}
catch {
    Write-Host "Failed to create device: $($_.Exception.Message)" -ForegroundColor Red
}
```

## Scripting Best Practices

### Use Splatting for Readability

```powershell
$params = @{
    Name = 'new-server'
    Device_Type = 1
    Site = 1
    Status = 'active'
    Description = 'Provisioned via PowerNetbox'
}

New-NBDCIMDevice @params
```

### Store Connection for Scripts

```powershell
# At script start
$token = Get-Content 'token.txt'  # Or use SecretManagement module
$cred = [PSCredential]::new('api', (ConvertTo-SecureString $token -AsPlainText -Force))
Connect-NBAPI -Hostname 'netbox.example.com' -Credential $cred
```

## VMware PowerCLI Integration

Sync VMware vCenter data to Netbox using PowerCLI and PowerNetbox.

### Prerequisites

```powershell
# Install required modules
Install-Module VMware.PowerCLI -Scope CurrentUser
Install-Module PowerNetbox -Scope CurrentUser
```

### Connect to Both Systems

```powershell
# Connect to vCenter
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
Connect-VIServer -Server 'vcenter.example.com' -Credential (Get-Credential)

# Connect to Netbox
$nbCred = [PSCredential]::new('api', (ConvertTo-SecureString 'your-token' -AsPlainText -Force))
Connect-NBAPI -Hostname 'netbox.example.com' -Credential $nbCred
```

### Sync VMware Clusters to Netbox

```powershell
# Get or create cluster type
$clusterType = Get-NBClusterType -Name 'VMware'
if (-not $clusterType) {
    $clusterType = New-NBClusterType -Name 'VMware' -Slug 'vmware'
}

# Sync clusters
Get-Cluster | ForEach-Object {
    $cluster = $_
    $existingCluster = Get-NBCluster -Name $cluster.Name

    if (-not $existingCluster) {
        New-NBCluster -Name $cluster.Name -Type $clusterType.id -Site 1
        Write-Host "Created cluster: $($cluster.Name)" -ForegroundColor Green
    }
}
```

### Sync VMs to Netbox

```powershell
# Full VM sync from vCenter to Netbox
function Sync-VMwareToNetbox {
    param(
        [int]$SiteId = 1,
        [int]$ClusterId
    )

    $vms = Get-VM
    $count = 0

    foreach ($vm in $vms) {
        # Check if VM exists in Netbox
        $existingVM = Get-NBVirtualMachine -Name $vm.Name

        # Get VM details
        $vmView = $vm | Get-View
        $vcpus = $vm.NumCpu
        $memoryMB = $vm.MemoryMB
        $diskGB = [math]::Round(($vm.ProvisionedSpaceGB), 0)

        # Determine status
        $status = switch ($vm.PowerState) {
            'PoweredOn'  { 'active' }
            'PoweredOff' { 'offline' }
            'Suspended'  { 'staged' }
            default      { 'active' }
        }

        $params = @{
            Name     = $vm.Name
            Status   = $status
            Vcpus    = $vcpus
            Memory   = $memoryMB
            Disk     = $diskGB
            Comments = "Last synced: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        }

        if ($ClusterId) { $params['Cluster'] = $ClusterId }

        if ($existingVM) {
            # Update existing VM
            Set-NBVirtualMachine -Id $existingVM.id @params
            Write-Host "Updated: $($vm.Name)" -ForegroundColor Yellow
        }
        else {
            # Create new VM
            New-NBVirtualMachine @params
            Write-Host "Created: $($vm.Name)" -ForegroundColor Green
        }

        $count++
    }

    Write-Host "`nSynced $count VMs" -ForegroundColor Cyan
}

# Run sync
Sync-VMwareToNetbox -ClusterId 1
```

### Sync VM Interfaces and IPs

```powershell
function Sync-VMNetworkToNetbox {
    param([string]$VMName)

    $vm = Get-VM -Name $VMName
    $nbVM = Get-NBVirtualMachine -Name $VMName

    if (-not $nbVM) {
        Write-Error "VM not found in Netbox: $VMName"
        return
    }

    # Get network adapters
    $nics = Get-NetworkAdapter -VM $vm

    foreach ($nic in $nics) {
        $ifName = $nic.Name
        $macAddress = $nic.MacAddress

        # Check if interface exists
        $existingIF = Get-NBVirtualMachineInterface -Virtual_Machine_Id $nbVM.id |
            Where-Object { $_.name -eq $ifName }

        if (-not $existingIF) {
            $newIF = New-NBVirtualMachineInterface -Name $ifName -Virtual_Machine $nbVM.id -Mac_Address $macAddress
            Write-Host "Created interface: $ifName" -ForegroundColor Green
        }
    }

    # Get IP addresses from VMware Tools
    $vmGuest = Get-VMGuest -VM $vm

    foreach ($ip in $vmGuest.IPAddress) {
        # Skip IPv6 link-local
        if ($ip -like 'fe80::*') { continue }

        # Determine prefix length
        $prefix = if ($ip -like '*:*') { '/128' } else { '/24' }
        $address = "$ip$prefix"

        # Check if IP exists in Netbox
        $existingIP = Get-NBIPAMAddress -Address $ip

        if (-not $existingIP) {
            $nbIF = Get-NBVirtualMachineInterface -Virtual_Machine_Id $nbVM.id | Select-Object -First 1

            $newIP = New-NBIPAMAddress -Address $address -Description "VM: $VMName"

            if ($nbIF) {
                Set-NBIPAMAddress -Id $newIP.id `
                    -Assigned_Object_Type 'virtualization.vminterface' `
                    -Assigned_Object_Id $nbIF.id
            }

            Write-Host "Created IP: $address" -ForegroundColor Green
        }
    }
}

# Sync network for all VMs
Get-VM | ForEach-Object { Sync-VMNetworkToNetbox -VMName $_.Name }
```

### Complete VMware Sync Script

```powershell
<#
.SYNOPSIS
    Syncs VMware vCenter inventory to Netbox
.DESCRIPTION
    This script connects to vCenter and Netbox, then syncs:
    - Clusters
    - Virtual Machines (with CPU, memory, disk)
    - VM Interfaces and MAC addresses
    - IP Addresses
#>

param(
    [Parameter(Mandatory)]
    [string]$vCenterServer,

    [Parameter(Mandatory)]
    [string]$NetboxHost,

    [Parameter(Mandatory)]
    [string]$NetboxToken,

    [int]$SiteId = 1
)

# Connect to systems
Connect-VIServer -Server $vCenterServer
$cred = [PSCredential]::new('api', (ConvertTo-SecureString $NetboxToken -AsPlainText -Force))
Connect-NBAPI -Hostname $NetboxHost -Credential $cred

# Ensure cluster type exists
$clusterType = Get-NBClusterType -Name 'VMware'
if (-not $clusterType) {
    $clusterType = New-NBClusterType -Name 'VMware' -Slug 'vmware'
}

# Sync clusters
Write-Host "`n=== Syncing Clusters ===" -ForegroundColor Cyan
Get-Cluster | ForEach-Object {
    $existing = Get-NBCluster -Name $_.Name
    if (-not $existing) {
        New-NBCluster -Name $_.Name -Type $clusterType.id -Site $SiteId
        Write-Host "Created: $($_.Name)" -ForegroundColor Green
    }
}

# Sync VMs
Write-Host "`n=== Syncing VMs ===" -ForegroundColor Cyan
Get-VM | ForEach-Object {
    $vm = $_
    $existing = Get-NBVirtualMachine -Name $vm.Name

    $params = @{
        Name   = $vm.Name
        Status = if ($vm.PowerState -eq 'PoweredOn') { 'active' } else { 'offline' }
        Vcpus  = $vm.NumCpu
        Memory = $vm.MemoryMB
        Disk   = [math]::Round($vm.ProvisionedSpaceGB)
    }

    # Get Netbox cluster ID
    $vmCluster = Get-Cluster -VM $vm
    if ($vmCluster) {
        $nbCluster = Get-NBCluster -Name $vmCluster.Name
        if ($nbCluster) { $params['Cluster'] = $nbCluster.id }
    }

    if ($existing) {
        Set-NBVirtualMachine -Id $existing.id @params
    }
    else {
        New-NBVirtualMachine @params
    }
}

Write-Host "`n=== Sync Complete ===" -ForegroundColor Green
Disconnect-VIServer -Confirm:$false
```

### Schedule Regular Sync

```powershell
# Create scheduled task (Windows)
$action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument '-File C:\Scripts\Sync-VMwareToNetbox.ps1'
$trigger = New-ScheduledTaskTrigger -Daily -At '02:00'
Register-ScheduledTask -TaskName 'Netbox VMware Sync' -Action $action -Trigger $trigger
```
