# Module Override Patterns

This document explains the module override patterns and priority system used in this Nix configuration repository. Understanding these priorities is crucial for managing how different modules interact and ensuring that configuration values are merged correctly.

## The NixOS Priority System

In the NixOS module system, every option definition has a priority. When multiple modules define the same option, the definition with the **lowest priority number** wins.

If multiple definitions have the *same* priority, they are usually merged (for lists/sets) or cause a conflict error (for simple values), unless one is specifically designed to override the others.

### Standard Priorities

| Priority Value | Helper Function | Description |
| :--- | :--- | :--- |
| **40** | `lib.mkOverride 40` | **High Priority Tuning**. Used in this repo for critical kernel parameters (e.g., `disk-performance.nix`) to ensure they override even `mkForce`. |
| **50** | `lib.mkForce` | **Force Override**. Used to forcibly override standard configuration. Use sparingly. |
| **60** | `lib.mkOverride 60` | **High Priority Default**. Stronger than standard, weaker than force. Used for specialized feature defaults (e.g., gaming limits). |
| **100** | (None) | **Standard Definition**. The default priority when you just write `option = value;`. |
| **1000** | `lib.mkDefault` | **Default Value**. Weakest priority. Used for providing fallback values that users can easily override. |

## Usage Guidelines

### 1. `lib.mkDefault` (Priority 1000)

**When to use:**

- Setting default values in reusable modules (`modules/`).
- Defining "sane defaults" that you expect might be changed by host-specific config (`hosts/`).
- Feature flags enabling/disabling other sub-features.

**Example:**

```nix
# modules/shared/core.nix
system.stateVersion = lib.mkDefault platformLib.platformStateVersion;
```

### 2. Standard Definition (Priority 100)

**When to use:**

- In `hosts/<hostname>/configuration.nix` when you want to set the final value.
- When a module *must* set a value for it to work correctly, and it shouldn't be overridden easily.

**Example:**

```nix
# hosts/jupiter/configuration.nix
networking.hostName = "jupiter";
```

### 3. `lib.mkForce` (Priority 50)

**When to use:**

- **Workarounds:** Fixing upstream bugs or weird behaviors where a standard setting isn't enough.
- **State Reset:** Clearing a list or set defined elsewhere (e.g., `services.displayManager.sessionPackages = lib.mkForce [ ];`).
- **Tests:** Forcing configuration in test VMs (e.g., disabling bootloaders).

**Example:**

```nix
# modules/darwin/nix.nix
# Determinate Nix owns the daemon, so we force nix-darwin to disable its management
nix.enable = lib.mkForce false;
```

### 4. Custom Priorities (`mkOverride <n>`)

**When to use:**

- **System Tuning:** When you have a module specifically for performance tuning that should take precedence over standard service modules.
- **Priority Resolution:** When two modules conflict at standard priority (100) and you want one to win without using `mkForce`.

**Example:**

```nix
# modules/nixos/system/disk-performance.nix
# We want these performance tweaks to apply even if other modules set them
"vm.swappiness" = lib.mkOverride 40 10;
```

## Common Patterns in This Repository

### The "Feature Flag" Pattern

We use `mkDefault` heavily in feature modules to allow enabling/disabling components while preserving user overrides.

```nix
# home/common/apps/bat.nix
programs.bat = {
  enable = true;
  config.theme = lib.mkDefault "base16"; # User can override this in their home config
};
```

### The "Performance Tuning" Pattern

We use `mkOverride 40` for `disk-performance.nix`. This ensures that if we enable the disk performance module, its sysctl settings take precedence over defaults set by other modules (like gaming or standard system modules).

### The "Test VM" Pattern

In `tests/lib/vm-base.nix`, we use `mkForce` to strip down the system for testing:

```nix
boot.loader.systemd-boot.enable = lib.mkForce false;
services.xserver.enable = lib.mkForce false;
```

## Debugging Overrides

If you are unsure which value is winning or why, use `nixos-option` (on NixOS) or `nix repl`.

### Using `nixos-option`

```bash
nixos-option services.sonarr.package
```

This will show the current value, default value, and where it is defined.

### Using `nix repl`

```bash
nix repl
# Load the flake
:lf .
# Inspect a host's configuration
nixosConfigurations.jupiter.config.services.sonarr.package
```

To see definitions and priorities:

```bash
nixosConfigurations.jupiter.options.services.sonarr.package.definitions
```

This lists all files defining the option and their priority values.
