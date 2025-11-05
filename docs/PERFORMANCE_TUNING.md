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

The following overlays modify core packages, causing cache misses and local rebuilds:

1. **pamixer.nix**: Modifies C++ compilation flags for ICU 76.1 compatibility
   - **Impact**: Forces local rebuild of pamixer and dependencies
   - **Rationale**: Necessary for compatibility with newer ICU versions
   - **Status**: Acceptable trade-off for compatibility

2. **mpd-fix.nix**: Disables io_uring for MPD build
   - **Impact**: Forces local rebuild of MPD
   - **Rationale**: Required to fix build failures on kernel 6.14.11
   - **Status**: Acceptable trade-off for functionality

**Note**: These overlays are minimal and necessary. Consider documenting in overlay files themselves.

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

### Build-Time Input Declaration (Tip 11)

**Current State**: All inputs fetched at evaluation time

**Potential Optimizations**:

- Mark non-critical inputs as build-time only
- Candidates for build-time-only:
  - `homebrew-j178` (macOS only, used at build time)
  - `nixos-hardware` (hardware-specific, could be build-time)
  - Other inputs not needed during evaluation

**Action Items**:

- Research Determinate Nix syntax for build-time-only inputs
- Identify inputs safe for build-time-only declaration
- Test impact on evaluation speed

## Performance Monitoring

### Key Metrics to Track

1. **Evaluation Time**: Time from `nh switch` start to evaluation completion
   - Target: < 10 seconds (with optimizations)
   - Current baseline: Measure before/after optimizations

2. **Substitution Throughput**: Speed of binary cache downloads
   - Monitor: Network utilization during substitution
   - Target: Saturate available bandwidth

3. **Cache Hit Rate**: Percentage of derivations found in binary caches
   - Monitor: Using `nix-store --query --requisites` and cache analysis
   - Target: > 95% for standard operations

### Measurement Commands

```bash
# Measure evaluation time
time nh os switch

# Analyze store paths and cache hits
nix path-info --recursive --size /run/current-system | head -20

# Check substitution status
nix store ping

# Monitor during switch
nix-instantiate --eval --strict -E 'builtins.currentTime'
```

## References

- [Strategic Performance Tuning for Determinate Nix and Home Manager Environments](./reference/performance-tuning-reference.md) (if available)
- [Determinate Nix Manual](https://manual.determinate.systems/)
- [NixOS Performance Wiki](https://nixos.wiki/wiki/Nix_Evaluation_Performance)
