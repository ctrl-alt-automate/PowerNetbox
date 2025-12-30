## Description

<!-- Briefly describe the changes in this PR -->

## Type of Change

<!-- Mark the relevant option with an "x" -->

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Documentation update
- [ ] Code refactoring (no functional changes)
- [ ] CI/CD or build changes

## Related Issues

<!-- Link to related issues using "Fixes #123" or "Relates to #123" -->

Fixes #

## Checklist

<!-- Ensure all items are checked before requesting review -->

### Code Quality
- [ ] Code follows the [PowerShell Practice and Style Guidelines](https://poshcode.gitbook.io/powershell-practice-and-style/)
- [ ] Functions use `[CmdletBinding()]` attribute
- [ ] State-changing functions use `SupportsShouldProcess`
- [ ] No hardcoded paths or credentials
- [ ] `Write-Verbose` used for debugging (not `Write-Host`)

### Testing
- [ ] Existing tests pass (`Invoke-Pester ./Tests/`)
- [ ] New tests added for new functionality
- [ ] Tested manually against Netbox instance (if applicable)

### Documentation
- [ ] Function has proper comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`)
- [ ] README updated (if needed)
- [ ] Wiki updated (if needed)

## Testing Performed

<!-- Describe how you tested these changes -->

- Netbox version tested:
- PowerShell version:
- Platform (Windows/Linux/macOS):

## Screenshots (if applicable)

<!-- Add screenshots for UI-related changes -->

## Additional Notes

<!-- Any additional context or notes for reviewers -->
