---
description: "Validate Nix module structure and placement"
---

# Module Validation (Dendritic Pattern)

Validate that a Nix module follows the dendritic pattern and project conventions.

## What to Check

### 1. Is it a Flake-Parts Module?

Every `.nix` file under `modules/` must be a flake-parts module:

```nix
# ✅ CORRECT - Flake-parts module
{ config, lib, ... }:
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

### 2. Scope Usage

Check that `config` is accessed from the correct scope:

```nix
# ✅ CORRECT - Canonical pattern with nixosArgs
{ config, ... }:
{
  flake.modules.nixos.shell = nixosArgs: {
    users.users.${config.username}.shell = nixosArgs.config.programs.fish.package;
    #              ^^^^^^^^^^^^^^              ^^^^^^^^^^^^
    #              Top-level (outer)           Platform config
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

### 3. Constants Access

```nix
# ✅ CORRECT - Via top-level config
{ config, ... }:
let
  constants = config.constants;
in
{
  flake.modules.nixos.service = { ... }: {
    services.app.port = constants.ports.services.app;
  };
}

# ❌ WRONG - Direct import (anti-pattern)
let
  constants = import ../lib/constants.nix;
in
```

### 4. Code Style

**❌ Using `with pkgs;`**:
```nix
# WRONG
home.packages = with pkgs; [ curl wget ];

# CORRECT
home.packages = [ pkgs.curl pkgs.wget ];
```

**❌ Using specialArgs**:
```nix
# WRONG
lib.nixosSystem { specialArgs = { inherit inputs; }; }

# CORRECT - Access from outer scope
{ config, inputs, ... }:
{
  flake.modules.nixos.myFeature = { ... }: {
    # inputs available via closure
  };
}
```

### 5. Module Placement

**System-level** (`flake.modules.nixos.*` or `flake.modules.darwin.*`):
- System services (systemd, launchd)
- Kernel modules and drivers
- Hardware configuration
- Container runtimes
- Graphics drivers
- Network configuration
- Boot configuration

**Home-manager** (`flake.modules.homeManager.*`):
- User applications and CLI tools
- User services (systemd --user)
- Dotfiles and shell configuration
- Development tools
- Desktop applications
- Editor configurations

## Usage

**Arguments**:
- `$1` - Path to module file to validate
- If no argument, check the most recently edited `.nix` file

**Examples**:
```
/validate-module modules/audio.nix
/validate-module modules/hosts/jupiter/definition.nix
/validate-module
```

## Your Task

1. **Read the module file** - Use Read tool to examine the module
2. **Check if dendritic** - Is it a flake-parts module with `flake.modules.*`?
3. **Check scope usage** - Is `config` accessed correctly (outer vs inner)?
4. **Scan for antipatterns** - `with pkgs;`, `specialArgs`, direct imports
5. **Verify placement** - System vs home-manager distinction
6. **Report findings** - Provide clear feedback

## Validation Output

Provide a structured report:

**✅ Passes**:
- List what the module does correctly

**⚠️ Warnings**:
- Non-critical issues that should be addressed

**❌ Errors**:
- Critical issues that must be fixed

**💡 Suggestions**:
- Improvements or optimizations

## Auto-fix Option

Ask the user if they want you to fix identified issues automatically.

## Related Documentation

- `DENDRITIC_SOURCE_OF_TRUTH.md` - Complete dendritic pattern documentation
- `CLAUDE.md` - Module placement guidelines
