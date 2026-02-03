# Dendritic Pattern Compliance Analysis

This document analyzes the current state of the repository's compliance with the [dendritic pattern](https://github.com/mightyiam/dendritic) and provides a roadmap for full compliance.

## What is the Dendritic Pattern?

The dendritic pattern is a Nix configuration architecture where:

1. **Every file is a top-level flake-parts module** - not a NixOS/darwin/home-manager module directly
2. **Lower-level configurations are stored as option values** using the `deferredModule` type
3. **File paths represent features**, not configuration types (no organizing by platform)
4. **Automatic import** using `import-tree` - files gain path independence
5. **Value sharing** happens through top-level config, not `specialArgs`
6. **Each file implements a single feature** that spans all applicable configurations

### Core Principle

Instead of organizing code like this:
```
hosts/jupiter/configuration.nix  # NixOS config
hosts/mercury/configuration.nix  # Darwin config
home/nixos/default.nix          # Home-manager for NixOS
home/darwin/default.nix         # Home-manager for Darwin
```

The dendritic pattern organizes by **features**:
```
modules/gaming.nix              # Defines gaming for all platforms
modules/vr.nix                  # Defines VR for all platforms
modules/desktop.nix             # Defines desktop for all platforms
```

Each module defines `flake.modules.<class>.<aspect>` where:
- `<class>` is `nixos`, `darwin`, or `homeManager`
- `<aspect>` is the feature name

## Current Compliance Status

### ✅ What's Already Compliant

#### 1. Infrastructure (Fully Compliant)

The infrastructure is **100% dendritic compliant**:

- **`modules/infrastructure/nixos.nix`**: Uses `deferredModule` type for `configurations.nixos` option
- **`modules/infrastructure/darwin.nix`**: Uses `deferredModule` type for `configurations.darwin` option
- **`modules/infrastructure/home-manager.nix`**: Uses `deferredModule` type for home-manager
- **`modules/infrastructure/flake-parts.nix`**: Orchestrates the flake-parts setup
- **No `specialArgs`** - all modules access shared values via `config.<option>`

#### 2. Flake Setup (Fully Compliant)

```nix
# flake.nix outputs section
outputs = inputs@{ self, ... }:
  inputs.flake-parts.lib.mkFlake { inherit inputs self; } {
    imports = [
      ./flake-parts/core.nix
      # Dendritic pattern: auto-import all modules
      (inputs.import-tree ./modules)
    ];
  };
```

✅ Uses `import-tree` for automatic module discovery
✅ All `.nix` files in `modules/` are automatically imported as flake-parts modules
✅ Files prefixed with `_` are ignored (useful for work-in-progress)

#### 3. Host Definitions (Fully Compliant)

**`modules/hosts/jupiter/definition.nix`**:
```nix
{ config, inputs, ... }:
{
  configurations.nixos.jupiter = {
    system = "x86_64-linux";
    module = { lib, pkgs, modulesPath, ... }: {
      imports = [
        config.flake.modules.nixos.desktop
      ];
      # Host-specific configuration
    };
  };
}
```

✅ Uses `configurations.nixos.<name>` option (defined by infrastructure)
✅ Module is a `deferredModule`
✅ Imports from `config.flake.modules.nixos.*` (dendritic aspects)
✅ No hardcoded paths - uses dendritic references

#### 4. Constants (Fully Compliant)

**`modules/constants.nix`**: Defines top-level `config.constants` option

✅ **Constants Aspect Pattern** - provides values to all features
✅ Accessible from all modules via `config.constants`
✅ No need for `specialArgs` or passing values through module arguments

#### 5. Core Modules (Fully Compliant)

**`modules/core/nix.nix`**: Defines both `flake.modules.nixos.base` and `flake.modules.darwin.base`

✅ **Multi-Context Aspect Pattern** - single file defines multiple classes
✅ Uses `config.constants` for shared values
✅ Uses `config.username` from top-level

#### 6. Fully Migrated Service Modules

**`modules/comfyui.nix`**: ✅ Full implementation in dendritic pattern

```nix
{ config, ... }:
{
  flake.modules.nixos.comfyui = { lib, pkgs, ... }: {
    # Full service configuration
  };
}
```

✅ Defines `flake.modules.nixos.comfyui` aspect
✅ Accesses `config.constants` for ports
✅ Complete implementation (not a wrapper)

### ⚠️ What's Partially Compliant

#### 1. Wrapper Modules (Need Full Migration)

These modules are **dendritic-shaped wrappers** but still import from `_old_nixos/`:

**`modules/sunshine.nix`**:
```nix
flake.modules.nixos.sunshine = { ... }: {
  imports = [ ./_old_nixos/services/sunshine/default.nix ];
};
```

❌ Still imports from old structure
✅ Defines dendritic aspect
🔄 **ACTION NEEDED**: Move full implementation into the wrapper file

**`modules/home-assistant.nix`**: Same issue - wrapper importing old module

**`modules/hytale-server.nix`**: Same issue - wrapper importing old module

#### 2. Home-Manager Modules (Hybrid State)

**`modules/programs/base.nix`**: Partially migrated

```nix
flake.modules.homeManager.base = { ... }: {
  imports = [
    hm.shell        # ✅ Dendritic
    hm.git          # ✅ Dendritic
    # ...
    ../../home/common/features/development  # ❌ Old path imports
  ];
};
```

✅ Defines dendritic aspect
✅ Uses dendritic imports for core modules
❌ Still has path-based imports for features
🔄 **ACTION NEEDED**: Convert remaining feature modules to dendritic

#### 3. Platform-Specific Modules

**`modules/programs/darwin-workstation.nix`**: Hybrid

```nix
flake.modules.darwin.workstation = { ... }: {
  imports = [ config.flake.modules.darwin.base ];
  # Darwin-specific config
};
```

✅ Defines dendritic aspect
✅ Inherits from base
❌ Could be split into feature-based modules
🔄 **ACTION NEEDED**: Consider breaking into smaller feature modules

### ❌ What's Not Compliant

#### 1. Old Module Structure

**`modules/_old_nixos/`**, **`modules/_old_darwin/`**, **`modules/_old_shared/`**:

These directories contain the **old hierarchical structure**:
- Traditional NixOS/darwin modules (not flake-parts modules)
- Organized by platform, not feature
- Used by wrapper modules

❌ Not dendritic pattern
🔄 **ACTION NEEDED**: Migrate content into feature modules, then delete

#### 2. Traditional Home-Manager Structure

**`home/common/`**, **`home/nixos/`**, **`home/darwin/`**:

These directories use the **old home-manager organization**:
- Separated by platform
- Not using `flake.modules.homeManager.*` aspects
- Still imported via path-based imports

❌ Not dendritic pattern
🔄 **ACTION NEEDED**: Convert to `flake.modules.homeManager.*` aspects

## Dendritic Aspect Patterns Used

Based on the [dendritic patterns guide](https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki/Dendritic_Aspects):

### ✅ Currently Using

1. **Simple Aspect**: Features for one or multiple contexts
   - Example: `modules/comfyui.nix` (NixOS only)

2. **Multi-Context Aspect**: Feature with main context + nested context
   - Example: `modules/core/nix.nix` (defines both nixos.base and darwin.base)

3. **Constants Aspect**: Provides constant values to all features
   - Example: `modules/constants.nix` (top-level constants)

4. **Inheritance Aspect**: Extends existing features
   - Example: `modules/programs/darwin-workstation.nix` extends `darwin.base`

### 🔄 Should Be Using

5. **Conditional Aspect**: Platform-specific behavior in same file
   - **Needed for**: Home-manager modules that work on both NixOS and Darwin
   - Example pattern:
   ```nix
   flake.modules.homeManager.myApp = { pkgs, lib, ... }:
     lib.mkMerge [
       {
         # Common config for all platforms
       }
       (lib.mkIf pkgs.stdenv.isLinux {
         # Linux-specific
       })
       (lib.mkIf pkgs.stdenv.isDarwin {
         # macOS-specific
       })
     ];
   ```

6. **Collector Aspect**: Feature that merges config from multiple contributors
   - **Needed for**: Features like Syncthing where each host contributes its ID
   - Example: Each host module adds to `flake.modules.nixos.syncthing`

## Migration Roadmap

### Phase 1: Migrate Service Wrappers (High Priority)

Convert wrapper modules to full implementations:

1. **Sunshine** (`modules/sunshine.nix`):
   - Copy implementation from `modules/_old_nixos/services/sunshine/`
   - Integrate directly into `flake.modules.nixos.sunshine`
   - Test on Jupiter host

2. **Home Assistant** (`modules/home-assistant.nix`):
   - Copy implementation from `modules/_old_nixos/services/home-assistant/`
   - Integrate directly into `flake.modules.nixos.homeAssistant`
   - Test on Jupiter host

3. **Hytale Server** (`modules/hytale-server.nix`):
   - Copy implementation from `modules/_old_nixos/services/hytale-server/`
   - Integrate directly into `flake.modules.nixos.hytaleServer`
   - Test on Jupiter host

### Phase 2: Migrate Home-Manager Modules (Medium Priority)

Convert home-manager modules to dendritic aspects:

1. Create `modules/home-manager/` directory for new dendritic home modules
2. For each feature in `home/common/features/`:
   - Create `modules/home-manager/<feature>.nix`
   - Define `flake.modules.homeManager.<feature>`
   - Use **Conditional Aspect** pattern for platform differences
3. Update `modules/programs/base.nix` to import dendritic aspects instead of paths
4. Test on both Jupiter (NixOS) and Mercury (Darwin)

### Phase 3: Clean Up Old Structure (Low Priority)

Once all migrations are complete:

1. **Verify** all hosts build and work correctly
2. **Delete** `modules/_old_nixos/`, `modules/_old_darwin/`, `modules/_old_shared/`
3. **Delete** `home/` directory (all content migrated)
4. **Update** documentation to reflect pure dendritic structure

### Phase 4: Optimization (Optional)

Consider these improvements:

1. **Break down large modules**: Split `desktop`, `gaming`, `vr` into smaller feature modules
2. **Implement Collector Aspects**: For services that need cross-host configuration
3. **Add Factory Aspects**: For parameterized module generation (e.g., user templates)
4. **Use DRY Aspects**: For reusable attribute set configurations

## How to Write New Modules (Dendritic Style)

### Template for Simple Aspect (Single Platform)

```nix
# modules/my-service.nix
{ config, ... }:
let
  constants = config.constants;
in
{
  flake.modules.nixos.myService = { lib, pkgs, ... }: {
    # Service configuration
    services.myService = {
      enable = true;
      port = constants.ports.services.myService;
    };
  };
}
```

### Template for Multi-Context Aspect (Multiple Platforms)

```nix
# modules/my-feature.nix
{ config, ... }:
let
  constants = config.constants;
in
{
  # NixOS configuration
  flake.modules.nixos.myFeature = { lib, pkgs, ... }: {
    environment.systemPackages = [ pkgs.myPackage ];
  };

  # Darwin configuration
  flake.modules.darwin.myFeature = { lib, pkgs, ... }: {
    environment.systemPackages = [ pkgs.myPackage ];
  };

  # Home-Manager configuration (works on both)
  flake.modules.homeManager.myFeature = { lib, pkgs, ... }: {
    home.packages = [ pkgs.myPackage ];
  };
}
```

### Template for Conditional Aspect (Platform-Specific Behavior)

```nix
# modules/my-app.nix
{ config, ... }:
{
  flake.modules.homeManager.myApp = { lib, pkgs, ... }:
    lib.mkMerge [
      {
        # Common configuration
        programs.myApp.enable = true;
      }
      (lib.mkIf pkgs.stdenv.isLinux {
        # Linux-specific configuration
        programs.myApp.linuxOption = true;
      })
      (lib.mkIf pkgs.stdenv.isDarwin {
        # macOS-specific configuration
        programs.myApp.darwinOption = true;
      })
    ];
}
```

## Benefits We're Already Seeing

1. **Path Independence**: Modules can be renamed/moved without breaking imports
2. **Clean Value Sharing**: No `specialArgs` - all values via `config.*`
3. **Feature-Oriented**: Think in terms of features, not platforms
4. **Auto-Discovery**: `import-tree` eliminates manual imports
5. **Unified Top-Level**: All configuration decisions visible in one evaluation

## Benefits After Full Migration

1. **No Platform Silos**: Features span all applicable platforms in one file
2. **Easier Cross-Platform**: Add Darwin support to a feature by adding one aspect
3. **Simplified Testing**: Each feature file is self-contained and testable
4. **Better Reusability**: Features can be shared across projects as-is
5. **Cleaner Mental Model**: One file = one feature = simple

## References

- [Dendritic Pattern (mightyiam)](https://github.com/mightyiam/dendritic)
- [Dendritic Design Guide (Doc-Steve)](https://github.com/Doc-Steve/dendritic-design-with-flake-parts)
- [Dendritic Aspect Patterns](https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki/Dendritic_Aspects)
- [Flake Parts Documentation](https://flake.parts)
- [Example: mightyiam/infra](https://github.com/mightyiam/infra)
- [Example: vic/vix](https://github.com/vic/vix)
- [Flipping the Configuration Matrix](https://not-a-number.io/2025/refactoring-my-infrastructure-as-code-configurations/#flipping-the-configuration-matrix)
