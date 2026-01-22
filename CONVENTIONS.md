# Nix Configuration Coding Conventions

This document defines the coding standards and conventions for this Nix configuration repository. It is used by multiple AI coding assistants (Aider, Cursor, Cline, etc.) to ensure consistent code quality.

## Module Organization Principles

### System vs Home-Manager Separation

**System-Level Modules** (`modules/nixos/` or `modules/darwin/`):

Required when configuration needs:
- System services (systemd, launchd)
- Kernel modules and drivers
- Hardware configuration
- Root-level daemons
- Container runtime daemons (Docker, Podman)
- Graphics drivers and system libraries
- Network configuration
- Boot loaders

**Home-Manager Modules** (`home/common/apps/` or `home/{nixos,darwin}/`):

Required for:
- User applications and CLI tools
- User-level systemd services
- Dotfiles and shell configuration
- Development tools (LSPs, formatters, linters)
- Desktop applications
- User tray applets
- Editor and terminal configurations

### Directory Structure

```
modules/
├── nixos/
│   ├── features/      # System-level features
│   ├── services/      # System services
│   └── hardware/      # Hardware configuration
├── darwin/            # macOS system config
└── shared/
    └── features/      # Cross-platform features

home/
├── common/
│   └── apps/         # Cross-platform user apps
├── nixos/
│   └── apps/         # Linux-specific user apps
└── darwin/
    └── apps/         # macOS-specific user apps
```

## Code Style Requirements

### 1. Never Use `with pkgs;`

This is a critical antipattern that reduces code clarity and makes it harder to track dependencies.

```nix
# ❌ WRONG - Antipattern
home.packages = with pkgs; [ curl wget tree ];

# ✅ CORRECT - Modern pattern
home.packages = [ pkgs.curl pkgs.wget pkgs.tree ];
```

### 2. Use Constants from `lib/constants.nix`

Never hardcode ports, paths, or other magic values.

```nix
# ❌ WRONG
services.myapp.port = 8080;
time.timeZone = "Europe/London";

# ✅ CORRECT
let
  constants = import ../lib/constants.nix;
in
{
  services.myapp.port = constants.ports.services.myapp;
  # Use per-host configuration for timezone
}
```

### 3. Use Validators for Assertions

Import validators from `lib/validators.nix` for common checks:

```nix
let
  validators = import ../lib/validators.nix { inherit lib; };
in
{
  assertions = [
    (validators.assertValidPort cfg.port "service-name")
  ];
}
```

### 4. Module Options Pattern

When creating modules, follow this structure:

```nix
{ config, lib, pkgs, ... }:

let
  cfg = config.features.myFeature;
in
{
  options.features.myFeature = {
    enable = lib.mkEnableOption "my feature";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.myPackage;
      description = "The package to use for my feature";
    };
  };

  config = lib.mkIf cfg.enable {
    # Configuration here
  };
}
```

## Git Commit Conventions

Follow conventional commits format (see `docs/DX_GUIDE.md`):

- `feat:` - New feature
- `fix:` - Bug fix
- `refactor:` - Code refactoring
- `docs:` - Documentation changes
- `test:` - Test additions or changes
- `chore:` - Build/tooling changes

Examples:
```
feat(audio): add PipeWire support for audio routing
fix(modules): correct home-manager module placement
refactor(features): simplify gaming feature configuration
docs(guides): update qBittorrent setup instructions
```

## Common Antipatterns to Avoid

### ❌ Container Tools in Home-Manager

```nix
# ❌ WRONG - Don't do this
home.packages = [ pkgs.podman pkgs.podman-compose ];
```

**Fix**: Container runtimes belong at system-level in `modules/nixos/features/virtualisation.nix`.

### ❌ System Packages in Home Config

```nix
# ❌ WRONG - Don't do this
home.packages = [ pkgs.vulkan-tools pkgs.mesa-demos ];
```

**Fix**: Graphics libraries should only be in system config.

### ❌ Hardcoded Values

```nix
# ❌ WRONG - Don't do this
time.timeZone = "Europe/London";
services.jellyfin.port = 8096;
```

**Fix**: Use per-host configuration or constants from `lib/constants.nix`.

### ❌ Duplicate Package Declarations

```nix
# ❌ WRONG - Package appears in both system and home
environment.systemPackages = [ pkgs.git ];
home.packages = [ pkgs.git ];
```

**Fix**: Choose one location based on whether it's a system requirement or user tool.

## Code Formatting

All `.nix` files must be formatted before committing:

```bash
# Format specific file
nix fmt path/to/file.nix

# Format entire project
treefmt
```

The project uses automated formatting hooks that will format code after edits.

## Testing and Validation

### Before Committing

1. **Format code**: Run `nix fmt` or `treefmt`
2. **Validate flake**: Run `nix flake check`
3. **Test build**: Test your changes in a VM or on target system
4. **Review diff**: Check `git diff` for unintended changes

### Never Run Without Permission

**CRITICAL**: Never run these commands directly:
- `nh os switch`
- `sudo nixos-rebuild switch`
- `sudo darwin-rebuild switch`
- `rm -rf` in system directories
- `sudo rm`

Always suggest these commands for the user to run manually.

## Documentation Requirements

When adding new features or modules:

1. **Add module documentation** in the options using `description`
2. **Update relevant docs** in `docs/` directory
3. **Add examples** if the feature is complex
4. **Update CLAUDE.md** if AI behavior should change

## File Headers

Nix modules should include clear comments:

```nix
# Module: features.audio.pipewire
# Description: Configures PipeWire audio server with pro audio support
# Location: modules/nixos/features/audio/pipewire.nix
```

## Import Patterns

Use explicit imports:

```nix
{ config, lib, pkgs, ... }:

let
  constants = import ../lib/constants.nix;
  validators = import ../lib/validators.nix { inherit lib; };
  cfg = config.features.myFeature;
in
{
  # Module definition
}
```

## Decision-Making Guidelines

When uncertain about placement or structure:

1. **Check existing patterns** in the codebase
2. **Reference architecture docs** in `docs/reference/architecture.md`
3. **Follow feature patterns** in `docs/FEATURES.md`
4. **Use scaffolding tools**: `nix run .#new-module`
5. **Ask for clarification** rather than making assumptions

## Resources

- **Architecture Guide**: `docs/reference/architecture.md`
- **Feature Patterns**: `docs/FEATURES.md`
- **DX Guide**: `docs/DX_GUIDE.md`
- **Refactoring Examples**: `docs/reference/REFACTORING_EXAMPLES.md`
- **AI Guidelines**: `CLAUDE.md`
