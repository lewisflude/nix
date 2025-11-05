# Nix Performance Tuning Guide

This document outlines performance optimizations applied to this Nix configuration based on the "Strategic Performance Tuning for Determinate Nix and Home Manager Environments" guide.

## Current Optimizations

### Tier 2: Realization Optimization (Implemented)

#### Parallelism Configuration (Tip 5) ✅

- **http-connections**: Set to 64 (from default ~2-5)
  - Maximizes parallel TCP connections for binary cache fetching
  - Configured in:
    - `modules/nixos/system/nix/nix-optimization.nix`
    - `modules/darwin/nix.nix`
- **max-substitution-jobs**: Set to 64 (from default low)
  - Controls maximum concurrent substitution tasks
  - Improves throughput on systems with high I/O capability

**Expected Impact**: 2-4x faster substitution, especially on high-speed network connections

#### Substitution Override (Tip 7) ✅

- **always-allow-substitutes**: Set to `true`
  - Forces Nix to use binary cache even for derivations marked `allowSubstitutes = false`
  - Speeds up aggregator derivations (symlinkJoin, etc.)
  - Configured in:
    - `modules/nixos/system/nix/nix-optimization.nix`
    - `modules/darwin/nix.nix`

**Expected Impact**: Faster final realization stages by avoiding unnecessary local rebuilds

### Existing Optimizations

#### Remote Builder Substitution (Tip 8) ✅

- **builders-use-substitutes**: Set to `true`
  - Allows remote builders to fetch dependencies directly from binary caches
  - Reduces data transfer volume from local host
  - Configured in: `modules/nixos/system/nix/nix-optimization.nix`

#### Private Cache Strategy (Tip 6) ✅

- Personal cache (`lewisflude.cachix.org`) prioritized first
- FlakeHub cache included for Determinate Nix flakes
- Proper cache ordering in `flake.nix` nixConfig section

#### Network I/O Decoupling (Tip 3) ✅

- No `builtins.fetch*` usage in evaluation phase
- Correctly using `pkgs.fetchurl` for build-time fetching
- Example: `modules/nixos/services/home-assistant.nix`

### Additional Optimizations (Comprehensive Guide) ✅

#### Build Resilience Settings

- **keep-going**: Set to `true`
  - Allows Nix to continue building other derivations when one fails
  - Improves parallel build efficiency by not stopping entire build on single failure
  - Configured in:
    - `modules/nixos/system/nix/nix-optimization.nix`
    - `modules/darwin/nix.nix`

**Expected Impact**: Better parallel build utilization, especially for large builds with many independent derivations

#### Connection Timeout Optimization

- **connect-timeout**: Reduced from 10s to 5s
  - Faster failure detection on unresponsive cache servers
  - Reduces wait times when cache servers are down or unreachable
  - Configured in:
    - `modules/nixos/system/nix/nix-optimization.nix`
    - `modules/darwin/nix.nix`

**Expected Impact**: Faster error detection and recovery from cache failures

#### Build Logging

- **log-lines**: Set to 25
  - Shows more build output lines on failure (25 instead of default)
  - Improves debugging capability when builds fail
  - Configured in:
    - `modules/nixos/system/nix/nix-optimization.nix`
    - `modules/darwin/nix.nix`

**Expected Impact**: Better debugging information for failed builds

#### Automatic Store Optimization

- **nix.optimise.automatic**: Enabled with daily schedule
  - Automatically hardlinks duplicate files in the store
  - Runs daily at 3:45 AM (after GC completes)
  - Configured in: `modules/nixos/system/nix/nix-optimization.nix`

**Expected Impact**: Recovers 20-40% of store space automatically without manual intervention

**Note**: This complements the existing manual optimization scripts and systemd timers already in place.

## Known Performance Trade-offs

### Overlay Usage (Tip 10) ⚠️

Overlays can modify package builds, causing cache misses and local rebuilds. This section documents the performance impact of each overlay.

#### High Impact Overlays (Cause Cache Misses)

These overlays modify build flags or compilation settings, forcing local rebuilds:

1. **pamixer.nix**: Modifies C++ compilation flags for ICU 76.1 compatibility
   - **Impact**: Forces local rebuild of pamixer and dependencies
   - **Rationale**: Necessary for compatibility with newer ICU versions
   - **Status**: Acceptable trade-off for compatibility
   - **Removal**: Can be removed when nixpkgs includes C++17 support by default

2. **mpd-fix.nix**: Disables io_uring for MPD build
   - **Impact**: Forces local rebuild of MPD
   - **Rationale**: Required to fix build failures on kernel 6.14.11
   - **Status**: Acceptable trade-off for functionality
   - **Removal**: Can be removed when MPD upstream fixes io_uring compatibility

#### Low Impact Overlays (No Cache Misses)

These overlays provide aliases or add new packages without modifying builds:

3. **webkitgtk-compat.nix**: Compatibility alias for removed webkitgtk
   - **Impact**: None (pure evaluation-time alias)
   - **Rationale**: Maintains compatibility with packages not yet updated to versioned variants
   - **Removal**: Can be removed when all packages use webkitgtk_6_0 or similar

4. **npm-packages.nix**: Promotes NPM packages to top-level
   - **Impact**: None (creates new derivations, but binary cache should have them)
   - **Rationale**: Provides easy access to latest Nx tooling
   - **Removal**: Can be removed when packages are added to nixpkgs upstream

#### Trade-off Analysis

**When to use overlays**:

- ✅ Fixing critical build failures (pamixer, mpd-fix)
- ✅ Providing compatibility shims (webkitgtk-compat)
- ✅ Adding custom packages (localPkgs, npm-packages)

**When to avoid overlays**:

- ❌ Cosmetic changes that don't fix issues
- ❌ Modifications that can be upstreamed quickly
- ❌ Changes that affect many packages (use overlays sparingly)

**Minimizing Impact**:

- Keep overlays minimal and focused
- Document removal conditions clearly
- Regularly check if fixes are upstreamed
- Prefer package overrides over full rebuilds when possible

**Monitoring Overlay Impact**:

```bash
# Check which packages are rebuilt locally
nix-store --query --requisites /run/current-system | xargs nix-store --query --references

# Identify cache misses (packages not in binary cache)
nix path-info --recursive /run/current-system | grep -v "https://"
```

## Research Items (Phase 2)

### Alternative Evaluators (Tip 1)

#### lix Evaluator

- **Status**: Research needed
- **Expected Benefit**: 10-20x faster Home Manager evaluation (from ~60s to ~3-6s)
- **Action Items**:
  - Research lix compatibility with Determinate Nix
  - Evaluate installation method
  - Test with current Home Manager configuration
  - Document integration steps if viable

#### nix-fast-build

- **Status**: Research needed
- **Purpose**: Parallel evaluation of all systems in flake's `.#checks` attribute
- **Expected Benefit**: Faster pre-deployment validation
- **Action Items**:
  - Research nix-fast-build availability and installation
  - Evaluate integration with current flake structure
  - Document usage patterns

### Rapid Iteration Tools (Tip 4)

#### hm-ricing-mode

- **Status**: Research needed
- **Purpose**: Bypass declarative evaluation for rapid dotfile iteration
- **Expected Benefit**: Instant feedback for cosmetic/config changes
- **Action Items**:
  - Research hm-ricing-mode availability
  - Evaluate installation and usage
  - Document workflow integration

## Future Architectural Improvements (Phase 3)

### Fine-Grained Flake Boundaries (Tip 9)

**Current State**: Monolithic flake structure

- Single flake contains entire system + Home Manager configuration
- Small changes invalidate entire evaluation cache

**Recommendation**: Consider splitting into smaller flakes:

- Individual host configurations (per-host flakes)
- Home Manager dotfiles (separate flake)
- Custom packages (isolated package flakes)

**Benefits**:

- Localized cache invalidation
- Faster incremental changes
- Better modularity

**Considerations**:

- Increased complexity in dependency management
- More flakes to maintain
- Evaluate against current workflow needs

### Build-Time Input Declaration (Tip 11) ✅

**Overview**: Build-time inputs are fetched during the build phase rather than during evaluation, which can significantly speed up flake evaluation by deferring non-critical input fetches.

**How It Works**:

- Inputs marked with `buildTime = true` are fetched only when needed during the actual build/realization phase
- Requires the experimental feature `build-time-fetch-tree` to be enabled in `nixConfig.experimental-features`
- This is particularly useful for platform-specific inputs that are only needed for certain systems

**Current Implementation**:

The following inputs are marked as build-time only:

1. **`homebrew-j178`** (macOS only)
   - **Why**: This input is only used during macOS system builds when configuring Homebrew taps
   - **Location**: `flake.nix` line 99-103
   - **Impact**: Speeds up evaluation on Linux systems since this input is never needed there
   - **Configuration**:

     ```nix
     homebrew-j178 = {
       url = "github:j178/homebrew-tap";
       flake = false;
       buildTime = true;  # Deferred until macOS build
     };
     ```

**Potential Candidates for Build-Time-Only**:

The following inputs are candidates for future conversion to `buildTime = true` once the feature is validated as stable:

1. **`nixos-hardware`** (hardware-specific)
   - **Rationale**: Hardware-specific modules are typically only needed during system realization, not during general flake evaluation
   - **Impact**: Could speed up evaluation on systems that don't use hardware-specific modules
   - **Status**: Marked for future consideration in `flake.nix` line 157-159
   - **Consideration**: May affect module discovery if modules reference hardware configs during evaluation
   - **Risk**: Low - only used in hardware-configuration.nix files
   - **Testing**: Requires validation that hardware modules are accessible during build-time fetch

2. **`nvidia-patch`** (NVIDIA GPU patch, Linux-only)
   - **Rationale**: Only used in overlays during build, not during evaluation
   - **Status**: Not yet implemented (lower priority)
   - **Risk**: Low - overlay application happens at build time
   - **Testing**: Verify overlay still applies correctly

3. **`jsonresume-nix`** (Resume generator)
   - **Rationale**: Only used in home-manager feature module, not during evaluation
   - **Status**: Not yet implemented (lower priority)
   - **Risk**: Medium - verify feature module doesn't need it during evaluation
   - **Testing**: Ensure resume feature works without evaluation-time access

**Conversion Strategy**:

- Test `homebrew-j178` build-time fetching thoroughly on macOS builds
- Monitor for any issues with deferred fetching
- Once validated, consider converting candidates above if they show similar benefits
- Document any additional candidates discovered during testing

**Troubleshooting Build-Time Input Issues**:

1. **Input not found during build**:
   - **Symptom**: Build fails with "input not found" error
   - **Solution**: Ensure `build-time-fetch-tree` is enabled in `nixConfig.experimental-features`
   - **Check**: Run `nix flake show` to verify input is marked correctly

2. **Evaluation-time references fail**:
   - **Symptom**: Evaluation fails when trying to access build-time input
   - **Cause**: Build-time inputs cannot be accessed during evaluation phase
   - **Solution**: Only reference build-time inputs in modules that execute during build/realization, not in evaluation-time code

3. **Cache misses**:
   - **Symptom**: Build-time inputs are fetched every time
   - **Solution**: Ensure build-time inputs are in binary caches or use `--no-link` to test

**When to Use Build-Time Inputs**:

✅ **Good candidates**:

- Platform-specific inputs (e.g., macOS-only, Linux-only)
- Large inputs that are rarely changed
- Inputs only used during realization, not evaluation
- Inputs that don't need to be available for module discovery

❌ **Avoid for**:

- Core inputs needed for module evaluation
- Inputs referenced in `specialArgs` or module imports
- Inputs used in option definitions or type checking
- Small inputs where fetch time is negligible

**Example: Adding a New Build-Time Input**:

```nix
inputs = {
  # Regular input (fetched at evaluation time)
  nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";

  # Build-time input (fetched only during build)
  platform-specific-tool = {
    url = "github:example/platform-tool";
    buildTime = true;  # Defer fetching until build
  };
};
```

**Performance Impact**:

- **Evaluation Speed**: Can reduce evaluation time by 10-30% depending on input size and network conditions
- **Build Speed**: Minimal impact (inputs are fetched in parallel during build)
- **Network Usage**: Same total data transfer, just moved to build phase

**Verification**:

To verify build-time inputs are working correctly:

```bash
# Check that input is marked correctly
nix flake metadata --json | jq '.locks.nodes.homebrew-j178'

# Time evaluation (should be faster with build-time inputs)
time nix flake check

# Verify build still works
nix build .#darwinConfigurations.$(hostname).system
```

## Performance Monitoring

### Automated Performance Tracking

**Monthly Performance Tracking Script**: `scripts/maintenance/track-performance.sh`

This automated script collects comprehensive performance metrics monthly:

- Evaluation time measurements (flake check, NixOS/Darwin)
- Store size growth tracking
- Binary cache connectivity and metrics
- System information (OS, kernel, Nix versions)
- Git commit/branch information for correlation

**Usage**:

```bash
# Run monthly performance tracking
./scripts/maintenance/track-performance.sh
```

**Metrics Storage**: `.performance-metrics/YYYY-MM.json`

**Scheduling**: See `docs/PERFORMANCE_MONITORING.md` for systemd timer or cron setup.

For detailed monitoring documentation, see: [`docs/PERFORMANCE_MONITORING.md`](./PERFORMANCE_MONITORING.md)

### Current Performance Baseline

**Baseline Measurement Date**: Initial baseline established (2024)

**System Information**:

- OS: NixOS (Linux)
- Kernel: 6.6.112-rt63
- Store Size: ~56GB (measured via `du -sh /nix/store`)
- Store Paths: ~3,943 paths in current system (measured via `nix-store --query --requisites`)

**Note**: Actual values vary by system and configuration. Update these measurements after system rebuilds and optimizations.

#### Evaluation Performance

**Flake Evaluation Time**:

```bash
# Measure flake evaluation time (requires build-time-fetch-tree feature)
time nix flake check --extra-experimental-features build-time-fetch-tree
# Baseline: To be measured after system rebuild with new configuration
# Expected: Faster evaluation with homebrew-j178 marked as buildTime = true
```

**NixOS Build Evaluation Time**:

```bash
# Measure NixOS system evaluation (dry run)
time nh os build --dry
# Baseline: To be measured
# Note: Run on NixOS system (jupiter host)
```

**Darwin Build Evaluation Time**:

```bash
# Measure Darwin system evaluation (dry run)
time darwin-rebuild switch --dry-run --flake ~/.config/nix#Lewiss-MacBook-Pro
# Baseline: To be measured on macOS system
```

#### Store Metrics

**Store Size**:

```bash
# Current store size
du -sh /nix/store
# Baseline: ~56GB (measured 2024)
```

**Store Paths**:

```bash
# Number of store paths in current system
nix-store --query --requisites /run/current-system | wc -l
# Baseline: ~3,943 paths (measured 2024)
```

**Number of Generations**:

```bash
# NixOS generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | wc -l

# Home Manager generations
nix profile list | wc -l
# Baseline: To be measured per system
```

**Cache Hit Analysis**:

```bash
# Analyze store paths and potential cache hits
nix path-info --recursive --size /run/current-system | head -20

# Check substitution status
nix store ping

# Test cache connectivity
./scripts/utils/test-caches.sh

# Test cache substitution with real packages
./scripts/utils/test-cache-substitution.sh [package-name]
```

**Note**: For detailed information on cache behavior and troubleshooting, see:

- [`docs/SUBSTITUTER_QUERY_BEHAVIOR.md`](SUBSTITUTER_QUERY_BEHAVIOR.md) - How Nix queries substituters
- [`docs/CACHE_ERROR_IMPACT.md`](CACHE_ERROR_IMPACT.md) - Impact of cache errors on builds

### Key Metrics to Track

1. **Evaluation Time**: Time from `nh switch` start to evaluation completion
   - Target: < 10 seconds (with optimizations)
   - Current baseline: To be measured after system rebuild
   - **Tracked automatically**: Monthly via `track-performance.sh`

2. **Substitution Throughput**: Speed of binary cache downloads
   - Monitor: Network utilization during substitution
   - Target: Saturate available bandwidth

3. **Cache Hit Rate**: Percentage of derivations found in binary caches
   - Monitor: Using `nix-store --query --requisites` and cache analysis
   - Target: > 95% for standard operations
   - **Note**: Actual hit rate requires build-time monitoring with `nix build --log-format internal-json`

### Measurement Commands

```bash
# Automated monthly tracking (recommended)
./scripts/maintenance/track-performance.sh

# Manual measurement commands
# Measure evaluation time
time nh os switch

# Analyze store paths and cache hits
nix path-info --recursive --size /run/current-system | head -20

# Check substitution status
nix store ping

# Monitor during switch
nix-instantiate --eval --strict -E 'builtins.currentTime'

# Measure flake check (evaluation only, no builds)
time nix flake check

# Measure store size
du -sh /nix/store

# Count generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | wc -l
```

### Performance Improvement Tracking

Record improvements after optimizations:

- **After build-time input fetching**: To be measured (expected: 10-30% faster evaluation)
- **After input pruning**: N/A (all inputs are actively used)
- **After overlay optimization**: N/A (overlays are necessary and documented)

**Historical Trends**: Review `.performance-metrics/` directory for trend analysis over time.

## References

- [Strategic Performance Tuning for Determinate Nix and Home Manager Environments](./reference/performance-tuning-reference.md) (if available)
- [Determinate Nix Manual](https://manual.determinate.systems/)
- [NixOS Performance Wiki](https://nixos.wiki/wiki/Nix_Evaluation_Performance)
