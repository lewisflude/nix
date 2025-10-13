# Infinite Recursion Fix - Documentation

## Overview
Fixed infinite recursion errors that occurred when modules tried to access `config` or `pkgs` before they were fully evaluated.

## Root Cause
Modules were creating circular dependencies by:
1. Accessing `config.host.system`, `config.nixpkgs.hostPlatform.system`, or `pkgs.stdenv.*` during module evaluation
2. Using conditional imports with `lib.optionals config.*` 
3. Not having access to required arguments like `system`, `username`, etc. in module specialArgs

## Solution Summary

### 1. Added Required Arguments to specialArgs

**File**: `lib/system-builders.nix`

Added the following to both Darwin and NixOS system builders:
```nix
specialArgs = {
  inherit inputs;
  system = hostConfig.system;      # For external modules
  hostSystem = hostConfig.system;  # For our modules
  username = hostConfig.username;
  useremail = hostConfig.useremail;
  hostname = hostConfig.hostname;
  # ... other args
};
```

Also added to Home Manager's `extraSpecialArgs`:
```nix
extraSpecialArgs = {
  inherit inputs;
  system = hostConfig.system;
  hostSystem = hostConfig.system;
  username = hostConfig.username;
  useremail = hostConfig.useremail;
  hostname = hostConfig.hostname;
};
```

### 2. Fixed Module System References

Updated all modules to use `hostSystem` from specialArgs instead of:
- ❌ `config.host.system`
- ❌ `config.nixpkgs.hostPlatform.system`
- ❌ `pkgs.stdenv.system`
- ❌ `pkgs.stdenv.isDarwin`
- ❌ `pkgs.stdenv.isLinux`

#### Pattern Used:
```nix
{
  config,
  lib,
  pkgs,
  hostSystem,  # ← Add this
  ...
}: let
  isDarwin = lib.strings.hasSuffix "darwin" hostSystem;
  isLinux = lib.strings.hasSuffix "linux" hostSystem;
in {
  # Use isDarwin and isLinux instead of pkgs.stdenv.*
}
```

#### Files Fixed:
- `modules/shared/overlays.nix`
- `modules/shared/core.nix`
- `modules/shared/sops.nix`
- `modules/shared/features/security.nix`
- `modules/shared/telemetry.nix`
- `modules/nixos/system/nix/nix-optimization.nix`
- `home/common/sops.nix`
- `home/common/shell.nix`
- `home/nixos/mcp.nix`

### 3. Fixed Conditional Imports

**File**: `home/common/profiles/optional.nix`

Changed from:
```nix
{
  config,
  lib,
  ...
}:
with lib; {
  imports =
    []
    ++ optionals config.host.features.development.enable [
      ../apps/cursor
      ../development
    ]
    # ... more conditionals
}
```

To:
```nix
{
  config,
  lib,
  ...
}:
{
  imports = [
    # Import all modules unconditionally
    ../apps/cursor
    ../development
    # ...
  ];
  
  # Note: Each module uses mkIf internally to control enablement
}
```

## Best Practices

### DO ✅

1. **Pass system info through specialArgs**
   ```nix
   specialArgs = {
     system = hostConfig.system;
     hostSystem = hostConfig.system;
     username = hostConfig.username;
   };
   ```

2. **Use hostSystem in modules**
   ```nix
   {
     hostSystem,
     lib,
     ...
   }: let
     isDarwin = lib.strings.hasSuffix "darwin" hostSystem;
   in { ... }
   ```

3. **Import modules unconditionally**
   ```nix
   imports = [
     ./module-a.nix
     ./module-b.nix
   ];
   ```

4. **Use mkIf inside modules**
   ```nix
   config = mkIf cfg.enable {
     # Configuration here
   };
   ```

### DON'T ❌

1. **Don't access config in let bindings at top level**
   ```nix
   # ❌ BAD
   let
     mySystem = config.host.system;
   in { ... }
   ```

2. **Don't use pkgs.stdenv for platform detection**
   ```nix
   # ❌ BAD
   systemd.services.foo = lib.mkIf pkgs.stdenv.isLinux { ... };
   
   # ✅ GOOD
   systemd.services.foo = lib.mkIf isLinux { ... };
   ```

3. **Don't use conditional imports with config**
   ```nix
   # ❌ BAD
   imports = lib.optionals config.host.features.foo.enable [ ./foo.nix ];
   
   # ✅ GOOD
   imports = [ ./foo.nix ];  # foo.nix uses mkIf internally
   ```

4. **Don't access config.nixpkgs.hostPlatform early**
   ```nix
   # ❌ BAD
   let
     system = config.nixpkgs.hostPlatform.system;
   ```

## Testing

After making these changes, verify with:
```bash
# Dry run
nix build --dry-run '.#darwinConfigurations.HOSTNAME.system'

# Or for NixOS
nix build --dry-run '.#nixosConfigurations.HOSTNAME.system'

# Full rebuild
darwin-rebuild switch --flake .
# or
nixos-rebuild switch --flake .
```

## Why This Matters

The Nix module system evaluates modules in phases:
1. Import all modules
2. Process module arguments
3. Merge all module options
4. Evaluate config values
5. Check assertions

When you access `config` or `pkgs` in steps 1-3, you create a circular dependency because those values depend on completing steps 3-4 first.

Using `specialArgs` provides values that are available from step 2 onward, breaking the cycle.

## Additional Notes

- String interpolation in shell scripts is fine (e.g., `"${config.host.system}"` in a writeShellScript)
- The error message "noting that argument `X` is not externally provided, so querying `_module.args` instead, requiring `config`" is the key indicator
- Always check the stack trace for "while evaluating definitions from" to find the problematic module
