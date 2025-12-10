# Test Endpoint Against Netbox 4.4.7

You are testing existing NetboxPS functions against the live Netbox 4.4.7 API to verify compatibility.

## Test Environment

```bash
TOKEN="a9717b9520d54d19383649066ef3b25e313bf219"
HOST="zwqg2756.cloud.netboxapp.com"
```

## Testing Workflow

### Step 1: Connect to Netbox
```powershell
./deploy.ps1 -Environment dev -SkipVersion
. ./Connect-DevNetbox.ps1
```

### Step 2: Test the Function
```powershell
# Test GET function
Get-Netbox[Module][Resource] -Verbose

# Test with filters
Get-Netbox[Module][Resource] -Name "test" -Verbose

# Test with ID
Get-Netbox[Module][Resource] -Id 1 -Verbose

# Test raw output
Get-Netbox[Module][Resource] -Raw
```

### Step 3: Compare with Direct API Call
```bash
# Direct API call for comparison
curl -s -H "Authorization: Token $TOKEN" "https://$HOST/api/[module]/[resource]/" | python3 -m json.tool
```

### Step 4: Document Results

Report findings in this format:

#### Function: `Get-Netbox[Module][Resource]`
- **Status**: ✅ Working / ⚠️ Partial / ❌ Broken
- **Netbox Version Tested**: 4.4.7
- **Issues Found**:
  - Issue 1: description
  - Issue 2: description
- **Breaking Changes**:
  - Change 1: old behavior → new behavior
- **Recommendations**:
  - Fix 1: description

## Common Issues to Check

1. **Field name changes** - API fields may have been renamed
2. **Removed fields** - Deprecated fields from older versions
3. **New required fields** - Fields that are now mandatory
4. **Changed data types** - e.g., string → object
5. **Nested object changes** - Related object structure changes
6. **Pagination changes** - Check `count`, `next`, `previous`, `results`

## Current Task

$ARGUMENTS
