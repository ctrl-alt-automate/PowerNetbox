# Netbox Version Compatibility

PowerNetbox is tested against multiple Netbox versions to ensure broad compatibility.

## Supported Versions

| Netbox Version | Status | Notes |
|----------------|--------|-------|
| 4.5.x | ✅ Full Support | Primary development target |
| 4.4.x | ✅ Full Support | All 94 integration tests pass |
| 4.3.x | ✅ Full Support | Minimum supported, all 94 tests pass |
| 4.2.x | ❌ Not Supported | Use PowerNetbox v4.4.10.0 or earlier |
| 4.1.x | ❌ Not Supported | Use PowerNetbox v4.4.10.0 or earlier |
| 4.0.x | ❌ Not Supported | Use PowerNetbox v4.4.10.0 or earlier |
| 3.x | ❌ Not Supported | Missing required API endpoints |

**Minimum supported version: Netbox 4.3+**

## Compatibility Testing

PowerNetbox uses automated compatibility testing via GitHub Actions. The workflow tests against multiple Netbox versions using Docker images from [netboxcommunity/netbox](https://hub.docker.com/r/netboxcommunity/netbox).

### Test Matrix

The compatibility workflow runs 94 integration tests against each version:

```
Netbox 4.5.2:  94/94 tests passed ✅ (Primary target)
Netbox 4.4.10: 94/94 tests passed ✅
Netbox 4.3.7:  94/94 tests passed ✅ (Minimum supported)
```

## API Endpoint Changes

PowerNetbox handles API changes between Netbox versions automatically:

### Netbox 4.5 Changes

| Change | Description | PowerNetbox Handling |
|--------|-------------|---------------------|
| Token v2 | New `nbt_<KEY>.<TOKEN>` format with Bearer auth | Auto-detected, uses correct auth header |
| is_staff removed | User model no longer has `is_staff` field | `Is_Staff` parameter ignored on 4.5+ |
| Cable Profiles | New `profile` field on cables | `Cable_Profile` parameter on cable functions |
| Object Ownership | New `/api/users/owners/` endpoint | `Get/New/Set/Remove-NBOwner` functions |
| Port Mappings | Bidirectional `front_ports`/`rear_ports` | Full support in port functions |
| Form_Factor removed | Interface `form_factor` replaced by `type` | `-Form_Factor` parameter removed, use `-Type` |
| `?omit=` parameter | Replaces `?exclude=` for field omission | `-Omit` parameter on all 123 Get functions |
| Image Attachments | Upload images to any object | `New-NBImageAttachment` function |

### Content Types / Object Types

| Netbox Version | Endpoint |
|----------------|----------|
| 4.4+ | `/api/core/object-types/` |
| 4.0-4.3 | `/api/extras/object-types/` |

The `Get-NBContentType` function automatically detects your Netbox version and uses the correct endpoint.

### Module Availability

| Module | Available Since |
|--------|-----------------|
| DCIM | All versions |
| IPAM | All versions |
| Virtualization | All versions |
| Circuits | All versions |
| Tenancy | All versions |
| Extras | All versions |
| Core | Netbox 3.5+ |
| VPN | Netbox 3.7+ |
| Wireless | Netbox 3.1+ |
| Users | Netbox 3.0+ |

## Running Compatibility Tests Locally

You can run the compatibility tests locally using Docker:

```bash
# Start Netbox with a specific version
export NETBOX_VERSION=v4.3.7-3.3.0
docker compose -f docker-compose.ci.yml up -d

# Wait for Netbox to be healthy
docker inspect --format='{{.State.Health.Status}}' powernetbox-netbox-1

# Run tests
$env:NETBOX_HOST = 'localhost:8000'
$env:NETBOX_TOKEN = '0123456789abcdef0123456789abcdef01234567'
Invoke-Pester ./Tests/Integration.Tests.ps1 -Tag 'Live'

# Cleanup
docker compose -f docker-compose.ci.yml down -v
```

### Available Docker Image Tags

| Netbox Version | Docker Tag | Notes |
|----------------|------------|-------|
| 4.5.2 | `v4.5.2-4.0.0` | netbox-docker 4.0.0 (Granian, PostgreSQL 18, Valkey 9) |
| 4.4.10 | `v4.4.10-3.4.2` | netbox-docker 3.4.2 |
| 4.3.7 | `v4.3.7-3.3.0` | netbox-docker 3.3.0 |

## Reporting Compatibility Issues

If you encounter compatibility issues with a specific Netbox version:

1. Check this page for known issues
2. Try updating to the latest PowerNetbox version
3. [Open an issue](https://github.com/ctrl-alt-automate/PowerNetbox/issues) with:
   - Your Netbox version (`Get-NBVersion`)
   - PowerNetbox version (`Get-Module PowerNetbox`)
   - The specific function and error message
