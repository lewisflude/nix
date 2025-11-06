# Upstream Contribution Evaluation

This document tracks evaluation and potential upstream contributions for overlays and fixes in this configuration.

## Purpose

Reducing maintenance burden by contributing fixes upstream to nixpkgs or other repositories when they are generally applicable.

## Current Status

**✅ Optimized**: This configuration has been optimized to minimize cache-impacting overlays.

All previously problematic overlays have been removed in favor of using upstream nixpkgs versions:

- `pamixer.nix` - Removed, using upstream nixpkgs version
- `mpd-fix.nix` - Removed, using upstream nixpkgs version
- `nodejs-alias.nix` - Removed, using default nodejs
- `webkitgtk-compat.nix` - Removed, packages now use versioned webkitgtk

Current overlays are low-impact (aliases and new packages only):

- `npm-packages.nix` - Adds new packages (nx-latest)
- `chaotic-packages.nix` - Pure aliases to existing bleeding-edge packages
- `localPkgs` - Custom packages not yet in nixpkgs (cursor, ghostty)

## Overlays Under Evaluation

**None currently** - All overlays are either:

1. Custom packages not in nixpkgs (cursor, ghostty)
2. Pure aliases with no build modifications (chaotic-packages)
3. New package additions (npm-packages)

---

## Contribution Process

### Step 1: Evaluate General Applicability

Before contributing, determine if the fix is:

- ✅ **Generally applicable**: Affects many users, not just this configuration
- ❌ **Config-specific**: Only needed for this specific setup
- ⚠️ **Temporary**: Issue may be resolved in future versions

### Step 2: Search Existing Issues

Check for existing issues or PRs:

- nixpkgs GitHub issues
- Upstream project issues
- NixOS Discourse discussions
- Related PRs

### Step 3: Test Current State

Verify the issue still exists:

```bash
# Test without overlay
nix build -f '<nixpkgs>' pamixer
nix build -f '<nixpkgs>' mpd
```

### Step 4: Document Clearly

Create clear documentation:

- Reproduction steps
- Error messages
- System information
- Proposed fix

### Step 5: Create PR

If applicable:

1. Fork nixpkgs
2. Create branch with fix
3. Test thoroughly
4. Submit PR with clear description
5. Link to related issues

### Step 6: Monitor Progress

- Track PR status
- Respond to reviews
- Update this document
- Remove overlay once merged (after sufficient testing)

## Contribution Log

| Overlay | Issue | PR/Issue | Status | Date | Notes |
|---------|-------|----------|--------|------|-------|
| (None currently) | - | - | - | - | All cache-impacting overlays removed |

## Status Legend

- ⏳ To Be Evaluated
- 🔍 Evaluating
- 📝 Issue Created
- 🔨 PR Created
- 👀 Under Review
- ✅ Merged
- ❌ Rejected/Not Applicable
- 🔄 Deferred

## Benefits of Upstream Contribution

1. **Reduced Maintenance**: Fix maintained upstream
2. **Community Benefit**: Others benefit from the fix
3. **Better Testing**: Upstream testing ensures stability
4. **Cache Coverage**: Upstream fixes get better binary cache coverage
5. **Knowledge Sharing**: Contributes to community knowledge

## Resources

- [nixpkgs Contributing Guide](https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md)
- [nixpkgs Manual](https://nixos.org/manual/nixpkgs/)
- [NixOS Discourse](https://discourse.nixos.org/)
- [nixpkgs Review Process](https://github.com/NixOS/nixpkgs/blob/master/.github/PULL_REQUEST_TEMPLATE.md)
