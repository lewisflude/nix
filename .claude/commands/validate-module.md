---
description: "Validate Nix module structure and placement"
---

# Module Validation

Validate that a Nix module follows project conventions and is placed in the correct location.

## What to Check

### 1. Module Placement

**System-Level** (must be in `modules/nixos/` or `modules/darwin/`):
- System services (systemd, launchd)
- Kernel modules and drivers
- Hardware configuration
- Root-level daemons
- Container runtimes (Podman, Docker daemons)
- Graphics drivers and system libraries
- Network configuration
- Boot loaders

**Home-Manager** (must be in `home/common/apps/` or `home/{nixos,darwin}/`):
- User applications and CLI tools
- User systemd services (systemd --user)
- Dotfiles and shell configuration
- Development tools (LSPs, formatters, linters)
- Desktop applications
- User tray applets
- Editor configurations

### 2. Code Style

Check for antipatterns:

**❌ Using `with pkgs;`**:
```nix
# WRONG
home.packages = with pkgs; [ curl wget ];

# CORRECT
home.packages = [ pkgs.curl pkgs.wget ];
```

**❌ Hardcoded values**:
```nix
# WRONG
services.app.port = 8080;

# CORRECT
let
  constants = import ../lib/constants.nix;
in
{
  services.app.port = constants.ports.services.app;
}
```

### 3. Module Structure

Verify proper module structure:

```nix
{ config, lib, pkgs, ... }:

let
  cfg = config.features.myFeature;
in
{
  options.features.myFeature = {
    enable = lib.mkEnableOption "my feature";

    # Additional options with proper types
  };

  config = lib.mkIf cfg.enable {
    # Configuration
  };
}
```

### 4. Documentation

Check that:
- Options have `description` fields
- Complex logic has comments
- Module purpose is clear

### 5. Imports

Verify:
- All imports use correct relative paths
- No circular dependencies
- Constants and validators are imported if used

## Usage

**Arguments**:
- `$1` - Path to module file to validate
- If no argument, check the most recently edited `.nix` file

**Examples**:
```
/validate-module modules/nixos/features/audio.nix
/validate-module home/common/apps/git.nix
/validate-module
```

## Your Task

1. **Read the module file** - Use Read tool to examine the module
2. **Check placement** - Verify it's in the correct directory based on its purpose
3. **Scan for antipatterns** - Look for `with pkgs;`, hardcoded values, etc.
4. **Verify structure** - Ensure it follows the standard pattern
5. **Check documentation** - Verify options have descriptions
6. **Report findings** - Provide clear feedback on issues found

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

- `CLAUDE.md` - Module placement guidelines (section: Module Placement Guidelines)
- `CONVENTIONS.md` - Coding standards
- `docs/reference/architecture.md` - Architecture patterns
- `docs/FEATURES.md` - Feature module conventions
