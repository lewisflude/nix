---
name: "feature-validator"
description: "Validates feature modules against the dendritic pattern. Ensures modules follow flake-parts conventions, checks proper scope usage, validates cross-platform structure, and verifies module composition. Use when adding new features, modifying modules, or reviewing changes."
---

# Feature Validator Skill (Dendritic Pattern)

You validate feature modules against the dendritic pattern where every `.nix` file is a flake-parts module.

## Core Concepts

**Read `DENDRITIC_SOURCE_OF_TRUTH.md` for complete documentation.**

In the dendritic pattern:
- **Every file** under `modules/` is a flake-parts module
- **Features** are defined as `flake.modules.nixos.<name>` or `flake.modules.homeManager.<name>`
- **Hosts** compose features by importing from `config.flake.modules`
- **Values** are shared via top-level `config` (no specialArgs)

## When You Activate

You should activate when:
- User creates a new feature module
- User modifies existing module configuration
- Module-related errors appear
- User asks about module patterns
- Reviewing PR that adds/changes modules

## Feature Module Pattern

### Basic Structure

```nix
# modules/my-feature.nix
{ config, ... }:
let
  constants = config.constants;  # Access top-level constants
in
{
  # NixOS system configuration
  flake.modules.nixos.myFeature = { pkgs, lib, ... }: {
    # Platform-level config
  };

  # Home-manager user configuration (optional)
  flake.modules.homeManager.myFeature = { pkgs, ... }: {
    # Platform-level config
  };
}
```

### Cross-Platform Feature

```nix
# modules/shell.nix
{ config, ... }:
let
  inherit (config) username;
in
{
  # NixOS shell configuration
  flake.modules.nixos.shell = { pkgs, ... }: {
    programs.fish.enable = true;
    users.users.${username}.shell = pkgs.fish;
  };

  # Darwin shell configuration
  flake.modules.darwin.shell = { pkgs, ... }: {
    programs.fish.enable = true;
  };

  # Home-manager shell configuration
  flake.modules.homeManager.shell = { pkgs, ... }: {
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        # User shell config
      '';
    };
  };
}
```

## Validation Rules

### 1. File Structure

**Must be a flake-parts module**:
```nix
# ✅ CORRECT
{ config, lib, inputs, ... }:
{
  flake.modules.nixos.myFeature = { ... }: { };
}

# ❌ WRONG - Not a flake-parts module
{ config, lib, pkgs, ... }:
{
  services.myService.enable = true;
}
```

### 2. Scope Usage

**Canonical pattern** - use named parameter for platform config:
```nix
# ✅ CORRECT - Canonical pattern with nixosArgs
{ config, lib, ... }:
{
  flake.modules.nixos.shell = nixosArgs: {
    programs.fish.enable = true;
    users.users.${config.username}.shell = nixosArgs.config.programs.fish.package;
    #              ^^^^^^^^^^^^^^              ^^^^^^^^^^^^
    #              Top-level (outer)           Platform config (NixOS)
  };
}

# ✅ ALSO CORRECT - Omit platform config if not needed
{ config, ... }:
{
  flake.modules.nixos.user = { pkgs, ... }: {
    users.users.${config.username}.shell = pkgs.fish;  # Uses outer scope
  };
}

# ❌ WRONG - Shadows outer config
{ config, ... }:
{
  flake.modules.nixos.user = { config, pkgs, ... }: {
    users.users.${config.username}.shell = pkgs.fish;  # config is NixOS here!
  };
}
```

### 3. Constants Access

**Use `config.constants`, not imports**:
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

# ❌ WRONG
let
  constants = import ../lib/constants.nix;
in
```

### 4. No `with pkgs;`

```nix
# ❌ WRONG
home.packages = with pkgs; [ curl wget ];

# ✅ CORRECT
home.packages = [ pkgs.curl pkgs.wget ];
```

### 5. Module Placement

**System-level** (`flake.modules.nixos.*` / `flake.modules.darwin.*`):
- System services
- Hardware configuration
- Kernel modules
- Container runtimes
- Graphics drivers

**Home-manager** (`flake.modules.homeManager.*`):
- User applications
- Dotfiles
- User services
- Desktop apps
- Shell configuration

### 6. Host Imports Features

Features are imported in host definitions, not infrastructure:

```nix
# ✅ CORRECT - modules/hosts/jupiter/definition.nix
{ config, ... }:
let
  inherit (config.flake.modules) nixos homeManager;
in
{
  configurations.nixos.jupiter.module = {
    imports = [
      nixos.audio
      nixos.gaming
    ];
  };
}
```

## Validation Checklist

### Structure Validation
- [ ] File is a flake-parts module (not standalone NixOS/HM module)
- [ ] Defines `flake.modules.<platform>.<name>`
- [ ] Uses proper function signature `{ config, ... }:`

### Scope Validation
- [ ] Top-level `config` accessed from outer scope
- [ ] No confusion between top-level and platform-level config
- [ ] Closures used correctly for value access

### Code Quality
- [ ] No `with pkgs;` usage
- [ ] No `specialArgs` usage
- [ ] Constants via `config.constants`
- [ ] Explicit package references

### Placement Validation
- [ ] System config in `flake.modules.nixos.*`
- [ ] User config in `flake.modules.homeManager.*`
- [ ] Cross-platform handled correctly

### Integration Validation
- [ ] Module imported in host definition
- [ ] No conflicts with existing modules
- [ ] Builds successfully (`nix flake check`)

## Common Issues

### Issue #1: Not a Flake-Parts Module

```nix
# ❌ WRONG - This is a NixOS module, not dendritic
{ config, lib, pkgs, ... }:
{
  options.myFeature.enable = lib.mkEnableOption "my feature";
  config = lib.mkIf config.myFeature.enable {
    services.myService.enable = true;
  };
}

# ✅ CORRECT - Dendritic pattern
{ config, lib, ... }:
{
  flake.modules.nixos.myFeature = { pkgs, config, ... }: {
    services.myService.enable = true;
  };
}
```

### Issue #2: Wrong Config Scope

```nix
# ❌ WRONG - Shadows outer config
{ config, ... }:
{
  flake.modules.nixos.shell = { config, pkgs, ... }: {
    # This config is NixOS, not top-level!
    users.users.${config.username}.shell = pkgs.fish;
  };
}

# ✅ CORRECT - Use named parameter (canonical)
{ config, ... }:
{
  flake.modules.nixos.shell = nixosArgs: {
    users.users.${config.username}.shell = nixosArgs.config.programs.fish.package;
    #              ^^^^^^^^^^^^^^              ^^^^^^^^^^^^
    #              Top-level                   Platform config
  };
}

# ✅ ALSO CORRECT - Omit if platform config not needed
{ config, ... }:
{
  flake.modules.nixos.shell = { pkgs, ... }: {
    users.users.${config.username}.shell = pkgs.fish;
  };
}
```

### Issue #3: Direct Constant Import

```nix
# ❌ WRONG
{ ... }:
let
  constants = import ./constants.nix;  # Anti-pattern!
in
{
  flake.modules.nixos.service = { ... }: {
    services.foo.port = constants.ports.foo;
  };
}

# ✅ CORRECT
{ config, ... }:
let
  constants = config.constants;  # Via top-level config
in
{
  flake.modules.nixos.service = { ... }: {
    services.foo.port = constants.ports.foo;
  };
}
```

## Validation Report Format

```
Module: modules/my-feature.nix

✅ Structure:
- Proper flake-parts module
- Defines flake.modules.nixos.myFeature

✅ Scope:
- Top-level config accessed correctly
- Closures used properly

❌ Code Quality:
- Line 15: Uses `with pkgs;` (should use explicit refs)

⚠️ Placement:
- Consider adding homeManager module for user-facing tools

Recommendations:
1. Replace `with pkgs; [ foo bar ]` with `[ pkgs.foo pkgs.bar ]`
2. Add flake.modules.homeManager.myFeature for desktop tools
```

## Quick Reference

| Check | Valid | Invalid |
|-------|-------|---------|
| **File type** | Flake-parts module | Standalone NixOS module |
| **Config access** | Outer scope closure | Inner scope parameter |
| **Constants** | `config.constants` | `import ./constants.nix` |
| **Packages** | `[ pkgs.foo ]` | `with pkgs; [ foo ]` |
| **Platform** | `flake.modules.nixos.*` | Direct NixOS config |

## Related Documentation

- **`DENDRITIC_SOURCE_OF_TRUTH.md`** - Complete pattern documentation
- **`CLAUDE.md`** - AI assistant guidelines
- [Dendritic Pattern (canonical)](https://github.com/mightyiam/dendritic)
- [Flake Parts Documentation](https://flake.parts)
