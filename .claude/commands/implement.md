# Implement Netbox Endpoint

You are implementing a new endpoint for the NetboxPS PowerShell module. Combine expertise from both:
1. **Netbox API** - to understand the endpoint schema and behavior
2. **PowerShell Best Practices** - to write clean, modern code

## Implementation Workflow

### Step 1: Research the API Endpoint
Query the live Netbox API to understand the endpoint:
```bash
TOKEN="a9717b9520d54d19383649066ef3b25e313bf219"
HOST="zwqg2756.cloud.netboxapp.com"

# Get endpoint structure
curl -s -H "Authorization: Token $TOKEN" "https://$HOST/api/[module]/[endpoint]/" | python3 -m json.tool

# Get schema (if available)
curl -s -H "Authorization: Token $TOKEN" "https://$HOST/api/schema/?format=json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(json.dumps(d['paths'].get('/api/[module]/[endpoint]/', {}), indent=2))"
```

### Step 2: Create Functions
For each endpoint, typically create 4 functions:
1. `Get-Netbox[Module][Resource]` - GET (list/retrieve)
2. `New-Netbox[Module][Resource]` - POST (create)
3. `Set-Netbox[Module][Resource]` - PATCH (update)
4. `Remove-Netbox[Module][Resource]` - DELETE

### Step 3: File Structure
Create files in the appropriate directory:
```
Functions/[Module]/[Resource]/
├── Get-Netbox[Module][Resource].ps1
├── New-Netbox[Module][Resource].ps1
├── Set-Netbox[Module][Resource].ps1
└── Remove-Netbox[Module][Resource].ps1
```

### Step 4: Follow Existing Patterns
Use existing functions as templates. Key patterns:
- `BuildURIComponents` for parameter processing
- `BuildNewURI` for URI construction
- `InvokeNetboxRequest` for API calls
- Always include `-Raw` switch
- Use `SupportsShouldProcess` for mutations

### Step 5: Test the Implementation
```powershell
# Build and connect
./deploy.ps1 -Environment dev -SkipVersion
. ./Connect-DevNetbox.ps1

# Test the new functions
Get-Netbox[Module][Resource]
New-Netbox[Module][Resource] -Name "test" -WhatIf
```

### Step 6: Update Module Manifest
After adding functions, rebuild:
```powershell
./deploy.ps1 -Environment dev
```

## Quality Checklist
- [ ] All parameters have proper validation
- [ ] Pipeline support where appropriate
- [ ] SupportsShouldProcess for New/Set/Remove
- [ ] -Raw switch included
- [ ] Follows naming convention
- [ ] Comment-based help included
- [ ] Tested against live API

## Current Task

$ARGUMENTS
