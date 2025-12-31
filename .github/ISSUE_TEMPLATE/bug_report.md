---
name: Bug Report
about: Report a bug or unexpected behavior
title: '[Bug] '
labels: bug
assignees: ''
---

## Bug Description

<!-- A clear and concise description of what the bug is -->

## Function/Cmdlet Affected

<!-- Which PowerNetbox function(s) are affected? e.g., Get-NBDCIMDevice, New-NBIPAMAddress -->

- Function:
- Module: <!-- DCIM, IPAM, VPN, etc. -->

## Steps to Reproduce

1. Connect to Netbox: `Connect-NBAPI -Hostname '...' -Credential $cred`
2. Run command: `...`
3. See error

## Expected Behavior

<!-- What did you expect to happen? -->

## Actual Behavior

<!-- What actually happened? Include error messages if any -->

```
Paste error message here
```

## Environment

- **PowerNetbox Version**: <!-- Run: (Get-Module PowerNetbox).Version -->
- **Netbox Version**: <!-- Run: (Get-NBVersion).'netbox-version' -->
- **PowerShell Version**: <!-- Run: $PSVersionTable.PSVersion -->
- **PowerShell Edition**: <!-- Desktop or Core -->
- **OS**: <!-- Windows 10, Ubuntu 22.04, macOS 14, etc. -->

## Additional Context

<!-- Add any other context about the problem here -->

## Possible Solution (optional)

<!-- If you have ideas on how to fix this -->
