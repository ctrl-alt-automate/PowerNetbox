# Development Practices

This page documents the quality controls and development practices used in PowerNetbox.

## Overview

We use several GitHub features to maintain code quality and ensure consistent contributions:

| Feature | Purpose | Benefit |
|---------|---------|---------|
| Required Status Checks | Automated testing before merge | Prevents broken code |
| PR Templates | Standardized pull requests | Complete information |
| Issue Templates | Structured bug/feature reports | Faster resolution |
| CODEOWNERS | Automatic reviewer assignment | Expert review |
| Branch Protection | Prevents direct pushes | Enforces process |
| Milestones | Release tracking | Clear roadmap |

## Branch Protection

Both `dev` and `main` branches are protected:

### Required Checks

| Check | Description |
|-------|-------------|
| PSScriptAnalyzer | PowerShell linting |
| Pester Tests (Ubuntu) | Unit tests on Linux |
| Pester Tests (Windows) | Unit tests on Windows |

### Requirements

- ✅ All status checks must pass
- ✅ At least 1 code review approval
- ❌ Force push disabled
- ❌ Branch deletion disabled

## Why These Practices?

### 1. Required Status Checks

**Problem**: Broken code can be merged accidentally, causing issues for all users.

**Solution**: Automated tests run on every PR:
- **PSScriptAnalyzer**: Catches common mistakes, enforces style
- **Pester Tests**: Verifies code works correctly
- **Multi-Platform**: Tests on Windows, Linux, macOS

**Result**: Only working, tested code reaches users.

### 2. PR Templates

**Problem**: PRs often lack context, making review difficult.

**Solution**: Structured template with:
- Description of changes
- Type of change (bug fix, feature, etc.)
- Checklist of requirements
- Testing information

**Result**: Reviewers have all information needed for effective review.

### 3. Issue Templates

**Problem**: Bug reports often missing crucial details (version, OS, steps to reproduce).

**Solution**: Templates that prompt for:
- Environment details (PowerShell version, Netbox version, OS)
- Steps to reproduce
- Expected vs actual behavior

**Result**: Faster issue resolution with complete information.

### 4. CODEOWNERS

**Problem**: Not knowing who should review what.

**Solution**: Automatic reviewer assignment:
- Module owners review their modules
- Critical files (manifest, deploy script) get extra attention

**Result**: Right expertise applied to each review.

### 5. Branch Protection

**Problem**: Accidental pushes to main branches can break releases.

**Solution**: Protected branches require:
- PR-based workflow
- Passing checks
- Code review approval

**Result**: Stable main branches, reliable releases.

### 6. Milestones

**Problem**: Hard to track what's included in each release.

**Solution**: Milestones group related issues:
- `v4.5.0 Compatibility` - Netbox 4.5 work
- Future version milestones as needed

**Result**: Clear roadmap, organized releases.

## Contributing

See [CONTRIBUTING.md](https://github.com/ctrl-alt-automate/PowerNetbox/blob/dev/CONTRIBUTING.md) for detailed contribution guidelines.

## Related Pages

- [Getting Started](Getting-Started.md)
- [Function Naming](Function-Naming.md)
- [Troubleshooting](Troubleshooting.md)
- [Compatibility](Compatibility.md)
