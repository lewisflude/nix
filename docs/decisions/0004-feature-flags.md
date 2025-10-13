# ADR-0004: Feature Flag System

**Date:** 2025-01-14  
**Status:** Accepted  
**Deciders:** Lewis Flude  
**Technical Story:** Phase 2 Architecture Improvements - Feature Management

## Context

Enabling or disabling features required one of these approaches:

1. **Commenting out imports**:
   ```nix
   imports = [
     ./gaming.nix
     # ./development.nix  # Temporarily disabled
   ];
   ```

2. **Conditional imports based on hostname**:
   ```nix
   imports = [] 
     ++ lib.optionals (hostname == "gaming-pc") [./gaming.nix];
   ```

3. **Manual configuration in each module**:
   ```nix
   programs.steam.enable = false;  # Disabled manually
   ```

Problems:
- Commented code is ugly and easy to forget about
- Hard to see what features are enabled at a glance
- Conditional logic scattered throughout config
- No central place to manage features per host
- Difficult to create feature presets or profiles

## Decision

Implement a comprehensive feature flag system with:

1. **Centralized library** (`lib/features.nix`) with utilities
2. **Host-level feature configuration**
3. **Module-level feature checks**
4. **Type-safe options**

### Usage Pattern

```nix
# In host configuration
features = {
  gaming.enable = true;
  development.enable = true;
  homeServer.enable = false;
};

# In module
{config, lib, ...}: {
  options.features.gaming = {
    enable = lib.mkEnableOption "gaming support";
  };
  
  config = lib.mkIf config.features.gaming.enable {
    programs.steam.enable = true;
    # ...
  };
}
```

## Consequences

### Positive

- **Centralized Control**: All features configured in one place
- **Clear Overview**: Easy to see what's enabled per host
- **Type Safety**: Options validated by NixOS module system
- **No Comments**: No commented-out code
- **Easy Toggle**: Change one boolean, rebuild
- **Composable**: Features can depend on other features
- **Self-Documenting**: Feature list is clear configuration
- **Preset Ready**: Foundation for feature presets

### Negative

- **Learning Curve**: New pattern to learn
- **Migration Effort**: Existing configs need updating
- **Slight Overhead**: Extra indirection through feature flags

### Neutral

- **More Verbose**: More explicit than import comments
- **New Files**: Added `lib/features.nix` and documentation

## Alternatives Considered

### Alternative 1: Environment Variables
```bash
ENABLE_GAMING=1 nixos-rebuild switch
```

**Rejected because:**
- Not declarative
- Hard to version control
- Can't see enabled features from config alone
- Environment variables not portable

### Alternative 2: Separate Config Files Per Profile
```nix
# profiles/gaming.nix
# profiles/development.nix
# Then: import ./profiles/gaming.nix
```

**Rejected because:**
- Profiles are too coarse-grained
- Hard to mix features from different profiles
- Duplication across profiles
- Doesn't solve the core problem

### Alternative 3: Use NixOS Profiles
```nix
system.profile = "gaming-workstation";
```

**Rejected because:**
- Profiles are system-wide, not feature-specific
- Can't easily combine profile features
- Less flexible than feature flags
- Profiles better for system variants, not features

### Alternative 4: Keep Status Quo (Comments)
**Rejected because:**
- Comments are maintenance burden
- Easy to forget about commented code
- No clear way to see enabled features
- Doesn't scale well

## Implementation Details

### Feature Library (`lib/features.nix`)

Utilities provided:
- `mkFeature` - Create single feature option
- `mkFeatures` - Create multiple feature options
- `mkFeatureModule` - Complete module with feature
- `featureEnabled` - Check if feature is on
- `withFeature` - Conditional imports based on feature
- `mkPlatformFeature` - Platform-specific features

### Module Pattern

```nix
{config, lib, pkgs, ...}:
let
  cfg = config.features.myFeature;
in {
  options.features.myFeature = {
    enable = lib.mkEnableOption "my feature";
    
    # Sub-options
    option1 = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable option 1";
    };
  };
  
  config = lib.mkIf cfg.enable {
    # Implementation
  };
}
```

### Host Configuration Pattern

```nix
# hosts/my-host/configuration.nix
{
  features = {
    gaming = {
      enable = true;
      steam = true;
      lutris = false;
    };
    
    development = {
      enable = true;
      languages = {
        python = true;
        rust = true;
      };
    };
  };
}
```

## Usage Examples

### Simple Feature
```nix
# Module
options.features.docker = lib.mkEnableOption "Docker";
config = lib.mkIf config.features.docker.enable {
  virtualisation.docker.enable = true;
};

# Host
features.docker.enable = true;
```

### Complex Feature with Sub-Options
```nix
# Module
options.features.gaming = {
  enable = lib.mkEnableOption "gaming";
  steam = lib.mkEnableOption "Steam" // {default = true;};
  proton = lib.mkEnableOption "Proton" // {default = true;};
};

# Host
features.gaming = {
  enable = true;
  steam = true;
  proton = false;
};
```

### Conditional Imports
```nix
imports = featureLib.withFeature config "gaming" [
  ./gaming/steam.nix
  ./gaming/proton.nix
];
```

## Migration Path

1. Create `lib/features.nix` with utilities
2. Update modules to use feature flags
3. Convert commented imports to feature flags
4. Update host configurations
5. Document pattern in guides
6. Validate all configs still build

## Future Enhancements

Potential additions:
- **Feature Presets**: Pre-configured feature sets
  ```nix
  features.preset = "gaming-workstation";
  ```
- **Conflict Detection**: Automatic incompatibility checking
- **Feature Discovery**: List available features
  ```bash
  nix eval .#features.available
  ```
- **Feature Dependencies**: Automatic enabling of dependencies
- **Feature Groups**: Hierarchical feature organization

## Documentation

- Created [docs/guides/feature-flags.md](../guides/feature-flags.md)
- Updated [CONTRIBUTING.md](../../CONTRIBUTING.md)
- Examples in feature guide
- Documented in module index

## References

- [Feature Flags Guide](../guides/feature-flags.md)
- [Phase 2 Documentation](../PHASE-2-IMPROVEMENTS.md)
- [lib/features.nix](../../lib/features.nix)
- Commit: `6f84100`

## Related ADRs

- None directly, but enables future preset/profile ADRs

---

**Result:** Successfully implemented with comprehensive documentation. Provides foundation for advanced feature management. Pattern adopted for all toggleable functionality.
