# Future Improvements: Phases 4-6

This document outlines the next batch of improvements to be made to the Nix configuration, organized by priority and complexity.

## Phase 4: Cleanup and Optimization

### 4.1: Remove Legacy/Unused Modules and Consolidate Duplicates

**Goal:** Eliminate technical debt and reduce maintenance burden

**Tasks:**
- [ ] Audit all modules in `modules/nixos/` for duplication with features
  - `modules/nixos/development/` likely overlaps with `features/`
  - `modules/nixos/desktop/` may have redundancy
- [ ] Remove unused virtualisation.nix helper in lib/
- [ ] Consolidate gaming configuration (scattered across development/ and features/)
- [ ] Merge duplicate audio configurations
- [ ] Clean up unused imports in modules

**Benefits:**
- Faster evaluation (fewer modules to process)
- Clearer mental model (one place per feature)
- Easier maintenance (no duplicate logic)

**Estimated Impact:** ~15% faster evaluation, significant maintainability improvement

---

### 4.2: Optimize Home Manager Configuration Structure

**Goal:** Make Home Manager configs more modular and reusable

**Current Issues:**
- `home/common/profiles/full.nix` imports everything
- No clear separation between "base" and "optional" user configs
- Hard to create minimal variants

**Improvements:**
```nix
# home/common/default.nix
{
  imports = [
    ./profiles/base.nix        # Essential user tools
    ./profiles/optional.nix    # Controlled by host.features
  ];
}

# home/common/profiles/optional.nix
{ config, lib, ... }: {
  imports = lib.optionals config.host.features.development.enable [
    ../apps/cursor
    ../apps/lazydocker.nix
  ];
}
```

**Benefits:**
- Faster user environment builds
- Easier to create minimal profiles
- Better feature isolation

---

### 4.3: Add Runtime Performance Monitoring

**Goal:** Track and optimize rebuild times

**Implementation:**
```bash
# scripts/utils/benchmark-rebuild.sh
#!/usr/bin/env bash
# Benchmarks rebuild time and tracks over time

time nix build .#<config> --dry-run --json > build-profile.json
# Parse JSON, extract timing data
# Store in .benchmark-history/
# Generate trend report
```

**Features:**
- Track rebuild times after each update
- Identify performance regressions
- Baseline comparisons
- Module-level attribution (which module is slow?)

**Integration:**
- Git pre-commit hook (optional)
- CI job (track baseline performance)
- Local script for development

---

### 4.4: Create Module Templates

**Goal:** Standardize module creation with templates

**Templates to Create:**

1. **Feature Module Template**
```nix
# templates/feature-module.nix
{ config, lib, pkgs, ... }:
with lib; let
  cfg = config.host.features.FEATURE_NAME;
in {
  # Options defined in host-options.nix
  
  config = mkIf cfg.enable {
    # Assertions
    assertions = [
      {
        assertion = cfg.enable -> (condition);
        message = "helpful error message";
      }
    ];
    
    # Platform detection
    environment.systemPackages = with pkgs;
      []
      ++ optionals pkgs.stdenv.isLinux [ linuxPkg ]
      ++ optionals pkgs.stdenv.isDarwin [ darwinPkg ];
    
    # Home Manager integration
    home-manager.users.${config.host.username} = {
      # User-level config
    };
  };
}
```

2. **Service Module Template**
3. **Overlay Template**
4. **Test Module Template**

**Usage:**
```bash
# scripts/utils/new-module.sh
./scripts/utils/new-module.sh feature my-feature
# Creates modules/shared/features/my-feature.nix from template
# Adds option to host-options.nix
# Updates default.nix imports
```

---

## Phase 5: Advanced Optimization

### 5.1: Implement Flake Outputs Caching Strategy

**Goal:** Cache expensive flake evaluations

**Current Issue:**
- Every `nix build` re-evaluates the entire flake
- Overlays evaluated on every invocation
- Module system evaluation not cached

**Solution:**
```nix
# Use flake-compat for legacy nix-build caching
# Implement evaluation cache for common queries
# Pre-compute expensive parts of flake outputs

{
  # Cache system configurations
  cached-systems = lib.mapAttrs (name: cfg: 
    cfg.config.system.build.toplevel
  ) nixosConfigurations;
}
```

**Benefits:**
- Faster `nix build` commands
- Reduced evaluation overhead
- Better CI performance

**Complexity:** High (requires deep Nix knowledge)

---

### 5.2: Add Cross-Platform CI Testing

**Goal:** Test both Darwin and NixOS configurations in CI

**Current State:**
- CI only validates Linux configs
- Darwin builds untested until manual deployment

**Implementation:**
```yaml
# .github/workflows/test.yml
jobs:
  test-nixos:
    runs-on: ubuntu-latest
    # ... existing tests
  
  test-darwin:
    runs-on: macos-latest
    steps:
      - uses: DeterminateSystems/nix-installer-action@main
      - name: Build Darwin configuration
        run: |
          nix build .#darwinConfigurations.Lewiss-MacBook-Pro.system
```

**Challenges:**
- macOS runners are expensive
- Can't test in VMs like NixOS
- Limited to dry-run builds

**Alternatives:**
- Use GitHub's macOS runners (paid)
- Self-hosted runner on your MacBook
- Only validate on push to main (not PRs)

---

### 5.3: Optimize Development Shell with direnv

**Goal:** Instant development environment activation

**Current State:**
- Manual `nix develop`
- Slow to enter
- Not integrated with editor

**Implementation:**
```nix
# .envrc
use flake

# flake.nix outputs
devShells.default = pkgs.mkShell {
  nativeBuildInputs = [ ... ];
  shellHook = ''
    echo "Nix development environment loaded"
  '';
};
```

**Benefits:**
- Auto-loads on `cd` into directory
- Editor integration (VS Code, Cursor)
- Faster than `nix develop`
- Cached environment

**Requirements:**
- Install direnv
- Add `.envrc` to each project
- Configure shell integration

---

### 5.4: Add Configuration Diffing Tool

**Goal:** Preview changes before applying updates

**Use Case:**
```bash
# Before running darwin-rebuild/nixos-rebuild
./scripts/utils/diff-config.sh

# Output:
# System packages to add: curl, wget, jq
# System packages to remove: vim
# Services changed: ssh (port 22 -> 2222)
# Configuration changes: 47 files
```

**Implementation:**
```bash
# Compare current system with new derivation
nix build .#nixosConfigurations.jupiter.config.system.build.toplevel -o /tmp/new-config
nvd diff /run/current-system /tmp/new-config
```

**Integration:**
- Pre-switch hook
- CI comment on PRs
- Local command for manual checks

---

## Phase 6: Advanced Features

### 6.1: Create Migration Guide for System State

**Goal:** Document and automate system state migrations

**Scope:**
- Secrets rotation
- User data migration
- Service state preservation
- Database migrations (Home Assistant, etc.)

**Format:**
```markdown
# Migration Guide

## When to Migrate
- Major NixOS version upgrade
- Home Manager breaking changes
- Hardware changes

## Process
1. Backup current state
2. Export secrets
3. Apply new configuration
4. Restore state
5. Validate services
```

**Automation:**
```bash
# scripts/maintenance/migrate.sh
# Automates common migration tasks
```

---

### 6.2: Add Telemetry for Feature Usage Patterns

**Goal:** Understand which features are actually used

**Privacy-First Design:**
- Local-only data (no telemetry sent anywhere)
- Opt-in via feature flag
- Anonymous metrics only

**Metrics to Track:**
```nix
{
  feature-usage = {
    development.rust = {
      enabled = true;
      since = "2024-01-01";
      last-used = "2024-03-15";
    };
  };
  
  rebuild-frequency = {
    average-per-week = 5;
    last-rebuild = "2024-03-15T10:30:00Z";
  };
  
  package-counts = {
    total = 847;
    user-packages = 120;
    system-packages = 727;
  };
}
```

**Use Cases:**
- Identify unused features to disable
- Optimize for most-used features
- Track technical debt (how long since last rebuild?)

**Implementation:**
```nix
# modules/shared/telemetry.nix
{ config, lib, ... }: {
  options.telemetry.enable = lib.mkEnableOption "usage telemetry";
  
  config = lib.mkIf config.telemetry.enable {
    environment.etc."nix-config-telemetry.json".text = builtins.toJSON {
      # ... metrics
    };
  };
}
```

---

## Priority Ranking

### High Priority (Do Next)
1. **4.1: Remove legacy modules** - Quick wins, reduces complexity
2. **4.2: Optimize Home Manager** - Directly improves rebuild times
3. **5.4: Configuration diffing** - Immediate safety/usability benefit

### Medium Priority
4. **4.3: Performance monitoring** - Baseline for future optimizations
5. **4.4: Module templates** - Improves development velocity
6. **5.2: Cross-platform CI** - Catches Darwin-specific issues early

### Low Priority (Nice to Have)
7. **5.1: Flake caching** - Complex, marginal benefit
8. **5.3: direnv optimization** - Developer experience improvement
9. **6.1: Migration guide** - Only needed during major upgrades
10. **6.2: Telemetry** - Interesting but not critical

---

## Estimated Timelines

**Phase 4 (Cleanup):** 4-6 hours
- Most changes are deletions and consolidations
- Straightforward refactoring

**Phase 5 (Advanced Optimization):** 8-12 hours
- Requires testing and validation
- Some complex Nix knowledge needed

**Phase 6 (Advanced Features):** 6-10 hours
- More about documentation than code
- Can be done incrementally

---

## Success Metrics

After completing all phases:

- [ ] **Evaluation time:** < 5 seconds (currently ~8-10s)
- [ ] **Rebuild time (Darwin):** < 2 minutes (currently ~3-5m)
- [ ] **Rebuild time (NixOS):** < 5 minutes (currently ~8-12m)
- [ ] **Module count:** < 50 total modules
- [ ] **Test coverage:** 80%+ of features tested
- [ ] **CI time:** < 10 minutes
- [ ] **Documentation:** Complete for all public interfaces

---

## Breaking Changes

Some improvements require breaking changes:

**4.1: Module consolidation**
- Old module paths will be deleted
- Need to update any external references

**4.2: Home Manager restructure**
- Profile imports change
- User packages may move

**Migration Path:**
1. Announce breaking changes in CHANGELOG
2. Provide migration script
3. Keep deprecated paths with warnings for one release
4. Remove in next release

---

## Questions to Consider

Before starting Phase 4:

1. **Which modules are actually unused?** Run evaluation with `--show-trace` to see what's imported
2. **What's the overlap between features/ and old modules?** Audit both directories
3. **Can we remove any flake inputs?** Less inputs = faster evaluation
4. **Which features are never used?** Consider removing entirely
5. **What's the minimum viable configuration?** Everything else is optional

---

## Next Steps

To start Phase 4:

```bash
# 1. Create feature branch
git checkout -b phase-4-cleanup

# 2. Audit current modules
find modules/ -name '*.nix' | xargs wc -l | sort -n

# 3. Identify duplicates
rg "programs.steam" modules/  # Example: find all steam configs

# 4. Start with low-risk consolidations
# 5. Test frequently
# 6. Document changes
```

Ready to implement? Let me know which phase/task you'd like to tackle first!
