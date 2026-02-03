# Dendritic Pattern Reference

**Source of truth**: `~/Code/dendritic` (README.md and example/)

## Core Principles

1. **Every file is a flake-parts module** - not NixOS, not home-manager, but flake-parts
2. **Files are auto-imported** via `import-tree`
3. **Each file implements ONE feature** across all configurations it applies to

## Key Files Structure

### Infrastructure (`modules/infrastructure/nixos.nix`)
```nix
# MINIMAL - just creates the option and calls nixosSystem
{ lib, config, inputs, ... }:
{
  options.configurations.nixos = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.submodule {
      options.module = lib.mkOption { type = lib.types.deferredModule; };
    });
  };

  config.flake.nixosConfigurations = lib.flip lib.mapAttrs config.configurations.nixos (
    name: { module }: inputs.nixpkgs.lib.nixosSystem { modules = [ module ]; }
  );
}
```

### Module Definitions (e.g., `modules/admin.nix`)
```nix
# Defines flake.modules.nixos.<name> or flake.modules.darwin.<name>
{ config, ... }:
{
  flake.modules.nixos.admin = {
    # Can be a bare attrset OR a function
    users.groups.wheel.members = [ config.username ];
  };

  # Can also be a function when you need NixOS args:
  flake.modules.nixos.shell = nixosArgs: {
    programs.fish.enable = true;
    users.users.${config.username}.shell = nixosArgs.config.programs.fish.package;
  };
}
```

### Host Definitions (e.g., `modules/hosts/jupiter/definition.nix`)
```nix
{ config, inputs, ... }:
let
  # Access flake modules from flake-parts config
  inherit (config.flake.modules) nixos;
in
{
  configurations.nixos.jupiter.module = {
    imports = [
      # External modules from inputs
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops

      # Internal deferred modules
      nixos.base
      nixos.desktop
      nixos.gaming
    ];

    # REQUIRED - set the platform
    nixpkgs.hostPlatform = "x86_64-linux";

    # Host-specific config
    networking.hostName = "jupiter";
  };
}
```

## Anti-Patterns to AVOID

1. **NO specialArgs** - use top-level config options instead
2. **NO complex infrastructure** - infrastructure just creates nixosSystem
3. **NO nested module paths** - use `flake.modules.nixos.gaming` not `flake.modules.nixos.gaming.steam`
4. **Host module should be bare attrset** - not a function like `{ lib, pkgs, ... }:`

## Required Import

Must import flake-parts modules system:
```nix
# modules/infrastructure/flake-parts.nix
{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];
}
```

## Accessing Values

- **Top-level config** (flake-parts): `config.username`, `config.constants`
- **NixOS config** (inside module function): `nixosArgs.config.programs.fish.package`
- **Flake modules**: `config.flake.modules.nixos.<name>`
