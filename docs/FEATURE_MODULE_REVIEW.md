# Feature Module Boundary Review

This document tracks the review and refinement of feature module boundaries (Task 4.6).

## Purpose

After living with the feature system for several months, identify pain points and determine if feature granularity is appropriate or needs adjustment. Refactor feature modules based on actual usage patterns.

## Review Schedule

- **Initial Review**: After 3 months of using feature system
- **Ongoing Reviews**: Quarterly (every 3 months)
- **Next Review Date**: [TO BE FILLED]

## Current Feature Modules

### NixOS Features (`modules/nixos/features/`)

| Feature | Purpose | Dependencies | Usage Frequency |
|---------|---------|--------------|-----------------|
| `ai-tools.nix` | AI/ML tooling | [TBD] | [Track] |
| `audio.nix` | Audio system configuration | [TBD] | [Track] |
| `containers.nix` | Container support | [TBD] | [Track] |
| `containers-supplemental.nix` | Additional container tools | [TBD] | [Track] |
| `gaming.nix` | Gaming-related packages | [TBD] | [Track] |
| `home-server.nix` | Home server services | [TBD] | [Track] |
| `media-management.nix` | Media management tools | [TBD] | [Track] |
| `restic.nix` | Restic backup system | [TBD] | [Track] |
| `security.nix` | Security enhancements | [TBD] | [Track] |
| `virtualisation.nix` | Virtualization support | [TBD] | [Track] |

#### Desktop Features (`modules/nixos/features/desktop/`)

| Feature | Purpose | Dependencies | Usage Frequency |
|---------|---------|--------------|-----------------|
| `default.nix` | Desktop feature aggregation | [TBD] | [Track] |
| `audio/` | Desktop audio configuration | [TBD] | [Track] |
| `desktop-environment.nix` | Desktop environment setup | [TBD] | [Track] |
| `graphics.nix` | Graphics drivers and tools | [TBD] | [Track] |
| `hyprland.nix` | Hyprland compositor | [TBD] | [Track] |
| `niri.nix` | Niri compositor | [TBD] | [Track] |
| `theme.nix` | Theming configuration | [TBD] | [Track] |
| `xwayland.nix` | XWayland support | [TBD] | [Track] |

### Shared Features (`modules/shared/features/`)

| Feature Category | Features | Purpose | Usage Frequency |
|-----------------|----------|---------|-----------------|
| `desktop/` | Desktop applications | [TBD] | [Track] |
| `development/` | Development tools | [TBD] | [Track] |
| `media/` | Media applications | [TBD] | [Track] |
| `productivity/` | Productivity tools | [TBD] | [Track] |
| `security/` | Security tools | [TBD] | [Track] |

## Pain Points to Identify

Document issues encountered after using the feature system:

### 1. Granularity Issues

**Too Granular** (too many small features):

- [ ] Feature X and Y are always enabled together
- [ ] Feature Z is too small to be its own feature
- [ ] Multiple features that should be merged

**Too Coarse** (too much in one feature):

- [ ] Feature X contains unrelated functionality
- [ ] Only using part of Feature Y, but can't disable the rest
- [ ] Feature should be split into multiple features

### 2. Dependency Issues

- [ ] Circular dependencies between features
- [ ] Unclear dependencies (implicit but not documented)
- [ ] Missing dependencies (features fail without other features)
- [ ] Overly tight coupling between features

### 3. Usage Patterns

**Always Together**:

- Features that are always enabled together (candidates for merging)
- [ ] Feature A + Feature B (always together)

**Rarely Used**:

- Features that are rarely or never enabled
- [ ] Feature C (rarely used - consider removing?)

**Should Be Split**:

- Features that are sometimes used together, sometimes separately
- [ ] Feature D (should be split into D1 and D2)

### 4. Configuration Complexity

- [ ] Features with too many options (should be simplified)
- [ ] Features that should be simpler (fewer options)
- [ ] Missing configuration options (need more flexibility)

## Refactoring Candidates

| Feature(s) | Issue | Proposed Change | Priority | Status |
|------------|-------|----------------|----------|--------|
| [Feature] | [Issue description] | [Proposed solution] | [High/Medium/Low] | [Not started/In progress/Completed] |

## Review Process

### Step 1: Gather Usage Data

Review which features are actually enabled across hosts:

```bash
# List enabled features per host
grep -r "features\." hosts/*/configuration.nix

# Check feature usage patterns
grep -r "enable.*feature" hosts/
```

**Current Usage** (to be filled):

```
Host: jupiter
Enabled Features: [list]

Host: Lewiss-MacBook-Pro
Enabled Features: [list]
```

### Step 2: Identify Patterns

Analyze usage data to find:

- Features always enabled together
- Features rarely used
- Features that should be split/merged

**Patterns Found**:

### Step 3: Document Pain Points

List specific issues encountered:

### Step 4: Propose Changes

For each pain point, propose a solution:

- **Issue**: [Description]
- **Proposal**: [Solution]
- **Impact**: [What changes]

### Step 5: Test Changes

Create branch and test refactored structure:

```bash
git checkout -b refactor/feature-modules
# Make changes
# Test builds
nix flake check
nh os build --dry
```

### Step 6: Implement

Merge if tests pass and improvements are clear.

## Review Log

| Review Date | Changes Made | Impact | Notes |
|-------------|--------------|--------|-------|
| [Date] | [Changes] | [Impact] | [Notes] |

## Example Refactoring Scenarios

### Scenario 1: Merge Features

**Issue**: `containers.nix` and `containers-supplemental.nix` are always enabled together.

**Solution**: Merge into single `containers.nix` feature with options to enable/disable supplemental tools.

**Status**: [Not started/In progress/Completed]

### Scenario 2: Split Feature

**Issue**: `desktop-environment.nix` contains both basic desktop setup and advanced configuration that's rarely used.

**Solution**: Split into `desktop-environment.nix` (basic) and `desktop-advanced.nix` (optional advanced features).

**Status**: [Not started/In progress/Completed]

### Scenario 3: Adjust Granularity

**Issue**: `audio.nix` is too coarse - includes both system audio and desktop audio configuration.

**Solution**: Keep `audio.nix` for system-level, move desktop audio to `desktop/audio/` (already exists).

**Status**: [Not started/In progress/Completed]

## Metrics to Track

After refactoring, track:

- Build time changes
- Evaluation time changes
- Configuration complexity (lines of config)
- Number of features
- Feature interdependencies

## Next Steps

1. [ ] Complete initial 3-month review
2. [ ] Document current feature usage
3. [ ] Identify pain points
4. [ ] Propose refactoring changes
5. [ ] Test changes in branch
6. [ ] Implement approved changes
7. [ ] Schedule next review
