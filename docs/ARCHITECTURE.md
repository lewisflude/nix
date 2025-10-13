# Configuration Architecture

## Overview

This Nix configuration follows a modular, feature-based architecture optimized for:
- **Performance** - Selective overlays, optimized builds
- **Correctness** - Type-safe options, validation
- **Maintainability** - Clear structure, consistent patterns
- **Latest versions** - Automated updates, minimal version pinning

## Architecture Diagram

```
flake.nix (minimal, delegates to lib/)
    │
    ├─→ lib/default.nix (main entry point)
    │       ├─→ hosts.nix (host definitions)
    │       ├─→ system-builders.nix (Darwin/NixOS builders)
    │       ├─→ output-builders.nix (formatters, checks, devShells)
    │       ├─→ functions.nix (utility functions)
    │       └─→ validation.nix (validation helpers)
    │
    ├─→ hosts/<hostname>/
    │       ├─→ default.nix (host config: username, features)
    │       └─→ configuration.nix (system-specific settings)
    │
    ├─→ modules/
    │       ├─→ shared/ (cross-platform)
    │       │       ├─→ core.nix
    │       │       ├─→ host-options.nix (option schema)
    │       │       └─→ features/ (development, security, etc.)
    │       ├─→ darwin/ (macOS-specific)
    │       └─→ nixos/ (Linux-specific)
    │               ├─→ features/ (gaming, audio, etc.)
    │               ├─→ core/
    │               ├─→ desktop/
    │               ├─→ hardware/
    │               └─→ services/
    │
    ├─→ home/ (Home Manager configs)
    │       ├─→ common/profiles/ (desktop, minimal)
    │       ├─→ darwin/ (macOS-specific)
    │       └─→ nixos/ (Linux-specific)
    │
    └─→ overlays/
            ├─→ default.nix (organized by priority)
            ├─→ cursor.nix, ghostty.nix, etc.
            └─→ Platform-conditional application
```

## Key Design Principles

### 1. Minimal Flake Surface

**flake.nix** is intentionally minimal - it only:
- Declares inputs
- Delegates outputs to `lib/default.nix`

This keeps the flake clean and moves complexity to maintainable library code.

```nix
# flake.nix
{
  inputs = { ... };
  outputs = inputs @ {self, ...}: import ./lib {inherit inputs self;};
}
```

### 2. Feature-Based Configuration

Instead of monolithic configs, functionality is opt-in via features:

```nix
# hosts/jupiter/default.nix
{
  hostname = "jupiter";
  features = {
    development.enable = true;
    gaming.enable = true;
    virtualisation.docker = true;
  };
}
```

Features are:
- **Type-safe** - Defined in `host-options.nix`
- **Validated** - Assertions catch invalid configs
- **Platform-aware** - Automatically disabled on unsupported platforms

### 3. Overlay Optimization

Overlays are organized by priority and conditionally applied:

```nix
# overlays/default.nix
{
  # Core (always applied)
  unstable = final: prev: { ... };
  
  # Platform-specific (conditional)
  ghostty = mkConditional isDarwin ghosttyOverlay;
  niri = mkConditional isLinux niriOverlay;
}
```

Benefits:
- Faster evaluation (no-op overlays for wrong platform)
- Clearer dependencies
- Easy to debug ("which overlays are active?")

### 4. Minimal specialArgs

Only essential data passed via `specialArgs`:

```nix
# system-builders.nix
specialArgs = {
  inherit inputs;  # Only when modules need flake inputs
  keysDirectory = "${self}/keys";  # NixOS only
};
```

Host configuration passed via module system:

```nix
modules = [
  { config.host = hostConfig; }  # Type-safe, validated
  # ...
];
```

### 5. Clear Module Hierarchy

```
modules/shared/     → Cross-platform (Darwin + NixOS)
modules/darwin/     → macOS-specific
modules/nixos/      → Linux-specific
  └─ features/      → Optional features
```

Each module:
- Declares its options
- Implements its config
- Uses feature flags for conditional logic

## Data Flow

### Host Configuration → System Build

1. **Host definition** (`hosts/jupiter/default.nix`)
   ```nix
   {
     username = "lewis";
     hostname = "jupiter";
     system = "x86_64-linux";
     features.gaming.enable = true;
   }
   ```

2. **System builder** validates and injects into module system:
   ```nix
   { config.host = hostConfig; }
   ```

3. **Feature modules** consume via options:
   ```nix
   config = mkIf config.host.features.gaming.enable {
     programs.steam.enable = true;
   };
   ```

### Overlay Application

1. **Request overlays** (`modules/shared/overlays.nix`)
2. **Overlay builder** (`overlays/default.nix`) returns platform-appropriate set
3. **Applied** via `nixpkgs.overlays`
4. **Result**: Platform-optimized package set

## Testing Strategy

### Three Levels of Testing

1. **Evaluation** - Does it parse and evaluate?
   ```bash
   nix flake check
   ```

2. **Build** - Does it build without errors?
   ```bash
   nix build .#nixosConfigurations.jupiter.config.system.build.toplevel
   ```

3. **Integration** - Does it work in a VM?
   ```bash
   nix build .#checks.x86_64-linux.development
   ```

### Continuous Validation

- **Pre-commit hooks** - Format and lint before commit
- **CI** - Validate on push
- **Automated updates** - Weekly flake update with validation

## Update Strategy

### Staying on Latest

1. **No version pinning** - Inputs track latest branches
   ```nix
   nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
   # Not: github:NixOS/nixpkgs/abc123def
   ```

2. **Automated updates** - CI creates PR weekly
   ```yaml
   # .github/workflows/update-flake.yml
   on:
     schedule:
       - cron: '0 9 * * 1'  # Monday 9am
   ```

3. **Manual updates**
   ```bash
   ./scripts/maintenance/update-flake.sh
   ```

### Update Process

1. Run `nix flake update`
2. Validate with `nix flake check`
3. Build test configurations
4. Create PR for review
5. Test on actual hardware
6. Merge and deploy

## Performance Optimizations

### Build Performance

1. **Selective overlays** - Only apply what's needed for the platform
2. **Minimal inputs** - Don't pass entire `inputs` everywhere
3. **Lazy evaluation** - Feature configs only eval if enabled
4. **Binary caches** - Use cachix for common packages

### Evaluation Performance

1. **Avoid IFD** - No import-from-derivation
2. **Pure evaluation** - No filesystem reads during eval
3. **Structured modules** - Clear import hierarchy

### Rebuild Performance

1. **Isolated changes** - Modifying one feature doesn't rebuild everything
2. **Smart overlays** - Platform-specific overlays don't affect other platform
3. **Cached builds** - Determinate Systems cache for faster builds

## Extension Points

### Adding a New Host

1. Create `hosts/<hostname>/default.nix`:
   ```nix
   {
     username = "user";
     hostname = "machine";
     system = "x86_64-linux";
     features = { ... };
   }
   ```

2. Create `hosts/<hostname>/configuration.nix` for system-specific settings

3. Add to `lib/hosts.nix`:
   ```nix
   hosts = {
     machine = import ../hosts/machine;
   };
   ```

4. Build: `nix build .#nixosConfigurations.machine.config.system.build.toplevel`

### Adding a New Feature

1. Define option in `modules/shared/host-options.nix`
2. Create feature module
3. Import in appropriate `default.nix`
4. Use in host config
5. Test with `nix flake check`

### Adding a New Overlay

1. Create overlay file in `overlays/`
2. Add to `overlays/default.nix`
3. Mark platform-specific if needed
4. Test builds on both platforms

## Troubleshooting

### Build Failures

```bash
# Check what changed
git diff flake.lock

# Validate configuration
nix flake check --verbose

# Build specific host
nix build .#nixosConfigurations.jupiter.config.system.build.toplevel --show-trace
```

### Feature Issues

```bash
# Check if feature is enabled
nix eval .#nixosConfigurations.jupiter.config.host.features.gaming.enable

# See what packages a feature adds
nix eval .#nixosConfigurations.jupiter.config.environment.systemPackages --apply 'x: map (p: p.name or "?") x'
```

### Overlay Debugging

```bash
# Check active overlays
nix repl
:lf .
outputs.nixosConfigurations.jupiter.config._module.args.overlayInfo

# Test specific overlay
nix eval .#nixosConfigurations.jupiter.pkgs.cursor.version
```

## Migration from Old Structure

Old structure → New structure:

1. **lib/features.nix** → Deleted (unused)
2. **Direct host attrs** → `config.host = { ... }`
3. **inputs everywhere** → Minimal `specialArgs`
4. **Global overlays** → Platform-conditional
5. **Mixed modules** → Clear shared/darwin/nixos split

## Further Reading

- [Module Organization](../modules/README.md)
- [Contributing Guide](../CONTRIBUTING.md)
- [Quick Reference](../QUICK_REFERENCE.md)
