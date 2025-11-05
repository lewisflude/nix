# Upstream Contribution Evaluation

This document tracks evaluation and potential upstream contributions for overlays and fixes in this configuration.

## Purpose

Reducing maintenance burden by contributing fixes upstream to nixpkgs or other repositories when they are generally applicable.

## Overlays Under Evaluation

### 1. pamixer.nix

**Location**: `overlays/pamixer.nix`

**Issue Description**:
ICU 76.1+ requires C++17 for compilation (std::u16string_view and other features). The pamixer package doesn't set the C++17 flag by default, causing build failures.

**Current Fix**:
Adds `-std=c++17` to `NIX_CFLAGS_COMPILE` in the overlay.

**Upstream Applicability**:

- **Status**: ⏳ To Be Evaluated
- **Impact**: Affects anyone using pamixer with ICU 76.1+
- **Likelihood**: High - this is a compatibility issue that affects many users

**Evaluation Steps**:

- [ ] Search nixpkgs issues for "pamixer ICU" or "pamixer C++17"
- [ ] Check if newer nixpkgs versions include the fix
- [ ] Test building pamixer from current nixpkgs without overlay
- [ ] Check pamixer upstream for C++17 support status
- [ ] Document issue clearly with reproduction steps

**Potential PR Approach**:
If generally applicable, create PR to nixpkgs that adds C++17 flag to pamixer derivation.

**Related Issues**:

- [nixpkgs issue #XXXXX](https://github.com/NixOS/nixpkgs/issues/XXXXX) - [Status]
- [pamixer issue #XXXXX](https://github.com/pulsemixer/pamixer/issues/XXXXX) - [Status]

**Notes**:

```
[Add notes from evaluation]
```

---

### 2. mpd-fix.nix

**Location**: `overlays/mpd-fix.nix`

**Issue Description**:
MPD build fails with io_uring on kernel 6.14.11+. The io_uring feature needs to be disabled to allow MPD to build successfully.

**Current Fix**:
Adds `-Dio_uring=disabled` to mesonFlags in the overlay.

**Upstream Applicability**:

- **Status**: ⏳ To Be Evaluated
- **Impact**: Affects anyone building MPD on kernel 6.14.11+
- **Likelihood**: Medium - may be kernel-specific or already fixed upstream

**Evaluation Steps**:

- [ ] Search nixpkgs issues for "MPD io_uring" or "MPD kernel 6.14"
- [ ] Check MPD upstream for io_uring compatibility fixes
- [ ] Test building MPD from current nixpkgs without overlay
- [ ] Check if newer kernel versions (or MPD versions) resolve the issue
- [ ] Document issue clearly with reproduction steps

**Potential PR Approach**:
If generally applicable, create PR to nixpkgs that disables io_uring for MPD (or makes it conditional on kernel version).

**Related Issues**:

- [nixpkgs issue #XXXXX](https://github.com/NixOS/nixpkgs/issues/XXXXX) - [Status]
- [MPD issue #XXXXX](https://github.com/MusicPlayerDaemon/MPD/issues/XXXXX) - [Status]

**Notes**:

```
[Add notes from evaluation]
```

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
| pamixer.nix | ICU 76.1+ C++17 | [Link] | [Status] | [Date] | [Notes] |
| mpd-fix.nix | io_uring kernel 6.14.11+ | [Link] | [Status] | [Date] | [Notes] |

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
