# System Architecture Documentation

This document describes the architecture of this Nix configuration system, explaining how components interact and how configuration flows from host definitions to final system builds.

## Overview

This configuration uses a feature-based, modular architecture that separates concerns between:

- **Host Configuration**: High-level feature flags per machine
- **Feature Modules**: Declarative feature implementations
- **Service Modules**: Platform-specific service configurations
- **System Builders**: Build-time orchestration

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      flake.nix                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   inputs     │  │  nixConfig   │  │   outputs    │     │
│  │              │  │              │  │              │     │
│  │ - nixpkgs    │  │ - caches     │  │ - darwin     │     │
│  │ - darwin     │  │ - features   │  │ - nixos      │     │
│  │ - home-mgr   │  │ - build-time │  │ - home       │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                 flake-parts/core.nix                        │
│  - Host discovery (lib/hosts.nix)                          │
│  - System builders (lib/system-builders.nix)               │
│  - Output builders (lib/output-builders.nix)               │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              hosts/<hostname>/default.nix                   │
│  ┌────────────────────────────────────────────────────┐    │
│  │ host = {                                            │    │
│  │   username = "lewis";                               │    │
│  │   features.gaming.enable = true;                    │    │
│  │   features.development.enable = true;               │    │
│  │ };                                                  │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│            lib/system-builders.nix                         │
│  ┌────────────────────────────────────────────────────┐    │
│  │ mkNixosSystem / mkDarwinSystem                      │    │
│  │  1. Apply overlays (lib/functions.nix)              │    │
│  │  2. Import platform modules                         │    │
│  │  3. Import feature modules                         │    │
│  │  4. Build system configuration                       │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│         modules/nixos/features/*.nix                        │
│  ┌────────────────────────────────────────────────────┐    │
│  │ config = mkIf cfg.enable {                         │    │
│  │   environment.systemPackages = [...];               │    │
│  │   services.steam.enable = true;                     │    │
│  │ };                                                  │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Final NixOS/Darwin System                      │
└─────────────────────────────────────────────────────────────┘
```

## Configuration Flow

### 1. Host Definition

Hosts are defined in `hosts/<hostname>/default.nix`:

```nix
{
  username = "lewis";
  useremail = "lewis@example.com";
  hostname = "jupiter";
  system = "x86_64-linux";

  features = {
    gaming = {
      enable = true;
      steam = true;
    };
    development = {
      enable = true;
      rust = true;
    };
  };
}
```

### 2. Host Discovery

`lib/hosts.nix` discovers and validates hosts:

- Scans `hosts/` directory for host configurations
- Validates host configuration structure
- Separates Darwin and NixOS hosts
- Provides helper functions for host access

### 3. System Building

`lib/system-builders.nix` orchestrates system construction:

**For NixOS**:

```nix
mkNixosSystem hostName hostConfig {self}:
  nixpkgs.lib.nixosSystem {
    system = hostConfig.system;

    modules = [
      # Host configuration
      ../hosts/${hostName}/configuration.nix

      # Apply overlays
      {
        nixpkgs = {
          overlays = functionsLib.mkOverlays {...};
          config = functionsLib.mkPkgsConfig;
        };
      }

      # Platform modules
      ../modules/nixos/default.nix

      # Feature modules (imported via modules/nixos/default.nix)
      # - modules/nixos/features/gaming.nix
      # - modules/shared/features/development/default.nix (shared feature)
      # etc.
    ];
  };
```

**For Darwin**:
Similar structure but uses `darwin.lib.darwinSystem` instead.

### 4. Overlay Application

Overlays are applied in `lib/system-builders.nix` via `functionsLib.mkOverlays`:

```nix
# lib/functions.nix
mkOverlays = {inputs, system}:
  lib.attrValues (
    import ../overlays {
      inherit inputs;
      inherit system;
    }
  );
```

**Overlay Application Order**:

1. Core overlays (unstable, localPkgs)
2. Application overlays (npm-packages, flake package integrations)
3. Platform-specific overlays (niri, audio-nix, chaotic-packages, etc.)

**Key Point**: Overlays are applied **before** modules are evaluated, so modules receive packages with overlays already applied.

### 5. Feature Module Processing

Feature modules in `modules/nixos/features/` translate feature flags into configuration:

```nix
# modules/nixos/features/gaming.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.host.features.gaming;
in {
  config = mkIf cfg.enable {
    programs.steam.enable = mkIf cfg.steam true;
    services.sunshine.enable = mkIf cfg.steam true;
    # ... more configuration
  };
}
```

### 6. Service Module Integration

Some features bridge to service modules:

```nix
# modules/nixos/features/media-management.nix
config = mkIf (cfg.enable or false) {
  host.services.mediaManagement = {
    enable = true;
    # Maps feature options to service options
  };
};
```

Service modules in `modules/nixos/services/` handle the actual service configuration.

## Component Relationships

### Host Options → Feature Modules

- **Host Options** (`modules/shared/host-options.nix`): Defines the option schema
- **Feature Modules** (`modules/nixos/features/*.nix`): Implements the options
- **Relationship**: Feature modules read `config.host.features.*` and generate NixOS/Darwin configuration

### Feature Modules → Service Modules

- **Feature Modules**: High-level feature flags
- **Service Modules**: Low-level service configuration
- **Relationship**: Features can bridge to services (e.g., `media-management.nix` → `qbittorrent.nix`)

### Overlays → Packages

- **Overlays** (`overlays/*.nix`): Modify or add packages
- **Packages**: Used by modules via `pkgs`
- **Relationship**: Overlays are applied to nixpkgs before modules receive `pkgs`

### System Builders → Modules

- **System Builders** (`lib/system-builders.nix`): Orchestrate module imports
- **Modules**: Provide configuration fragments
- **Relationship**: System builders compose modules into final system configuration

## Overlay Application Mechanism

Overlays are applied in `lib/system-builders.nix`:

```nix
# In mkNixosSystem / mkDarwinSystem
modules = [
  # Apply overlays from overlays/ directory
  {
    nixpkgs = {
      overlays = functionsLib.mkOverlays {
        inherit inputs;
        inherit (hostConfig) system;
      };
      config = functionsLib.mkPkgsConfig;
    };
  }

  # ... other modules (which can now use modified pkgs)
];
```

**How it works**:

1. `functionsLib.mkOverlays` imports `overlays/default.nix`
2. `overlays/default.nix` returns an attribute set of overlays
3. `lib.attrValues` converts the set to a list
4. NixOS/Darwin applies the overlay list to nixpkgs
5. All subsequent modules receive `pkgs` with overlays applied

**Important**: Overlays are applied **early** in the module list, so all modules receive modified packages.

## Feature System Flow

```
┌──────────────────┐
│  Host Config     │
│  features.gaming │
│  .enable = true  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  host-options.nix│
│  Defines schema  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  gaming.nix      │
│  Reads cfg.enable│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  NixOS Config    │
│  programs.steam  │
│  .enable = true  │
└──────────────────┘
```

## Module Import Order

Modules are imported in this order (in `lib/system-builders.nix`):

1. **Host Configuration**: `hosts/${hostName}/configuration.nix`
2. **Host Options Set**: `{ config.host = hostConfig; }`
3. **Overlays Applied**: `{ nixpkgs = { overlays = ...; }; }`
4. **Platform Modules**: `../modules/nixos/default.nix`
5. **Integration Modules**: `sops-nix`, `home-manager`, etc.
6. **Home Manager Config**: `{ home-manager = ...; }`
7. **Validation**: `mkValidationModule`
8. **Common Modules**: `../modules/shared`

## Special Arguments Flow

Special arguments are passed through multiple layers:

```nix
# flake-parts/core.nix
mkNixosSystem hostName hostConfig {self}

# lib/system-builders.nix
specialArgs = {
  inherit inputs;
  inherit (hostConfig) system username useremail hostname;
  keysDirectory = "${self}/keys";
};

# Available in all modules
{pkgs, inputs, system, username, ...}: {
  # Can use specialArgs here
}
```

## Validation System

Validation happens via assertions:

```nix
# lib/system-builders.nix
mkValidationModule = {config, ...}: {
  assertions = [
    {
      assertion = hostCheck.status != "fail";
      message = "[Validation] ${hostCheck.name}: ${hostCheck.message}";
    }
  ];
};
```

Validation checks:

- Host configuration completeness (username, useremail, hostname, system)
- Secrets configuration (SOPS setup)
- Feature dependencies (via feature module assertions)

## Home Manager Integration

Home Manager is integrated via:

```nix
# lib/system-builders.nix
mkHomeManagerConfig = {hostConfig, ...}: {
  useGlobalPkgs = true;
  extraSpecialArgs = inputs // hostConfig // {...};
  sharedModules = [sops-nix.homeManagerModules.sops ...];
  users.${hostConfig.username} = import ../home;
};
```

**Key Points**:

- Uses same `pkgs` as system (via `useGlobalPkgs`)
- Receives same specialArgs as system modules
- Shares overlays with system configuration

## Cross-Platform Considerations

### Platform Detection

Modules detect platform via:

```nix
# In feature modules
environment.systemPackages = with pkgs;
  optionals pkgs.stdenv.isLinux [linux-pkg]
  ++ optionals pkgs.stdenv.isDarwin [darwin-pkg];
```

### Platform-Specific Modules

- **NixOS**: `modules/nixos/` - Linux-specific configuration
- **Darwin**: `modules/darwin/` - macOS-specific configuration
- **Shared**: `modules/shared/` - Cross-platform configuration

### Platform-Specific Overlays

Overlays can be conditional:

```nix
# overlays/default.nix
audio-nix = mkConditional isLinux inputs.audio-nix.overlays.default;
niri = mkConditional isLinux inputs.niri.overlays.niri;
```

## Build-Time Inputs

Build-time inputs are marked in `flake.nix`:

```nix
homebrew-j178 = {
  url = "github:j178/homebrew-tap";
  flake = false;
  buildTime = true;  # Fetched only during build, not evaluation
};
```

**Impact**: These inputs are not available during evaluation, only during build/realization.

## Testing Architecture

Tests are organized in `tests/`:

- **evaluation.nix**: Tests that configurations evaluate
- **integration/**: Integration tests for specific features
- **home-manager.nix**: Home Manager configuration tests

## Extension Points

### Adding a New Feature

1. Define options in `modules/shared/host-options.nix`
2. Create module in `modules/nixos/features/my-feature.nix`
3. Import in `modules/nixos/default.nix`
4. Use in host config: `host.features.myFeature.enable = true`

### Adding a New Overlay

1. Create `overlays/my-overlay.nix`
2. Import in `overlays/default.nix`
3. Overlay automatically applied to all systems

### Adding a New Service

1. Create `modules/nixos/services/my-service.nix`
2. Import in `modules/nixos/services/default.nix`
3. Optionally create feature bridge in `modules/nixos/features/`

## Key Design Decisions

### Why Feature-Based?

- **Declarative**: High-level intent vs low-level configuration
- **Composable**: Features can be combined easily
- **Maintainable**: Changes in one place affect all hosts
- **Testable**: Features can be tested in isolation

### Why Overlay Early Application?

- **Consistency**: All modules see same modified packages
- **Predictability**: No surprises from late overlay application
- **Performance**: Overlays applied once, not per-module

### Why Separate Host Options?

- **Type Safety**: Options defined in one place
- **Discoverability**: Clear schema for available options
- **Validation**: Centralized validation logic

## Further Reading

- [Feature Module Guide](./FEATURES.md) - How to create and use features
- [Performance Tuning](./PERFORMANCE_TUNING.md) - Performance considerations
- [Development Guide](./DX_GUIDE.md) - Development practices
- [Module Templates](../templates/) - Templates for new modules
