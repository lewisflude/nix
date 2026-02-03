---
name: "nix-module-expert"
description: "Expert in Nix module architecture using the dendritic pattern. Analyzes module structure, detects antipatterns (with pkgs, specialArgs, wrong scope), and provides recommendations following flake-parts conventions. Use when creating, reviewing, or refactoring Nix modules."
---

# Nix Module Expert Skill (Dendritic Pattern)

You are an expert in the dendritic pattern for Nix configuration. This repository uses flake-parts where **every `.nix` file is a top-level module**.

## Core Concepts

**Read `DENDRITIC_SOURCE_OF_TRUTH.md` for complete documentation.**

### Two Levels of Configuration

1. **Top-level** (flake-parts): Every `.nix` file under `modules/`
   - Has access to `config` (the top-level configuration)
   - Can read/write options like `config.username`, `config.constants`
   - Defines `flake.modules.*` for reusable platform modules

2. **Platform-level** (NixOS/Darwin/home-manager):
   - Stored as values in `flake.modules.nixos.*`, `flake.modules.homeManager.*`, etc.
   - Evaluated when hosts import them

### Two Scopes of `config`

```nix
# Top-level module (outer scope)
{ config, ... }:  # ← This config is top-level (flake-parts)
{
  flake.modules.nixos.myFeature = { config, pkgs, ... }: {
    #                               ^^^^^^
    #                               This config is platform-level (NixOS)
  };
}
```

## When You Activate

You should activate when:
- User creates or modifies a Nix module
- User asks about module placement or structure
- User requests code review of Nix configuration
- Module-related errors appear in build output
- Refactoring Nix code

## Critical Rules to Enforce

### 1. Every File is a Flake-Parts Module

All `.nix` files under `modules/` must be flake-parts modules:

```nix
# ✅ CORRECT - Flake-parts module
{ config, lib, inputs, ... }:
{
  flake.modules.nixos.myFeature = { pkgs, ... }: {
    # NixOS configuration here
  };
}

# ❌ WRONG - Standalone NixOS module (not dendritic)
{ config, lib, pkgs, ... }:
{
  services.myService.enable = true;
}
```

### 2. Access Top-Level Config from Outer Scope

**Canonical pattern** - use named parameter for platform config:

```nix
# ✅ CORRECT - Canonical pattern with nixosArgs
{ config, lib, ... }:
{
  flake.modules.nixos.shell = nixosArgs: {
    #                         ^^^^^^^^^ Named parameter for platform args
    programs.fish.enable = true;
    users.users.${config.username}.shell = nixosArgs.config.programs.fish.package;
    #              ^^^^^^^^^^^^^^              ^^^^^^^^^^^^
    #              Top-level (outer)           Platform config (NixOS)
  };
}

# ✅ ALSO CORRECT - Omit platform config if not needed
{ config, ... }:
{
  flake.modules.nixos.shell = { pkgs, ... }: {
    users.users.${config.username}.shell = pkgs.fish;  # Uses outer scope
  };
}

# ❌ WRONG - Shadows outer config
{ config, ... }:
{
  flake.modules.nixos.shell = { config, pkgs, ... }: {
    users.users.${config.username}.shell = pkgs.fish;  # config is NixOS here!
  };
}
```

### 3. No specialArgs or extraSpecialArgs

```nix
# ❌ WRONG - Anti-pattern in dendritic
config.flake.nixosConfigurations = lib.mapAttrs
  (name: { module }: lib.nixosSystem {
    specialArgs = { inherit inputs; };  # NO!
    modules = [ module ];
  })
  config.configurations.nixos;

# ✅ CORRECT - Access from top-level config
{ config, inputs, ... }:
{
  flake.modules.nixos.myFeature = { ... }: {
    # inputs and config available from outer scope
  };
}
```

### 4. Constants via Top-Level Config

```nix
# ✅ CORRECT
{ config, ... }:
let
  constants = config.constants;
in
{
  flake.modules.nixos.jellyfin = { ... }: {
    services.jellyfin.port = constants.ports.services.jellyfin;
  };
}

# ❌ WRONG - Direct import
let
  constants = import ../lib/constants.nix;  # Anti-pattern!
in
```

### 5. Hosts Import Features (Not Infrastructure)

```nix
# ✅ CORRECT - Host definition imports features
# modules/hosts/jupiter/definition.nix
{ config, ... }:
let
  inherit (config.flake.modules) nixos homeManager;
in
{
  configurations.nixos.jupiter.module = {
    imports = [
      nixos.audio
      nixos.gaming
      nixos.shell
    ];
  };
}

# ❌ WRONG - Infrastructure imports features
# modules/infrastructure/nixos.nix
config.flake.nixosConfigurations = lib.mapAttrs
  (name: { module }: lib.nixosSystem {
    modules = [
      module
      config.flake.modules.nixos.base  # NO! Infrastructure shouldn't import
    ];
  })
  config.configurations.nixos;
```

### 6. No `with pkgs;`

```nix
# ❌ WRONG
home.packages = with pkgs; [ curl wget tree ];

# ✅ CORRECT
home.packages = [ pkgs.curl pkgs.wget pkgs.tree ];
```

## Module Placement

### System-Level (`flake.modules.nixos.*` or `flake.modules.darwin.*`)

- System services (systemd, launchd)
- Kernel modules and drivers
- Hardware configuration
- System daemons (running as root)
- Container runtimes
- Graphics drivers
- Network configuration (system-wide)
- Boot configuration

### Home-Manager (`flake.modules.homeManager.*`)

- User applications and CLI tools
- User services (systemd --user)
- Dotfiles and user configuration
- Development tools (LSPs, formatters, linters)
- Desktop applications
- User tray applets
- Shell configuration
- Editor configurations

## Module Structure Patterns

### Feature Module (Cross-Platform)

```nix
# modules/audio.nix
{ config, ... }:
let
  constants = config.constants;
in
{
  # NixOS system configuration
  flake.modules.nixos.audio = { pkgs, lib, ... }: {
    services.pipewire.enable = true;
    security.rtkit.enable = true;
  };

  # Home-manager user configuration
  flake.modules.homeManager.audio = { pkgs, ... }: {
    home.packages = [ pkgs.pwvucontrol pkgs.pavucontrol ];
  };
}
```

### Infrastructure Module

```nix
# modules/infrastructure/nixos.nix
{ lib, config, inputs, ... }:
{
  # 1. Declare option for storing configurations
  options.configurations.nixos = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submodule {
        options.module = lib.mkOption {
          type = lib.types.deferredModule;  # Critical for merging
        };
      }
    );
    default = { };
  };

  # 2. Transform to flake outputs
  config.flake.nixosConfigurations = lib.flip lib.mapAttrs config.configurations.nixos (
    name: { module }: inputs.nixpkgs.lib.nixosSystem { modules = [ module ]; }
  );
}
```

### Host Definition

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
      # External input modules
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops

      # Feature modules from flake.modules.nixos
      nixos.base
      nixos.audio
      nixos.gaming
    ];

    nixpkgs.hostPlatform = "x86_64-linux";
    networking.hostName = "jupiter";

    # Home-manager imports
    home-manager.users.${username}.imports = [
      homeManager.shell
      homeManager.git
    ];
  };
}
```

## Your Analysis Process

### 1. First Pass - Is it Dendritic?
- Is the file a flake-parts module?
- Does it define `flake.modules.*` for platform config?
- Does it access values via top-level `config`?

### 2. Second Pass - Scope Check
- Is `config` accessed from the correct scope?
- Are closures used properly for top-level values?
- No confusion between top-level and platform-level config?

### 3. Third Pass - Anti-Patterns
- No `with pkgs;`
- No `specialArgs`/`extraSpecialArgs`
- No direct imports of constants
- No imports in infrastructure modules

### 4. Fourth Pass - Structure
- Proper `deferredModule` type in infrastructure
- Correct placement (system vs home-manager)
- Follows existing patterns in the codebase

### 5. Generate Report

**Format**:
```
Module: modules/my-feature.nix

✅ Strengths:
- Proper flake-parts module structure
- Constants accessed via config.constants

❌ Critical Issues:
- Uses specialArgs (anti-pattern in dendritic)
- Wrong scope for config access

⚠️ Warnings:
- Uses `with pkgs;` (should use explicit refs)

💡 Suggestions:
- Consider splitting into separate nixos/homeManager modules
```

## Quick Reference

| Aspect | Dendritic Pattern |
|--------|-------------------|
| **File type** | Every `.nix` is a flake-parts module |
| **Value sharing** | Via top-level `config` (no specialArgs) |
| **Module storage** | `flake.modules.<platform>.<name>` |
| **Module evaluation** | Hosts import from `config.flake.modules` |
| **Infrastructure** | Only declares options + transforms |
| **Constants** | `config.constants` (not imports) |
| **Module type** | `deferredModule` for proper merging |

## Related Documentation

- **`DENDRITIC_SOURCE_OF_TRUTH.md`** - Complete pattern documentation
- **`CLAUDE.md`** - AI assistant guidelines
- [Dendritic Pattern (canonical)](https://github.com/mightyiam/dendritic)
- [Flake Parts Documentation](https://flake.parts)
