# Performance Monitoring and Tracking

This document tracks the implementation of Task 4: Performance Monitoring and Research tracking routines.

## Task 4.1: Performance Tracking Routine ✅

### Implementation

**Monthly Performance Tracking Script**: `scripts/maintenance/track-performance.sh`

This script automatically collects:

- **Evaluation Time Measurements**: Flake check, NixOS/Darwin evaluation times
- **Store Size Growth**: Tracks store size and generation counts over time
- **Binary Cache Metrics**: Cache connectivity and server count
- **System Information**: OS, kernel, Nix version, Determinate Nix version

### Usage

```bash
# Run monthly performance tracking
./scripts/maintenance/track-performance.sh
```

### Scheduling

To run monthly, add to your system:

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

### Documentation Updates

Performance trends should be documented in `docs/PERFORMANCE_TUNING.md` under "Performance Improvement Tracking" section.

---

## Task 4.2: Monitor Determinate Nix Updates

### Resources to Monitor

1. **Determinate Systems Blog**: <https://determinate.systems/posts>
2. **Determinate Nix Changelog**: Check release notes for each version
3. **GitHub Releases**: <https://github.com/DeterminateSystems/nix-installer/releases>
4. **FlakeHub Updates**: Monitor `determinate` input in `flake.nix`

### Current Version Tracking

**Current Determinate Nix Version**: [TO BE FILLED]

```bash
nix --version | grep -i determinate
```

**Last Checked**: [TO BE FILLED]

### Testing Process

When new Determinate Nix releases are available:

1. **Review Release Notes**: Check for performance-related features
2. **Create Test Branch**: `git checkout -b test-determinate-<version>`
3. **Update Input**: Update `determinate` input in `flake.nix`
4. **Test Evaluation**: Run `./scripts/maintenance/track-performance.sh`
5. **Compare Metrics**: Compare before/after evaluation times
6. **Test Experimental Features**: If new experimental features are available:

   ```bash
   # Test with experimental feature
   nix flake check --experimental-features "new-feature"
   ```

7. **Document Results**: Update this file with findings
8. **Merge or Revert**: Based on performance and stability

### Experimental Features to Watch

- [ ] [Feature Name] - [Status: Research/Testing/Adopted]
  - **Description**: [What it does]
  - **Expected Impact**: [Performance benefit]
  - **Testing Status**: [Not started/In progress/Completed]
  - **Notes**: [Any findings]

### Update Log

| Date | Version | Changes | Performance Impact | Status |
|------|---------|---------|-------------------|--------|
| [Date] | [Version] | [Changes] | [Impact] | [Adopted/Rejected] |

---

## Task 4.3: Review Flake Input Freshness

### Implementation

**Flake Update Script**: `scripts/maintenance/update-flake.sh`

This script:

- Updates flake inputs (all or specific)
- Monitors for deprecated/archived repositories
- Checks for FlakeHub alternatives with better cache coverage
- Documents problematic inputs

### Usage

```bash
# Update all inputs
./scripts/maintenance/update-flake.sh

# Dry run (check what would change)
./scripts/maintenance/update-flake.sh --dry-run

# Update specific input
./scripts/maintenance/update-flake.sh --input nixpkgs
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
# Add to crontab: 0 0 * * 0 /path/to/scripts/maintenance/update-flake.sh --dry-run
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

---

## Task 4.4: Evaluate Alternative Optimization Approaches

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
- Documentation: [Check project docs]

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

**Resources**:

- [Search for hm-ricing-mode documentation]

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

---

## Task 4.5: Contribute Fixes Upstream

### Overlays Under Evaluation

#### pamixer.nix Overlay

**Location**: `overlays/pamixer.nix`

**Issue**: ICU 76.1+ requires C++17 for compilation, but pamixer doesn't set this flag by default.

**Upstream Contribution Potential**:

- **Status**: [TO BE EVALUATED]
- **Applicability**: Check if this affects other users
- **Upstream Issue**: [Search/check nixpkgs issues]
- **PR Status**: [Not started/In progress/Submitted/Merged]

**Evaluation Steps**:

1. [ ] Search nixpkgs issues for similar problems
2. [ ] Check if upstream pamixer has fixed this
3. [ ] Test if newer nixpkgs versions include the fix
4. [ ] Document the issue clearly for upstream
5. [ ] Create PR if generally applicable

**Documentation**: Issue is well-documented in the overlay file itself.

#### mpd-fix.nix Overlay

**Location**: `overlays/mpd-fix.nix`

**Issue**: MPD build fails with io_uring on kernel 6.14.11+, requiring io_uring to be disabled.

**Upstream Contribution Potential**:

- **Status**: [TO BE EVALUATED]
- **Applicability**: Check if this affects other users
- **Upstream Issue**: [Search/check nixpkgs/MPD issues]
- **PR Status**: [Not started/In progress/Submitted/Merged]

**Evaluation Steps**:

1. [ ] Search nixpkgs issues for MPD io_uring problems
2. [ ] Check MPD upstream for io_uring compatibility fixes
3. [ ] Test if newer kernel versions resolve the issue
4. [ ] Document the issue clearly for upstream
5. [ ] Create PR if generally applicable

**Documentation**: Issue is well-documented in the overlay file itself.

### Contribution Process

1. **Evaluate General Applicability**: Is this a common problem?
2. **Search Existing Issues**: Check nixpkgs and upstream repos
3. **Test Current State**: Verify issue still exists in latest nixpkgs
4. **Document Clearly**: Create clear issue report with reproduction steps
5. **Create PR**: If fix is straightforward and generally applicable
6. **Monitor Progress**: Track PR status and update this document

### Contribution Log

| Overlay | Issue | PR/Issue Link | Status | Date |
|---------|-------|---------------|--------|------|
| pamixer.nix | ICU 76.1+ C++17 requirement | [Link] | [Status] | [Date] |
| mpd-fix.nix | io_uring kernel 6.14.11+ issue | [Link] | [Status] | [Date] |

---

## Task 4.6: Review and Refine Feature Module Boundaries

### Review Schedule

**Initial Review**: After 3 months of using feature system
**Ongoing Reviews**: Quarterly

### Current Feature Modules

List all feature modules and their boundaries:

[To be filled after reviewing `modules/nixos/features/` and `modules/shared/features/`]

### Pain Points to Identify

After living with the feature system, document:

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

### Refactoring Candidates

| Feature | Issue | Proposed Change | Priority |
|---------|-------|----------------|----------|
| [Feature] | [Issue] | [Change] | [High/Medium/Low] |

### Review Process

1. **Gather Usage Data**: Review which features are actually enabled
2. **Identify Patterns**: Find features that are always/never used together
3. **Document Pain Points**: List specific issues encountered
4. **Propose Changes**: Suggest splitting/merging/refactoring
5. **Test Changes**: Create branch and test refactored structure
6. **Implement**: Merge if tests pass and improvements are clear

### Review Log

| Review Date | Changes Made | Impact | Notes |
|-------------|--------------|--------|-------|
| [Date] | [Changes] | [Impact] | [Notes] |

---

## Monthly Review Checklist

Use this checklist each month:

- [ ] Run `track-performance.sh` to collect metrics
- [ ] Review performance trends in `.performance-metrics/`
- [ ] Check for new Determinate Nix releases
- [ ] Run `update-flake.sh` to update inputs
- [ ] Review any problematic inputs
- [ ] Check community discussions for new optimization approaches
- [ ] Review feature module usage and identify pain points
- [ ] Update this documentation with findings
- [ ] Update `PERFORMANCE_TUNING.md` with significant changes
