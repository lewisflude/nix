# Performance Monitoring Guide

This guide covers the performance monitoring and tracking system for maintaining optimal Nix configuration performance.

## Quick Start

### Run Monthly Performance Tracking

```bash
./scripts/maintenance/track-performance.sh
```

### Update Flake Inputs (Weekly)

```bash
nix run .#update-all --dry-run  # Check first
nix run .#update-all              # Then update
```

## Overview

The performance monitoring system tracks:

- **Evaluation times** (flake check, NixOS/Darwin)
- **Store size and growth** over time
- **Generation counts** accumulation
- **Binary cache connectivity** and server count
- **System information** (OS, kernel, Nix version)

## Performance Tracking Routine

### Monthly Tracking Script

**Script**: `scripts/maintenance/track-performance.sh`

**Metrics Collected**:

- Evaluation time measurements (flake check, NixOS/Darwin evaluation times)
- Store size growth (tracks store size and generation counts over time)
- Binary cache metrics (cache connectivity and server count)
- System information (OS, kernel, Nix version, Determinate Nix version)

### Usage

```bash
# Run monthly performance tracking
./scripts/maintenance/track-performance.sh
```

### Scheduling

**systemd timer** (NixOS):

```nix
systemd.timers.monthly-performance = {
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnCalendar = "monthly";
    Persistent = true;
  };
};
```

**cron** (macOS/Darwin):

```bash
# Add to crontab: 0 0 1 * * /path/to/scripts/maintenance/track-performance.sh
```

### Metrics Storage

Metrics are stored in `.performance-metrics/YYYY-MM.json` with:

- Timestamp and date
- System information
- Evaluation times (ms)
- Store size (bytes and human-readable)
- Generation counts
- Cache status
- Git commit/branch information

### Trend Analysis

After multiple runs, the script provides trend analysis showing:

- Store size growth over time
- Evaluation time changes
- Generation accumulation

**Performance trends should be documented in `docs/PERFORMANCE_TUNING.md` under "Performance Improvement Tracking" section.**

## Monitor Determinate Nix Updates

### Resources to Monitor

1. **Determinate Systems Blog**: <https://determinate.systems/posts>
2. **Determinate Nix Changelog**: Check release notes for each version
3. **GitHub Releases**: <https://github.com/DeterminateSystems/nix-installer/releases>
4. **FlakeHub Updates**: Monitor `determinate` input in `flake.nix`

### Testing Process

When new Determinate Nix releases are available:

1. **Review Release Notes**: Check for performance-related features
2. **Create Test Branch**: `git checkout -b test-determinate-<version>`
3. **Update Input**: Update `determinate` input in `flake.nix`
4. **Test Evaluation**: Run `./scripts/maintenance/track-performance.sh`
5. **Compare Metrics**: Compare before/after evaluation times
6. **Test Experimental Features**: If new experimental features are available:

   ```bash
   nix flake check --experimental-features "new-feature"
   ```

7. **Document Results**: Update this file with findings
8. **Merge or Revert**: Based on performance and stability

### Update Log

| Date | Version | Changes | Performance Impact | Status |
|------|---------|---------|-------------------|--------|
| [Date] | [Version] | [Changes] | [Impact] | [Adopted/Rejected] |

## Review Flake Input Freshness

### Update All Script

**Command**: `nix run .#update-all`

This interactive POG script updates:

- Flake inputs (flake.lock)
- ZSH plugins (nvfetcher)
- Custom packages
- Provides progress feedback and validation

### Usage

```bash
# Update everything
nix run .#update-all

# Dry run (check what would change)
nix run .#update-all --dry-run

# Skip specific updates
nix run .#update-all --skip-flake      # Skip flake.lock
nix run .#update-all --skip-plugins    # Skip ZSH plugins
nix run .#update-all --skip-packages   # Skip custom packages
```

### Scheduling

Run weekly to catch updates and issues early:

**systemd timer** (NixOS):

```nix
systemd.timers.weekly-flake-update = {
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnCalendar = "weekly";
    Persistent = true;
  };
};
```

**cron** (macOS/Darwin):

```bash
# Add to crontab: 0 0 * * 0 cd ~/.config/nix && nix run .#update-all --dry-run
```

### Input Health Checks

The script checks:

- Repository accessibility (404 detection)
- Archive status (if `gh` CLI available)
- FlakeHub alternative availability

### Problematic Inputs Log

Document any inputs that need attention:

| Input Name | Issue | Alternative | Status |
|------------|-------|-------------|--------|
| [Input] | [Issue description] | [Alternative or fix] | [Action needed] |

### FlakeHub Migration Strategy

When FlakeHub alternatives are available:

1. Check cache coverage: FlakeHub typically has better binary cache coverage
2. Test migration: Update to FlakeHub URL
3. Verify builds: Ensure all builds work
4. Monitor cache hit rates: Should improve with FlakeHub

## Evaluate Alternative Optimization Approaches

### Research Items

#### nix-fast-build

**Status**: Research Needed
**Purpose**: Parallel evaluation of all systems in flake's `.#checks` attribute
**Expected Benefit**: Faster pre-deployment validation

**Research Tasks**:

- [ ] Check availability and installation method
- [ ] Evaluate integration with current flake structure
- [ ] Test with current checks configuration
- [ ] Measure performance improvement
- [ ] Document usage patterns if adopted

**Resources**:

- GitHub: [nix-fast-build](https://github.com/nix-fast-build/nix-fast-build)

**Testing Branch**: `research/nix-fast-build`

#### hm-ricing-mode

**Status**: Research Needed
**Purpose**: Bypass declarative evaluation for rapid dotfile iteration
**Expected Benefit**: Instant feedback for cosmetic/config changes

**Research Tasks**:

- [ ] Research availability and installation
- [ ] Evaluate workflow integration
- [ ] Test with current Home Manager config
- [ ] Measure iteration speed improvement
- [ ] Document workflow if adopted

**Testing Branch**: `research/hm-ricing-mode`

### Community Discussions to Monitor

- NixOS Discourse: <https://discourse.nixos.org/>
- r/NixOS: <https://www.reddit.com/r/NixOS/>
- NixOS Matrix Chat: #nixos:matrix.org

**Key Topics to Watch**:

- Evaluation performance improvements
- New optimization techniques
- Cache optimization strategies
- Build performance enhancements

### Testing Process for New Approaches

1. **Create Research Branch**: `git checkout -b research/<tool-name>`
2. **Document Current Baseline**: Run `track-performance.sh` before changes
3. **Implement/Test**: Integrate and test the approach
4. **Measure Impact**: Run `track-performance.sh` after changes
5. **Document Findings**: Update this file with results
6. **Decision**: Adopt, reject, or defer based on results

### Research Log

| Tool/Approach | Date Researched | Status | Performance Impact | Decision |
|---------------|----------------|--------|-------------------|----------|
| nix-fast-build | [Date] | [Status] | [Impact] | [Adopt/Reject/Defer] |
| hm-ricing-mode | [Date] | [Status] | [Impact] | [Adopt/Reject/Defer] |

## Contribute Fixes Upstream

### Overlays Under Evaluation

### Overlay Optimization Status

**Status**: ? **Optimized** - All cache-impacting overlays have been removed

Previous overlays that caused cache misses have been removed:

- `pamixer.nix` - Removed, using upstream nixpkgs version
- `mpd-fix.nix` - Removed, using upstream nixpkgs version
- `nodejs-alias.nix` - Removed, using default nodejs
- `webkitgtk-compat.nix` - Removed, packages now use versioned webkitgtk

Remaining overlays are low-impact (aliases and new packages only):

- `npm-packages.nix` - Adds new packages (nx-latest)
- `localPkgs` - Custom packages not yet in nixpkgs (cursor)

Note: Chaotic Nyx bleeding-edge packages are now accessed via official `chaotic.nixosModules.default` and `chaotic.homeManagerModules.default` instead of custom overlays. See `docs/CHAOTIC_SETUP.md` for details.

### Future Overlay Additions

If new overlays are needed:

1. **Evaluate General Applicability**: Is this a common problem?
2. **Search Existing Issues**: Check nixpkgs and upstream repos
3. **Test Current State**: Verify issue still exists in latest nixpkgs
4. **Document Clearly**: Create clear issue report with reproduction steps
5. **Consider Alternatives**: Can we wait for upstream fix instead?
6. **Create PR**: If fix is straightforward and generally applicable
7. **Monitor Progress**: Track PR status and update documentation

### Contribution Log

| Overlay | Issue | PR/Issue Link | Status | Date |
|---------|-------|---------------|--------|------|
| (None currently requiring upstream contribution) | - | - | - | - |

## Review Feature Module Boundaries

### Review Schedule

**Initial Review**: After 3 months of using feature system
**Ongoing Reviews**: Quarterly

**Related Documentation**: See [`FEATURES.md`](../FEATURES.md) for feature system documentation.

### Pain Points to Identify

1. **Granularity Issues**:
   - Features too granular (too many small features)
   - Features too coarse (too much in one feature)

2. **Dependency Issues**:
   - Circular dependencies
   - Unclear dependencies
   - Missing dependencies

3. **Usage Patterns**:
   - Features always enabled together
   - Features rarely used
   - Features that should be split/merged

4. **Configuration Complexity**:
   - Features with too many options
   - Features that should be simpler
   - Missing configuration options

### Review Process

1. **Gather Usage Data**: Review which features are actually enabled
2. **Identify Patterns**: Find features that are always/never used together
3. **Document Pain Points**: List specific issues encountered
4. **Propose Changes**: Suggest splitting/merging/refactoring
5. **Test Changes**: Create branch and test refactored structure
6. **Implement**: Merge if tests pass and improvements are clear

## Monthly Review Checklist

Use this checklist each month:

- [ ] Run `track-performance.sh` to collect metrics
- [ ] Review performance trends in `.performance-metrics/`
- [ ] Check for new Determinate Nix releases
- [ ] Run `nix run .#update-all` to update inputs
- [ ] Review any problematic inputs
- [ ] Check community discussions for new optimization approaches
- [ ] Review feature module usage and identify pain points
- [ ] Update this documentation with findings
- [ ] Update `PERFORMANCE_TUNING.md` with significant changes

## Key Metrics to Watch

- **Evaluation Time**: Target < 10 seconds
- **Store Size Growth**: Monitor monthly trends
- **Cache Hit Rate**: Target > 95% (requires build-time monitoring)
- **Input Health**: Check for deprecated/archived repos
- **Feature Usage**: Track which features are actually used

## Related Documentation

- **Performance Optimizations**: [`PERFORMANCE_TUNING.md`](../PERFORMANCE_TUNING.md) - Current optimizations and baseline
- **Build Profiling**: [`BUILD_PROFILING.md`](../BUILD_PROFILING.md) - Tools for profiling builds
- **Feature System**: [`FEATURES.md`](../FEATURES.md) - Feature system documentation
- **Scripts**: [`scripts/maintenance/README.md`](../../scripts/maintenance/README.md) - Script documentation
