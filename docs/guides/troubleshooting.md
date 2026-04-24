# Troubleshooting

Common issues and their solutions.

## Connection Issues

### Error: "Unable to connect to remote server"

**Cause**: Network connectivity or hostname issue.

**Solution**:
```powershell
# Test connectivity
Test-NetConnection -ComputerName 'netbox.example.com' -Port 443

# Verify hostname resolves
Resolve-DnsName 'netbox.example.com'
```

### Error: "The SSL connection could not be established"

**Cause**: Self-signed or invalid certificate.

**Solution**:
```powershell
# Skip certificate validation
Connect-NBAPI -Hostname 'netbox.local' -Credential $cred -SkipCertificateCheck
```

### Error: "401 Unauthorized"

**Cause**: Invalid or expired API token.

**Solution**:
1. Verify your token in Netbox UI (Admin → API Tokens)
2. Check token hasn't expired
3. Ensure token has required permissions

```powershell
# Verify token format
$cred = [PSCredential]::new('api', (ConvertTo-SecureString 'your-token-here' -AsPlainText -Force))
Connect-NBAPI -Hostname 'netbox.example.com' -Credential $cred
```

### Error: "403 Forbidden"

**Cause**: Token lacks permissions for the requested operation.

**Solution**:
1. Check token permissions in Netbox UI
2. Ensure token allows the action (read/write/delete)
3. For write operations, token needs write permission

## Module Issues

### Module Not Loading

**Symptom**: `Import-Module PowerNetbox` fails.

**Solution**:
```powershell
# Check if module is installed
Get-Module PowerNetbox -ListAvailable

# Reinstall if needed
Install-Module PowerNetbox -Force -Scope CurrentUser

# Clear module cache and reimport
Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue
Import-Module PowerNetbox -Force
```

### Functions Not Found

**Symptom**: `Get-NBDCIMDevice: The term is not recognized...`

**Solution**:
```powershell
# Ensure module is imported
Import-Module PowerNetbox

# Verify functions are exported
Get-Command -Module PowerNetbox | Measure-Object
# Should show 478 commands
```

## API Issues

### Error: "400 Bad Request"

**Cause**: Invalid parameter or missing required field.

**Solution**:
```powershell
# Check required parameters
Get-Help New-NBDCIMDevice -Parameter *

# Example: Device requires name, device_type, and site
New-NBDCIMDevice -Name 'server01' -Device_Type 1 -Site 1
```

### Error: "404 Not Found"

**Cause**: Resource doesn't exist or wrong ID.

**Solution**:
```powershell
# Verify resource exists
Get-NBDCIMDevice -Id 123

# Check if using correct ID type
Get-NBDCIMDevice -Name 'server01'  # By name
Get-NBDCIMDevice -Id 1             # By ID (integer)
```

### Error: "409 Conflict"

**Cause**: Duplicate entry or constraint violation.

**Solution**:
```powershell
# Check for existing resource
Get-NBDCIMDevice -Name 'server01'

# Use Set- to update instead of New- to create
Set-NBDCIMDevice -Id $existingDevice.id -Description 'Updated'
```

## PowerShell Version Issues

### PowerShell 5.1 Compatibility

**Symptom**: Errors on Windows PowerShell 5.1.

**Solution**:
```powershell
# Check version
$PSVersionTable.PSVersion

# PowerNetbox supports 5.1+, but 7+ is recommended
# Install PowerShell 7 for best experience
winget install Microsoft.PowerShell
```

### TLS Errors on PowerShell 5.1

**Cause**: Older TLS version.

**Solution**:
```powershell
# Force TLS 1.2 (run before Connect-NBAPI)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```

## Performance Issues

### Slow Queries

**Cause**: Retrieving too many objects.

**Solution**:
```powershell
# Use -Limit to reduce results
Get-NBDCIMDevice -Limit 50

# Use filters to narrow results
Get-NBDCIMDevice -Site 1 -Status 'active'
```

### Timeout Errors

**Cause**: Large result sets or slow network.

**Solution**:
```powershell
# Use pagination
$offset = 0
$limit = 100
do {
    $devices = Get-NBDCIMDevice -Limit $limit -Offset $offset
    # Process devices...
    $offset += $limit
} while ($devices.Count -eq $limit)
```

## Getting More Help

### Enable Verbose Output

```powershell
Get-NBDCIMDevice -Verbose
```

### Check Raw API Response

```powershell
# Use -Raw to see unprocessed API response
Get-NBDCIMDevice -Id 1 -Raw | ConvertTo-Json -Depth 10
```

### Report Issues

If you encounter a bug, please report it:
- [GitHub Issues](https://github.com/ctrl-alt-automate/PowerNetbox/issues)

Include:
1. PowerShell version (`$PSVersionTable`)
2. Module version (`Get-Module PowerNetbox`)
3. Netbox version
4. Error message (use `-Verbose`)
5. Steps to reproduce
