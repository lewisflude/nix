# Dendritic Pattern - Source of Truth

**IMPORTANT**: This document is divided into two parts:
1. **Canonical Dendritic Pattern** - From the [official dendritic repository](https://github.com/mightyiam/dendritic)
2. **Local Extensions** - Patterns specific to this repository

**When in doubt, the canonical pattern takes precedence.** Local extensions build upon but never contradict the canonical pattern.

---

# Part 1: Canonical Dendritic Pattern

**Source**: `/home/lewis/Code/dendritic` (README.md and example/)

**Note from example/README.md**:
> This example is incomplete.
> It does not mean to suggest a certain file tree layout.
> Real examples can be found in the wild.

**Key Insight**: The canonical example is intentionally minimal and demonstrates the *pattern*, not a complete implementation. File paths serve to name features - they can be freely renamed, moved, or split. The pattern is about **structure and data flow**, not specific file organization.

## The Core Idea

> The dendritic pattern reconciles [configuration complexity] using yet another application of the Nixpkgs module system—a *top-level configuration*.
> The top-level configuration facilitates the declaration and evaluation of lower-level configurations, such as NixOS, home-manager and nix-darwin.

**Every Nix file is a top-level module.** In dendritic:
- Every `.nix` file (except `flake.nix`) is a top-level configuration module (e.g., a flake-parts module)
- Each file implements a **single feature**
- Each feature spans **all platforms** that feature applies to
- File paths **serve to name** that feature (organizational only)

## Key Concepts

Before diving into examples, understand these foundational concepts:

### Two Levels of Configuration

**Top-Level** (flake-parts):
- Every `.nix` file is a module at this level
- Has access to `config` (the top-level configuration)
- Can read/write options like `config.username`, `config.flake.modules.*`
- This is where you **coordinate** between platforms

**Platform-Level** (NixOS/Darwin/home-manager):
- These are the actual system configurations
- Stored as values in top-level options
- Example: `flake.modules.nixos.myFeature` contains a NixOS module
- This is where you **configure** the actual system

### Two Scopes of `config`

```nix
# Top-level module (outer scope)
{ config, ... }:  # ← This config is top-level (flake-parts)
{
  flake.modules.nixos.myFeature = { config, pkgs, ... }: {
    #                                ^^^^^^
    #                                This config is platform-level (NixOS)
  };
}
```

### Module Storage vs Module Evaluation

**Storage** (via options):
```nix
flake.modules.nixos.admin = { ... };  # ← Defines a module (storage)
```

**Evaluation** (via imports):
```nix
configurations.nixos.desktop.module = {
  imports = [ nixos.admin ];  # ← Uses the module (evaluation)
};
```

Modules are **defined once** in feature files, **stored** in `flake.modules.*`, and **imported** in host definitions.

## What Dendritic Solves

From the README, dendritic addresses:
- Multiple configurations
- Sharing of modules across configurations
- Multiple configuration classes (nixos, home-manager, darwin)
- Configuration nesting (home-manager within NixOS)
- **Cross-cutting concerns that span multiple configuration classes**
- **Accessing values (functions, constants, packages) across files**

## Entry Point: Flake with import-tree

**Pattern**: Use `import-tree` to automatically import all modules.

```nix
# flake.nix
# From: /home/lewis/Code/dendritic/example/flake.nix
#
# In this example the top-level configuration is a `flake-parts` one.
# Therefore, every Nix file (other than this) is a flake-parts module.
{
  # Declares flake inputs
  inputs = {
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree";

    nixpkgs.url = "github:nixos/nixpkgs/25.11";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; }
      # Imports all of the top-level modules (the files under `./modules`)
      (inputs.import-tree ./modules);
}
```

**Key Points**:
- `import-tree` automatically imports all `.nix` files from `./modules`
- No manual module list to maintain
- Every imported file is a flake-parts module
- File organization is up to you - dendritic doesn't prescribe layout
- The entire outputs expression is just: `mkFlake { inherit inputs; } (import-tree ./modules)`
- All complexity lives in the modules, not in flake.nix

## Enable flake-parts.modules Option

**Pattern**: Import `flake-parts.flakeModules.modules` to enable the `flake.modules.*` option.

```nix
# modules/flake-parts.nix
# From: /home/lewis/Code/dendritic/example/modules/flake-parts.nix
{ inputs, ... }:
{
  imports = [
    # https://flake.parts/options/flake-parts-modules.html
    inputs.flake-parts.flakeModules.modules
  ];
}
```

**Key Points**:
- Enables the `flake.modules.*` option tree
- Allows feature modules to define reusable modules
- `deferredModule` type provides proper merge semantics

## Systems Declaration

**Pattern**: Declare supported systems as a top-level module.

```nix
# modules/systems.nix
# From: /home/lewis/Code/dendritic/example/modules/systems.nix
{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
}
```

**Key Points**:
- Simple attribute set, no options needed
- This is a standard flake-parts setting

## Shared Top-Level Options

**Pattern**: Define options at top-level that other modules can access via `config`.

```nix
# modules/meta.nix
# From: /home/lewis/Code/dendritic/example/modules/meta.nix
#
# Declares a top-level option that is used in other modules.
# See `./shell.nix` for example usage.
{ lib, ... }:
{
  options.username = lib.mkOption {
    type = lib.types.singleLineStr;
    readOnly = true;
    default = "iam";
  };
}
```

**Accessing in Other Modules**:
```nix
{ config, ... }:
{
  # 'config' refers to the top-level (flake-parts) config
  flake.modules.nixos.myFeature = { pkgs, ... }: {
    users.users.${config.username}.shell = pkgs.fish;
    #              ^^^^^^^^^^^^^^
    #              Access top-level config option
  };
}
```

**Key Points**:
- Options defined at top-level are accessible everywhere
- Use `readOnly` for constants
- Replaces the need for `specialArgs`
- This is how values are shared across files in dendritic

## Infrastructure Modules: NixOS

**Pattern**: Infrastructure modules ONLY:
1. Declare options for configurations
2. Transform those options to flake outputs

```nix
# modules/nixos.nix
# From: /home/lewis/Code/dendritic/example/modules/nixos.nix
#
# Provides an option for declaring NixOS configurations.
# These configurations end up as flake outputs under `#nixosConfigurations."<name>"`.
# A check for the toplevel derivation of each configuration also ends
# under `#checks.<system>."configurations:nixos:<name>"`.
{ lib, config, ... }:
{
  # 1. DECLARE OPTION for storing NixOS configurations
  options.configurations.nixos = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      #      ^^^^^^^^^^^
      #      lazyAttrsOf: allows multiple hosts (desktop, laptop, server, etc.)
      #      Each attribute name becomes a configuration name
      lib.types.submodule {
        options.module = lib.mkOption {
          type = lib.types.deferredModule;
          #      ^^^^^^^^^^^^^^^^^^^^
          #      Critical: enables proper module merging across imports
          #      Multiple modules can contribute to the same config
        };
      }
    );
  };

  # 2. TRANSFORM to flake outputs
  config.flake = {
    # Transform configurations.nixos -> flake.nixosConfigurations
    # For each host in configurations.nixos, call lib.nixosSystem
    nixosConfigurations = lib.flip lib.mapAttrs config.configurations.nixos (
      name: { module }: lib.nixosSystem { modules = [ module ]; }
      #     ^^^^^^^^    ^^^^^^^^^^^^^^^   ^^^^^^^^^^
      #     |           |                 |
      #     |           |                 Evaluates the NixOS configuration
      #     |           lib from module args (provided by flake-parts)
      #     Extract the module from the submodule
    );

    # Auto-generate checks for all configurations
    # This builds the system toplevel for each config as a check
    checks =
      config.flake.nixosConfigurations
      |> lib.mapAttrsToList (
        name: nixos: {
          # Key by the system architecture
          ${nixos.config.nixpkgs.hostPlatform.system} = {
            # Check name: "configurations:nixos:desktop"
            "configurations:nixos:${name}" = nixos.config.system.build.toplevel;
          };
        }
      )
      |> lib.mkMerge;  # Merge all checks into a single attrset
  };
}
```

**Key Points**:
- Infrastructure is **pure transformation** - no actual configuration
- `configurations.nixos` is the storage location
- `deferredModule` type is critical for proper module composition
- `lazyAttrsOf` allows multiple configurations
- Auto-generates checks for each configuration
- Uses `lib.nixosSystem` (not from inputs)

## Feature Modules: Cross-Platform

**Pattern**: Feature modules define `flake.modules.<platform>.<name>` for reusable configuration across platforms.

**Example 1: Cross-Platform Admin Access**
```nix
# modules/admin.nix
# From: /home/lewis/Code/dendritic/example/modules/admin.nix
#
# Provides the user with high permissions cross-platform.
{ config, ... }:
{
  flake.modules = {
    # NixOS implementation
    nixos.pc = {
      users.groups.wheel.members = [ config.username ];
      #                               ^^^^^^^^^^^^^^^^
      #                               Uses top-level config
    };

    # Darwin implementation
    darwin.pc.system.primaryUser = config.username;
  };
}
```

**Example 2: Accessing Platform Config**
```nix
# modules/shell.nix
# From: /home/lewis/Code/dendritic/example/modules/shell.nix
#
# Default shell for the user across NixOS and Android
{ config, lib, ... }:
#  ^^^^^^
#  Top-level (flake-parts) module arguments
{
  flake.modules = {
    # Function form: receives platform module arguments
    nixos.pc = nixosArgs: {
      #        ^^^^^^^^^
      #        Platform-level config (NixOS module arguments)
      #        Receives: { config, pkgs, lib, ... }
      programs.fish.enable = true;
      users.users.${config.username}.shell = nixosArgs.config.programs.fish.package;
      #              ^^^^^^^^^^^^^^              ^^^^^^^^^^^^^^^^^^
      #              |                           |
      #              Top-level config            Platform config (NixOS)
      #              (from outer scope)          (from nixosArgs parameter)
    };

    # Another platform in the same file
    # This demonstrates cross-platform features in one module
    nixOnDroid.base = { pkgs, ... }: {
      #               ^^^^^^^^^
      #               nixOnDroid module arguments
      user.shell = lib.getExe pkgs.fish;
      #            ^^^
      #            lib from top-level (outer scope)
    };
  };
}
```

**Key Points**:
- Single file can target multiple platforms (nixos, darwin, nixOnDroid, etc.)
- **Outer `config`** = top-level (flake-parts) config
- **Inner function args** = platform-level (NixOS/Darwin) config
- This is the essence of "cross-cutting concerns"
- Feature modules define reusable pieces, not full configurations

## Host Definitions: Composing Features

**Pattern**: Hosts are just another top-level module that composes features.

**Data Flow**:
1. Feature modules define `flake.modules.nixos.*`
2. Host pulls features from `config.flake.modules.nixos`
3. Host sets `configurations.nixos.<hostname>.module`
4. Infrastructure transforms to `flake.nixosConfigurations.<hostname>`

```nix
# modules/desktop.nix
# From: /home/lewis/Code/dendritic/example/modules/desktop.nix
#
# Uses the option in `./nixos.nix` to declare a NixOS configuration.
{ config, ... }:
#  ^^^^^^
#  Top-level config gives us access to everything defined by other modules
let
  inherit (config.flake.modules) nixos;
  #        ^^^^^^^^^^^^^^^^^^^^^^
  #        Access feature modules from top-level config
  #        These are defined by feature modules like admin.nix, shell.nix
in
{
  # Set the configurations.nixos.desktop.module option
  # This option was declared in infrastructure/nixos.nix
  configurations.nixos.desktop.module = {
    imports = [
      # Import feature modules
      # These are NixOS modules (the platform-level modules)
      nixos.admin   # From admin.nix: flake.modules.nixos.pc
      nixos.shell   # From shell.nix: flake.modules.nixos.pc
      # ...other `nixos` modules
    ];
    nixpkgs.hostPlatform = "x86_64-linux";
  };
  # Infrastructure will transform this to:
  # flake.nixosConfigurations.desktop = lib.nixosSystem {
  #   modules = [ <the module above> ];
  # };
}
```

**Key Points**:
- Host definition is a regular top-level module (not special)
- Sets `configurations.nixos.<name>.module` option
- Imports feature modules from `config.flake.modules.nixos`
- **All imports happen at host level** (not in infrastructure)
- Infrastructure transforms this to `flake.nixosConfigurations.desktop`

## Complete Data Flow Example

**Understanding the Flow**: Here's how a complete configuration flows through dendritic:

```
┌─────────────────────────────────────────────────────────────┐
│ flake.nix                                                   │
│   └─> import-tree ./modules (imports ALL .nix files)       │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Top-Level Evaluation (flake-parts)                         │
│   Every file is a flake-parts module                       │
└─────────────────────────────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
┌──────────────┐  ┌────────────────┐  ┌──────────────┐
│ meta.nix     │  │ shell.nix      │  │ desktop.nix  │
│ (OPTIONS)    │  │ (FEATURES)     │  │ (HOST)       │
└──────────────┘  └────────────────┘  └──────────────┘
        │                  │                  │
        ▼                  ▼                  ▼
  config.username   flake.modules     configurations
      = "iam"        .nixos.pc          .nixos.desktop
                     .nixos.shell           .module
```

**Step by Step**:

1. **meta.nix** (top-level module):
   ```nix
   { lib, ... }: {
     options.username = lib.mkOption { default = "iam"; };
   }
   ```
   Result: `config.username` available everywhere

2. **shell.nix** (feature module):
   ```nix
   { config, ... }: {
     flake.modules.nixos.pc = nixosArgs: {
       users.users.${config.username}.shell = nixosArgs.config.programs.fish.package;
       #              └─ from meta.nix                    └─ from NixOS eval
     };
   }
   ```
   Result: `config.flake.modules.nixos.pc` contains a NixOS module

3. **desktop.nix** (host module):
   ```nix
   { config, ... }:
   let inherit (config.flake.modules) nixos; in
   {
     configurations.nixos.desktop.module = {
       imports = [ nixos.pc nixos.shell ];  # ← Uses modules from step 2
     };
   }
   ```
   Result: `config.configurations.nixos.desktop.module` contains imports

4. **nixos.nix** (infrastructure):
   ```nix
   { lib, config, ... }: {
     config.flake.nixosConfigurations = lib.mapAttrs
       (name: { module }: lib.nixosSystem { modules = [ module ]; })
       config.configurations.nixos;  # ← Reads from step 3
   }
   ```
   Result: `flake.nixosConfigurations.desktop` is a NixOS system

**The Magic**: Every module can read from and write to the top-level config. Infrastructure reads from options and transforms them to outputs. Features define reusable modules. Hosts compose features into configurations.

## Value Sharing: No specialArgs

**The Problem (Non-Dendritic)**:
```nix
# ❌ DON'T DO THIS (anti-pattern)
nixosConfigurations.myhost = lib.nixosSystem {
  specialArgs = { inherit inputs self someValue; };
  #             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  #             Passing values through specialArgs
  modules = [ ./configuration.nix ];
};
```

From the README:
> Often they require access to values that are defined outside of their config evaluation.
> Those values are often passed through to such evaluations via the `specialArgs` argument.

**The Solution (Dendritic)**:
```nix
# ✅ DO THIS (dendritic pattern)

# Module 1: Define the value at top-level
{ lib, ... }:
{
  options.someValue = lib.mkOption {
    type = lib.types.str;
    default = "my-value";
  };
}

# Module 2: Access the value via top-level config
{ config, ... }:
{
  flake.modules.nixos.myFeature = {
    environment.variables.MY_VAR = config.someValue;
    #                              ^^^^^^^^^^^^^^^^^^
    #                              Reads from top-level config
  };
}
```

From the README:
> In the dendritic pattern every file is a top-level module and can therefore add values to the top-level `config`.
> In turn, every file can also read from the top-level `config`.
> This makes the sharing of values between files seem trivial in comparison.

**Key Points**:
- Never use `specialArgs` or `extraSpecialArgs`
- Share values via top-level `config` options
- Every module can read and write top-level config
- Simpler and more type-safe than specialArgs

## Benefits from README

### 1. Type of Every File is Known
> The common question "what's in that Nix file?" is made irrelevant.
> They each contain a Nixpkgs module system module of the same class as the top-level configuration.

### 2. Automatic Importing
> Since all files are top-level modules and their paths convey meaning only to the author,
> they can all be automatically imported using a trivial expression or a small library.

### 3. File Path Independence
> In this pattern a file path represent a feature.
> Each file can be freely renamed and moved, and it can be split when it grows too large or too complex.

## Summary of Canonical Pattern

### Key Insights from the Canonical Pattern

1. **Separation of Concerns**:
   - **Infrastructure modules** declare options and transform them to outputs (pure plumbing)
   - **Feature modules** define reusable configuration pieces (flake.modules.*)
   - **Host modules** compose features into complete systems (imports)

2. **Two-Level Architecture**:
   - Top-level (flake-parts): coordination layer where all files live
   - Platform-level (NixOS/Darwin/HM): actual configurations stored as option values

3. **Value Sharing Without specialArgs**:
   - Every file can read/write top-level config
   - No need to thread values through specialArgs/extraSpecialArgs
   - Simpler, more type-safe value sharing

4. **Cross-Platform by Default**:
   - Single file can define modules for multiple platforms
   - Example: `audio.nix` defines both `nixos.audio` and `homeManager.audio`
   - Natural way to handle cross-cutting concerns

5. **deferredModule is Critical**:
   - Enables multiple modules to merge into the same configuration
   - Without it, last-write-wins (bad for composition)
   - Required for proper dendritic pattern

### Pattern Reference Table

| Aspect | Pattern |
|--------|---------|
| **File identity** | Every `.nix` file is a top-level module |
| **Importing** | Automatic via `import-tree` |
| **File paths** | Serve to name features (organizational only) |
| **Infrastructure** | Declares options + transforms to outputs |
| **Features** | Define `flake.modules.*` for reuse |
| **Hosts** | Compose features via imports |
| **Value sharing** | Via top-level `config` (no specialArgs) |
| **Cross-platform** | Single file can target multiple platforms |
| **Module type** | `deferredModule` for proper merging |
| **File layout** | Not prescribed - organize as you wish |

---

# Part 2: Local Extensions

**These patterns extend the canonical dendritic pattern for this repository's needs.** They do not contradict canonical patterns but add additional infrastructure.

## What's Extended vs What's Canonical

The canonical pattern is **minimal and flexible**. It provides:
- ✅ The core concept (every file is a top-level module)
- ✅ Infrastructure pattern (options + transformation)
- ✅ Feature module pattern (flake.modules.*)
- ✅ Value sharing mechanism (top-level config)

The canonical pattern does **NOT** prescribe:
- ❌ Specific file tree layout
- ❌ How to organize modules (flat vs subdirectories)
- ❌ Constants management approach
- ❌ Feature flag systems
- ❌ Home-manager integration specifics

This repository adds specific implementations for production use.

## File Structure (Extended)

```
.
├── flake.nix                              # ✅ Canonical: import-tree entry
└── modules/
    ├── infrastructure/                    # 🔧 Extension: subdirectory organization
    │   ├── flake-parts.nix                # ✅ Canonical pattern
    │   ├── nixos.nix                      # ✅ Canonical (with inputs extension)
    │   ├── darwin.nix                     # 🔧 Extension: Darwin infrastructure
    │   └── home-manager.nix               # 🔧 Extension: HM base config
    ├── options/                           # 🔧 Extension: subdirectory
    │   └── host.nix                       # 🔧 Extension: host.* options system
    ├── hosts/                             # 🔧 Extension: subdirectory for hosts
    │   ├── jupiter/
    │   │   └── definition.nix             # ✅ Canonical pattern (enhanced)
    │   └── mercury/
    │       └── definition.nix             # ✅ Canonical pattern (enhanced)
    ├── core/                              # 🔧 Extension: categorized modules
    ├── desktop/                           # 🔧 Extension: categorized modules
    ├── hardware/                          # 🔧 Extension: categorized modules
    ├── services/                          # 🔧 Extension: categorized modules
    ├── per-system/                        # 🔧 Extension: per-system outputs
    ├── outputs/                           # 🔧 Extension: library/overlay exports
    ├── systems.nix                        # ✅ Canonical pattern
    ├── meta.nix                           # ✅ Canonical (extended with useremail)
    ├── constants.nix                      # 🔧 Extension: centralized constants
    └── <feature>.nix                      # ✅ Canonical pattern
```

**Note**: Subdirectories are for organization only. Each file still defines `flake.modules.*` attributes or sets top-level options.

## Extension 1: Using Inputs in Infrastructure

**Why**: Access the exact nixpkgs lib from inputs.

```nix
# modules/infrastructure/nixos.nix
{ lib, config, inputs, ... }:
#                ^^^^^^ Extension: access inputs
{
  options.configurations.nixos = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submodule {
        options.module = lib.mkOption {
          type = lib.types.deferredModule;
        };
      }
    );
    default = { };  # Extension: provide default
  };

  config.flake = {
    nixosConfigurations = lib.flip lib.mapAttrs config.configurations.nixos (
      name: { module }: inputs.nixpkgs.lib.nixosSystem { modules = [ module ]; }
      #                 ^^^^^^^^^^^^^^^^^^^^ Extension: use inputs.nixpkgs.lib
    );

    checks =
      config.flake.nixosConfigurations
      |> lib.mapAttrsToList (name: nixos: {
        ${nixos.config.nixpkgs.hostPlatform.system} = {
          "configurations:nixos:${name}" = nixos.config.system.build.toplevel;
        };
      })
      |> lib.mkMerge;
  };
}
```

**Changes from Canonical**:
- Added `inputs` parameter
- Use `inputs.nixpkgs.lib.nixosSystem` instead of `lib.nixosSystem`
- Added `default = { };` to options

## Extension 2: Darwin Infrastructure

**Why**: Support nix-darwin following the same pattern as NixOS.

```nix
# modules/infrastructure/darwin.nix
{ lib, config, inputs, ... }:
{
  options.configurations.darwin = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submodule {
        options.module = lib.mkOption {
          type = lib.types.deferredModule;
        };
      }
    );
    default = { };
  };

  config.flake = {
    darwinConfigurations = lib.flip lib.mapAttrs config.configurations.darwin (
      name: { module }: inputs.darwin.lib.darwinSystem { modules = [ module ]; }
    );

    checks =
      config.flake.darwinConfigurations
      |> lib.mapAttrsToList (name: darwin: {
        ${darwin.config.nixpkgs.hostPlatform.system} = {
          "configurations:darwin:${name}" = darwin.config.system.build.toplevel;
        };
      })
      |> lib.mkMerge;
  };
}
```

**Pattern**: Identical to NixOS infrastructure but for Darwin.

## Extension 3: Constants System

**Why**: Centralize configuration values (ports, timeouts, networks) with type safety.

```nix
# modules/constants.nix
{ lib, ... }:
{
  options.constants = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = {
      ports.services = {
        jellyfin = 8096;
        caddy = 443;
      };
      timeouts.service = {
        healthCheck = 10;
      };
      defaults = {
        timezone = "Europe/London";
        locale = "en_GB.UTF-8";
        stateVersion = "25.05";
      };
      networks = {
        lan = "192.168.1.0/24";
        vpn = "10.2.0.0/16";
      };
    };
  };
}
```

**Usage in Feature Modules**:
```nix
{ config, ... }:
let
  constants = config.constants;
in
{
  flake.modules.nixos.jellyfin = { ... }: {
    services.jellyfin.port = constants.ports.services.jellyfin;
  };
}
```

**Why Extension**: Canonical pattern doesn't prescribe constant management. This provides a structured approach.

## Extension 4: Host Options System

**Why**: Feature flags and host-specific configuration via structured options.

```nix
# modules/options/host.nix
{ lib, config, ... }:
{
  options.host = lib.mkOption {
    type = lib.types.submoduleWith {
      modules = [{
        options = {
          hostname = lib.mkOption { type = lib.types.str; };

          features = lib.mkOption {
            type = lib.types.submodule {
              options = {
                desktop.enable = lib.mkEnableOption "desktop environment";
                gaming.enable = lib.mkEnableOption "gaming support";
                vr.enable = lib.mkEnableOption "VR support";
              };
            };
          };
        };
      }];
    };
  };

  # Export as base module to make host.* available
  config.flake.modules.nixos.base = { ... }: { };
  config.flake.modules.darwin.base = { ... }: { };
}
```

**Usage in Feature Modules**:
```nix
{ config, ... }:
{
  flake.modules.nixos.gaming = { lib, config, pkgs, ... }: {
    # Conditionally enable based on host.features flag
    programs.steam.enable = lib.mkIf config.host.features.gaming.enable true;
  };
}
```

**Why Extension**: Provides declarative feature flags. Canonical pattern doesn't prescribe how to conditionally enable features.

## Extension 5: Home-Manager Base Configuration

**Why**: Provide common home-manager structure that hosts can build upon.

```nix
# modules/infrastructure/home-manager.nix
{ config, ... }:
let
  inherit (config) username;
in
{
  flake.modules.nixos.homeManagerBase = { ... }: {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm-backup";

      users.${username} = { osConfig, ... }: {
        home.stateVersion = osConfig.system.stateVersion;
        home.username = username;
        home.homeDirectory = "/home/${username}";
        programs.home-manager.enable = true;
      };
    };
  };

  flake.modules.darwin.homeManagerBase = { ... }: {
    # Similar for darwin with /Users/${username}
  };
}
```

**Why Extension**: Canonical example doesn't show home-manager integration. This provides the structure.

## Extension 6: osConfig Parameter

**Why**: Home-manager modules can read system configuration.

```nix
{ config, ... }:
{
  flake.modules.homeManager.myApp = { lib, config, osConfig ? {}, ... }: {
    #                                                ^^^^^^^^^^^^^^^^
    #                                                Access system config

    # Conditionally enable based on system feature flags
    home.packages = lib.optionals (osConfig ? host.features.gaming.enable) [
      pkgs.steam-tui
    ];

    # Access SOPS secrets from system
    programs.myApp.apiKey =
      lib.mkIf (osConfig ? sops.secrets.MY_API_KEY)
        config.sops.secrets.MY_API_KEY.path;
  };
}
```

**Why Extension**: Enables home-manager modules to react to system config. Not shown in canonical example.

## Extension 7: Enhanced Host Definitions

**Why**: Import external input modules and set host-specific configuration.

```nix
# modules/hosts/jupiter/definition.nix
{ config, inputs, ... }:
let
  inherit (config) username;
  inherit (config.flake.modules) nixos homeManager;
in
{
  configurations.nixos.jupiter.module = { pkgs, ... }: {
    imports = [
      # Extension: Import external input modules at host level
      inputs.nixpkgs.nixosModules.notDetected
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops

      # Canonical: Import base modules
      nixos.base
      nixos.homeManagerBase

      # Canonical: Import feature modules
      nixos.shell
      nixos.desktop
    ];

    nixpkgs.hostPlatform = "x86_64-linux";

    # Extension: Home-manager imports at host level
    home-manager.users.${username}.imports = [
      inputs.nix-index-database.homeModules.nix-index
      homeManager.shell
      homeManager.git
    ];

    # Extension: Set host-specific configuration via host options
    host = {
      hostname = "jupiter";
      features = {
        desktop.enable = true;
        gaming.enable = true;
      };
    };

    networking.hostName = "jupiter";
    system.stateVersion = config.constants.defaults.stateVersion;
  };
}
```

**Changes from Canonical**:
- Import external input modules (home-manager, sops-nix, etc.)
- Home-manager module imports configured at host level
- Host-specific configuration via `host` options
- Access constants from top-level config

## Extension 8: Per-System Modules

**Why**: Define per-system flake outputs (apps, devShells, formatters).

```nix
# modules/per-system/apps.nix
{ inputs, ... }:
{
  perSystem = { config, pkgs, ... }: {
    apps.update-all = {
      type = "app";
      program = "${pkgs.pog-scripts.update-all}/bin/update-all";
    };
  };
}
```

**Why Extension**: Per-system outputs are flake-parts specific. Canonical example doesn't show this.

## Extension 9: Subdirectory Organization

**Pattern**: Group related modules by category.

**Rule**: Subdirectories are for organization only - each file still defines `flake.modules.*` or top-level options.

- `modules/core/` - Fundamental system modules
- `modules/desktop/` - Desktop environment modules
- `modules/hardware/` - Hardware support modules
- `modules/services/` - Service modules
- `modules/per-system/` - Per-system outputs
- `modules/outputs/` - Library and overlay exports

**Why Extension**: Canonical example explicitly states it doesn't prescribe file layout. We organize for clarity.

## Extension 10: Multiple Related Modules Per File

**Pattern**: Group related modules in a single file (canonical supports this).

```nix
# modules/audio.nix - defines multiple related modules
{ config, ... }:
{
  flake.modules.nixos.audio = { pkgs, ... }: {
    sound.enable = true;
    services.pipewire.enable = true;
  };

  flake.modules.homeManager.audio = { pkgs, ... }: {
    home.packages = [ pkgs.pavucontrol ];
  };

  flake.modules.homeManager.noiseCancellation = { pkgs, ... }: {
    services.noiseTorch.enable = true;
  };
}
```

**Note**: This is compatible with canonical pattern (one file implements related features).

## Anti-Patterns (Canonical + Extended)

### Canonical Anti-Patterns

From the dendritic README:

1. **❌ Using specialArgs/extraSpecialArgs**
   ```nix
   # DON'T
   nixosSystem {
     specialArgs = { inherit inputs; };
   }
   # DO
   { config, ... }: {
     # Access via config.someOption
   }
   ```

2. **❌ Not using deferredModule**
   - Required for proper module composition and merging

3. **❌ Importing modules outside of host level**
   - All imports should happen at host definitions

### Local Anti-Patterns

4. **❌ Using `with pkgs;`**
   ```nix
   # DON'T
   home.packages = with pkgs; [ curl wget ];
   # DO
   home.packages = [ pkgs.curl pkgs.wget ];
   ```

5. **❌ Hardcoding values**
   ```nix
   # DON'T
   time.timeZone = "Europe/London";
   # DO
   time.timeZone = config.constants.defaults.timezone;
   ```

6. **❌ Multiple files for single module path**
   - One `flake.modules.nixos.gaming` = one file

7. **❌ Bypassing osConfig**
   - Use `osConfig` parameter when home-manager needs system config

## Comparison Table

| Pattern | Canonical | Extension | Notes |
|---------|-----------|-----------|-------|
| Every file is top-level module | ✅ | ✅ | Core principle |
| Auto-import with import-tree | ✅ | ✅ | Core principle |
| Infrastructure declares options | ✅ | ✅ | Core principle |
| Feature modules define flake.modules.* | ✅ | ✅ | Core principle |
| Top-level config sharing | ✅ | ✅ | Core principle |
| No specialArgs | ✅ | ✅ | Core principle |
| Multiple platforms per file | ✅ | ✅ | Core principle |
| deferredModule type | ✅ | ✅ | Critical for merging |
| File layout flexibility | ✅ | ✅ | Explicitly not prescribed |
| Subdirectory organization | ✅* | ✅ | *Allowed but not shown |
| Access inputs in infrastructure | ❌ | ✅ | Uses lib.nixosSystem |
| constants.nix | ❌ | ✅ | Not prescribed |
| host.* options system | ❌ | ✅ | Not prescribed |
| osConfig parameter | ❌ | ✅ | Not shown in example |
| homeManagerBase | ❌ | ✅ | Not shown in example |
| External inputs at host level | ❌ | ✅ | Example only shows feature imports |
| Per-system modules | ❌ | ✅ | Flake-parts specific |
| Darwin infrastructure | ❌ | ✅ | Not shown in example |

## Key Takeaway

**Canonical dendritic provides the architecture, not the implementation.**

The pattern is:
- ✅ Every file is a top-level module
- ✅ Infrastructure declares options + transforms
- ✅ Features define flake.modules.*
- ✅ Hosts compose features
- ✅ Value sharing via top-level config

Everything else (constants, feature flags, home-manager integration, file organization) is **implementation detail** that you design for your needs.

## Common Mistakes When Learning Dendritic

### 1. Confusing the Two Levels

**Wrong**: Thinking a feature module IS a NixOS module
```nix
# ❌ This is NOT a NixOS module
{ config, ... }:
{
  # This is a flake-parts module
  services.myService.enable = true;  # ← WRONG! No services option at top-level
}
```

**Right**: Feature module DEFINES a NixOS module
```nix
# ✅ This is a flake-parts module that defines a NixOS module
{ config, ... }:
{
  flake.modules.nixos.myFeature = { pkgs, ... }: {
    services.myService.enable = true;  # ← Correct! Inside the NixOS module
  };
}
```

### 2. Confusing the Two Scopes of `config`

**Wrong**: Accessing top-level config from wrong scope
```nix
{ config, ... }:
{
  flake.modules.nixos.myFeature = { pkgs, ... }: {
    # config here refers to NixOS config, not top-level!
    users.users.${config.username}.shell = pkgs.fish;  # ← May fail!
  };
}
```

**Right**: Access top-level config from outer scope
```nix
{ config, ... }:  # ← Outer scope
{
  flake.modules.nixos.myFeature = { pkgs, ... }: {
    users.users.${config.username}.shell = pkgs.fish;  # ← Works! Closes over outer config
    #              ^^^^^^
    #              From outer scope (top-level config)
  };
}
```

### 3. Importing Features in Infrastructure

**Wrong**: Importing features in infrastructure modules
```nix
# modules/nixos.nix
{ config, ... }:
{
  config.flake.nixosConfigurations.myhost = lib.nixosSystem {
    modules = [
      config.flake.modules.nixos.admin  # ← NO! Infrastructure shouldn't import features
      config.flake.modules.nixos.shell
    ];
  };
}
```

**Right**: Hosts import features, infrastructure transforms
```nix
# modules/myhost.nix (host module)
{ config, ... }:
let inherit (config.flake.modules) nixos; in
{
  configurations.nixos.myhost.module = {
    imports = [ nixos.admin nixos.shell ];  # ← YES! Host imports features
  };
}
```

### 4. Forgetting deferredModule Type

**Wrong**: Using plain submodule
```nix
options.configurations.nixos = lib.mkOption {
  type = lib.types.lazyAttrsOf (lib.types.submodule {
    options.module = lib.mkOption {
      type = lib.types.unspecified;  # ← NO! Won't merge properly
    };
  });
};
```

**Right**: Using deferredModule
```nix
options.configurations.nixos = lib.mkOption {
  type = lib.types.lazyAttrsOf (lib.types.submodule {
    options.module = lib.mkOption {
      type = lib.types.deferredModule;  # ← YES! Proper merging
    };
  });
};
```

### 5. Using specialArgs

**Wrong**: Threading values through specialArgs (anti-pattern)
```nix
config.flake.nixosConfigurations = lib.mapAttrs
  (name: { module }: lib.nixosSystem {
    specialArgs = { inherit inputs self; };  # ← NO! This is the anti-pattern
    modules = [ module ];
  })
  config.configurations.nixos;
```

**Right**: Access values from top-level config
```nix
# In a feature module
{ config, ... }:  # ← config has everything from top-level
{
  flake.modules.nixos.myFeature = { ... }: {
    # Access anything from config (username, constants, etc.)
    users.users.${config.username} = { ... };
  };
}
```

## References

- [Dendritic Pattern (mightyiam)](https://github.com/mightyiam/dendritic) - **Canonical source**
- [Dendritic Design Guide (Doc-Steve)](https://github.com/Doc-Steve/dendritic-design-with-flake-parts)
- [Flake Parts Documentation](https://flake.parts)
- [Example: mightyiam/infra](https://github.com/mightyiam/infra)
- [Flipping the Configuration Matrix](https://not-a-number.io/2025/refactoring-my-infrastructure-as-code-configurations/)
