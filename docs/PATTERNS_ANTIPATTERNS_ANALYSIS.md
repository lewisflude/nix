# Nix Configuration Patterns & Antipatterns Analysis

This document provides a comprehensive analysis of the current Nix configuration against established patterns and antipatterns, with specific recommendations for improvements.

## Executive Summary

✅ **Strengths:**

- No `builtins.fetch*` usage in evaluation phase
- Proper use of `mkIf` for conditional configuration
- Well-structured modular architecture
- Good binary cache configuration with priority ordering
- Proper input following with `.follows`

⚠️ **Areas for Improvement:**

- 30+ flake inputs (potential evaluation overhead)
- Some overlays force local rebuilds (cache misses)
- Module complexity analysis needed
- Potential for lazy-loading optional inputs

---

## Detailed Analysis

### ✅ Patterns Currently Followed

#### 1. Evaluation Performance

- **✅ Lazy-trees enabled** via Determinate Nix
- **✅ High parallelism settings** (`http-connections = 64`, `max-substitution-jobs = 64`)
- **✅ Binary cache ordering** with priority parameters
- **✅ No `builtins.fetch*` usage** - Verified: no usage in modules/hosts directories
- **✅ `useGlobalPkgs = true`** in Home Manager (Darwin)
- **✅ `useUserPackages = true`** in Home Manager (NixOS) - appropriate for NixOS

#### 2. Flake Structure

- **✅ Modular feature system** - `host.features.*` pattern is excellent
- **✅ Shared configuration** - `_common/features.nix` approach
- **✅ Input following** - Proper use of `.follows` for nixpkgs consistency
- **✅ Separate hardware config** - `hardware-configuration.nix` kept separate

#### 3. Module Organization

- **✅ Platform-specific separation** - `modules/nixos/` vs `modules/darwin/` vs `modules/shared/`
- **✅ Feature flags with `mkIf`** - Properly implemented in feature modules
- **✅ Centralized options** - `modules/shared/host-options.nix`
- **✅ Small, focused modules** - Good separation of concerns

#### 4. Home Manager

- **✅ Modular home configs** - `home/common/features/` structure
- **✅ Platform-aware configs** - Separate darwin/nixos home modules

---

### ❌ Antipatterns Found

#### 1. Input Count (30+ inputs)

**Location:** `flake.nix`

**Issue:** Each input adds evaluation overhead, even if unused.

**Current Inputs:**

- Core: nixpkgs, flake-parts, darwin, home-manager, determinate, flakehub, sops-nix
- macOS: mac-app-util, nix-homebrew, homebrew-j178
- NixOS Desktop: niri, chaotic, musnix, audio-nix, solaar, nvidia-patch
- Hardware: nixos-hardware
- Applications: catppuccin, ghostty, jsonresume-nix
- Development: nur, nh, pre-commit-hooks, helix, rust-overlay, lazygit, atuin, pog, nix-topology
- VPN: vpn-confinement

**Recommendation:**

- Consider lazy-loading inputs that are only used conditionally
- Review if all inputs are necessary (e.g., `helix` is now provided via chaotic)
- Some inputs like `nixos-hardware` could potentially be build-time only

#### 2. Overlays Causing Cache Misses

**Location:** `overlays/default.nix`

**Issue:** Some overlays may modify build flags, forcing local rebuilds.

**Current Status:** ✅ Cache-impacting overlays have been removed. Remaining overlays (npm-packages, chaotic-packages) are pure aliases/additions with no cache impact.

**Recommendation:**

- Push successful builds to personal Cachix cache
- Monitor overlay additions for potential cache impact
- Consider upstreaming fixes if new overlays are added

#### 3. Potential Module Complexity

**Location:** Various modules

**Issue:** Some modules may have high import counts or deep recursion.

**Recommendation:**

- Run `scripts/utils/profile-evaluation.sh` to identify complex modules
- Consider flattening deep import chains
- Use `imports` at top level, not inside nested attrsets

#### 4. Input Usage Patterns

**Location:** `lib/system-builders.nix`

**Current Pattern:** ✅ Good - Using `lib.optionals` for conditional module inclusion

**Example:**

```nix
++ lib.optionals (determinate != null) [ determinate.nixosModules.default ]
++ lib.optionals (sops-nix != null) [ sops-nix.nixosModules.sops ]
```

**Status:** ✅ Already following best practices

---

## Specific Recommendations

### Priority 1: High Impact, Low Effort

#### 1. Review and Remove Unused Inputs

**Action:** Audit which inputs are actually used

- `helix` - Now provided via chaotic-packages overlay
- `nixos-hardware` - Only used in hardware-configuration.nix (could be lazy-loaded)

**Implementation:**

```nix
# In flake.nix, mark as optional:
nixos-hardware = {
  url = "github:NixOS/nixos-hardware";
  flake = false;  # Only needed at build time
};
```

#### 2. Optimize Overlay Cache Strategy

**Action:** Ensure all overlay builds are pushed to Cachix

**Implementation:**

```bash
# After building with overlays:
nix build .#nixosConfigurations.jupiter.config.system.build.toplevel
cachix push lewisflude <result>
```

#### 3. Add Lazy Module Loading

**Action:** Ensure all feature modules use `mkIf` aggressively

**Current Status:** ✅ Already implemented correctly

**Example from `modules/nixos/features/ai-tools.nix`:**

```nix
config = mkIf (cfg.enable or false) {
  # Only evaluates when enabled
};
```

### Priority 2: Medium Impact, Medium Effort

#### 4. Module Complexity Analysis

**Action:** Run evaluation profiling to identify bottlenecks

**Command:**

```bash
./scripts/utils/profile-evaluation.sh
```

**Review:**

- Top 10 most complex modules
- Modules with high import counts
- Large module files (>300 lines)

#### 5. Input Lazy Loading

**Action:** Make platform-specific inputs conditional

**Example:**

```nix
# Only load NixOS-specific inputs on Linux
inputs = {
  # ... core inputs ...
}
// lib.optionalAttrs (system == "x86_64-linux" || system == "aarch64-linux") {
  niri = { ... };
  chaotic = { ... };
  musnix = { ... };
}
```

**Note:** This requires careful handling in flake-parts

### Priority 3: Low Impact, High Effort

#### 6. Flatten Deep Import Chains

**Action:** Reduce module import depth

**Current Pattern:** ✅ Already using flat structure

#### 7. Optimize Option Definitions

**Action:** Review large option definition files

**Current Status:** `host-options.nix` is 723 lines - consider splitting by feature category

---

## Code Examples

### ✅ Good Pattern: Conditional Module Loading

```nix
# modules/nixos/features/ai-tools.nix
config = mkIf (cfg.enable or false) {
  host.services.aiTools = {
    enable = true;
    # ... config only evaluated when enabled
  };
};
```

### ✅ Good Pattern: Input Following

```nix
# flake.nix
home-manager = {
  url = "github:nix-community/home-manager";
  inputs.nixpkgs.follows = "nixpkgs";  # Ensures consistency
};
```

### ✅ Good Pattern: Conditional Overlays

```nix
# overlays/default.nix
audio-nix = mkConditional (isLinux && inputs ? audio-nix) (
  inputs.audio-nix.overlays.default
);
```

### ⚠️ Potential Improvement: Lazy Input Loading

```nix
# Current: All inputs loaded at eval time
inputs = {
  helix = { ... };  # Even if not used
};

# Better: Conditional loading (requires flake-parts support)
# Note: This is complex and may not be worth it
```

---

## Performance Metrics to Track

1. **Evaluation Time:** `time nix eval .#nixosConfigurations.jupiter.config.system.build.toplevel`
2. **Module Complexity:** Run `profile-evaluation.sh` regularly
3. **Cache Hit Rate:** Monitor Cachix push/pull statistics
4. **Build Time:** Track time for full system rebuilds

---

## Action Items

- [ ] Review and document which inputs are actually used
- [ ] Consider removing `helix` input (now via chaotic)
- [ ] Push overlay builds to Cachix after successful builds
- [ ] Run module complexity analysis
- [ ] Consider splitting `host-options.nix` by feature category
- [ ] Document input usage patterns in flake.nix comments
- [ ] Set up automated evaluation time tracking

---

## References

- [Nix Performance Tuning Guide](PERFORMANCE_TUNING.md)
- [Build Profiling Guide](BUILD_PROFILING.md)
- [Feature Module Documentation](FEATURES.md)
- [Architecture Reference](reference/architecture.md)

---

## Conclusion

Your Nix configuration follows most best practices. The main areas for improvement are:

1. **Input Management:** Review and potentially reduce input count
2. **Cache Strategy:** Ensure overlay builds are cached
3. **Module Complexity:** Profile and optimize complex modules

The configuration is well-structured and maintainable. The suggested improvements are optimizations rather than critical fixes.
