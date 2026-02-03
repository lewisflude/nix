# Dendritic Pattern - Source of Truth

This document captures the canonical patterns from the dendritic architecture. Use this as the authoritative reference when implementing or refactoring modules.

## Core Principles

1. **Infrastructure declares options, hosts compose modules**
2. **All imports happen at host level** (external inputs AND feature modules)
3. **No extraSpecialArgs** - use top-level flake-parts options instead
4. **One file = one module** - avoid multiple files contributing to the same `flake.modules.*` path

## File Structure

```
.
├── flake.nix                              # Entry point - imports all modules
└── modules/
    ├── infrastructure/
    │   ├── flake-parts.nix                # Enables flake-parts module system
    │   ├── nixos.nix                      # configurations.nixos option + transformation
    │   ├── darwin.nix                     # configurations.darwin option + transformation
    │   └── home-manager.nix               # homeManagerBase modules (structure only)
    ├── options/
    │   └── host.nix                       # base modules with host.* options
    ├── hosts/
    │   ├── jupiter/
    │   │   └── definition.nix             # NixOS host - imports ALL modules
    │   └── mercury/
    │       └── definition.nix             # Darwin host - imports ALL modules
    ├── systems.nix                        # Supported systems
    ├── meta.nix                           # Top-level options (username, useremail)
    ├── constants.nix                      # Top-level constants option
    └── <feature>.nix                      # Feature modules (shell, audio, gaming, etc.)
```

## Key Patterns

### 1. Entry Point (`flake.nix`)

```nix
{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # ... other inputs
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; }
      (inputs.import-tree ./modules);
}
```

### 2. Infrastructure Modules

Infrastructure modules ONLY declare options and transform them to flake outputs.

**NixOS Infrastructure** (`modules/infrastructure/nixos.nix`):
```nix
{ lib, config, inputs, ... }:
{
  options.configurations.nixos = lib.mkOption {
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
    nixosConfigurations = lib.flip lib.mapAttrs config.configurations.nixos (
      name: { module }: inputs.nixpkgs.lib.nixosSystem { modules = [ module ]; }
    );

    # Auto-generated checks
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

**Darwin Infrastructure** (`modules/infrastructure/darwin.nix`):
```nix
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

### 3. Home-Manager Infrastructure

Provides ONLY the structure, not module imports:

```nix
{ config, ... }:
let
  inherit (config) username useremail constants;
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
        programs.git.settings.user.email = useremail;
      };
    };
  };

  flake.modules.darwin.homeManagerBase = { ... }: {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm-backup";

      users.${username} = { ... }: {
        home.stateVersion = constants.defaults.stateVersion;
        home.username = username;
        home.homeDirectory = "/Users/${username}";
        programs.home-manager.enable = true;
        programs.git.settings.user.email = useremail;
      };
    };
  };
}
```

### 4. Shared Options (`modules/meta.nix`)

```nix
{ lib, ... }:
{
  options = {
    username = lib.mkOption {
      type = lib.types.singleLineStr;
      readOnly = true;
      default = "lewis";
    };

    useremail = lib.mkOption {
      type = lib.types.singleLineStr;
      readOnly = true;
      default = "lewis@lewisflude.com";
    };
  };
}
```

### 5. Feature Modules

Feature modules define `flake.modules.<platform>.<name>` and can target multiple platforms:

```nix
# modules/shell.nix
{ config, ... }:
let
  inherit (config) username;
in
{
  # NixOS system-level
  flake.modules.nixos.shell = { pkgs, ... }: {
    programs.zsh.enable = true;
    users.users.${username}.shell = pkgs.zsh;
  };

  # Darwin system-level
  flake.modules.darwin.shell = { pkgs, ... }: {
    programs.zsh.enable = true;
  };

  # Home-manager (works on both)
  flake.modules.homeManager.shell = { lib, pkgs, config, ... }: {
    programs.zsh = {
      enable = true;
      # ... configuration
    };
  };
}
```

### 6. Host Definitions

Hosts import ALL modules - both external inputs and feature modules:

```nix
# modules/hosts/jupiter/definition.nix
{ config, inputs, ... }:
let
  constants = config.constants;
  inherit (config) username useremail;
  inherit (config.flake.modules) nixos homeManager;
in
{
  configurations.nixos.jupiter.module = { pkgs, ... }: {
    imports = [
      # External input modules
      inputs.nixpkgs.nixosModules.notDetected
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops
      # ... other external modules

      # Base modules
      nixos.base
      nixos.homeManagerBase

      # Feature modules
      nixos.boot
      nixos.networking
      nixos.desktop
      nixos.gaming
      # ... other feature modules
    ];

    nixpkgs.hostPlatform = "x86_64-linux";

    # Home-manager imports (at host level)
    home-manager.users.${username}.imports = [
      # External home-manager modules
      inputs.nix-index-database.homeModules.nix-index
      inputs.sops-nix.homeManagerModules.sops
      # ... other external modules

      # Feature home-manager modules
      homeManager.shell
      homeManager.git
      homeManager.ssh
      homeManager.gaming
      # ... other feature modules
    ];

    # Host-specific configuration
    host = {
      username = username;
      hostname = "jupiter";
      system = "x86_64-linux";
      features.gaming.enable = true;
      # ...
    };

    networking.hostName = "jupiter";
    system.stateVersion = constants.defaults.stateVersion;
    # ... other host-specific config
  };
}
```

## Module Types Summary

| Type | Location | Purpose |
|------|----------|---------|
| Infrastructure | `modules/infrastructure/*.nix` | Declares options, transforms to flake outputs |
| Meta | `modules/meta.nix` | Shared options (username, email) |
| Constants | `modules/constants.nix` | Application constants as top-level option |
| Options | `modules/options/*.nix` | Defines `host.*` options in base modules |
| Feature | `modules/<feature>.nix` | Reusable config via `flake.modules.*` |
| Host | `modules/hosts/<name>/definition.nix` | Composes features into a host |

## Access Patterns

### From Feature Module (flake-parts level)
```nix
{ config, ... }:
{
  flake.modules.nixos.myFeature = {
    users.users.${config.username} = { ... };
  };
}
```

### From Feature Module (platform config)
```nix
{ config, ... }:
{
  flake.modules.nixos.myFeature = { pkgs, lib, config, ... }: {
    # 'config' here is NixOS config, not flake-parts config
    environment.systemPackages = [ pkgs.somePackage ];
  };
}
```

### From Home-Manager Module
```nix
{ config, ... }:
{
  flake.modules.homeManager.myFeature = { pkgs, config, osConfig ? {}, ... }: {
    # config = home-manager config
    # osConfig = NixOS/Darwin config (when available)
    home.packages = [ pkgs.somePackage ];
  };
}
```

### Constants Access
```nix
{ config, ... }:
let
  constants = config.constants;
in
{
  flake.modules.nixos.myService = { ... }: {
    services.myService.port = constants.ports.services.myService;
  };
}
```

## Benefits

1. **Single Source of Truth** - Options like `username` defined once, used everywhere
2. **Auto-Discovery** - Add a file to `modules/`, it's automatically imported
3. **Type Safety** - `deferredModule` and `lazyAttrsOf` provide proper typing
4. **Cross-Platform** - Same module can declare nixos, darwin, homeManager configs
5. **Composable** - Hosts explicitly choose which features to include
6. **Checkable** - Auto-generated checks validate all configurations
7. **Consistent** - Darwin and NixOS follow identical patterns

## Anti-Patterns to Avoid

1. **Don't use `with pkgs;`** - Always use explicit `pkgs.packageName`
2. **Don't hardcode values** - Use `meta.nix` options or `constants.nix`
3. **Don't mix concerns** - Feature modules shouldn't know about specific hosts
4. **Don't import features in infrastructure** - All imports happen at host level
5. **Don't use extraSpecialArgs** - Use top-level flake-parts options instead
6. **Don't have multiple files contribute to the same module** - One file = one module
