# Contributing to Nix Configuration

Thank you for your interest in contributing! This guide will help you understand the codebase structure, conventions, and best practices.

## Table of Contents

- [Getting Started](#getting-started)
- [Code Organization](#code-organization)
- [Coding Standards](#coding-standards)
- [Adding Features](#adding-features)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Common Tasks](#common-tasks)

## Getting Started

### Prerequisites

- Nix with flakes enabled
- Git
- Familiarity with Nix language and NixOS/nix-darwin
- Understanding of Home Manager (optional but helpful)

### Initial Setup

```bash
# Clone the repository
git clone <repository-url> ~/.config/nix
cd ~/.config/nix

# Verify the flake is valid
nix flake check

# Build a configuration to test
nix build .#darwinConfigurations.Lewiss-MacBook-Pro.system  # macOS
nix build .#nixosConfigurations.jupiter.config.system.build.toplevel  # Linux
```

### Development Workflow

1. Create a feature branch: `git checkout -b feature/my-feature`
2. Make your changes following the standards below
3. Test your changes (see [Testing](#testing))
4. Commit with clear messages (see [Commit Messages](#commit-messages))
5. Submit a pull request (if applicable)

## Code Organization

Our configuration follows a hierarchical structure:

```
.
├── flake.nix              # Main flake entry point
├── hosts/                 # Host-specific configurations
├── modules/               # System-level modules
│   ├── shared/            # Cross-platform
│   ├── darwin/            # macOS-specific
│   └── nixos/             # Linux-specific
├── home/                  # Home Manager configurations
│   ├── common/            # Cross-platform user configs
│   ├── darwin/            # macOS user configs
│   └── nixos/             # Linux user configs
├── lib/                   # Helper functions and builders
├── overlays/              # Nixpkgs overlays
└── docs/                  # Documentation
```

See [`modules/INDEX.md`](modules/INDEX.md) for a complete module reference.

## Coding Standards

### 1. Import Patterns

**Standard:** Directories without `.nix`, files with `.nix`

```nix
# ✅ Correct
imports = [
  ./apps          # Directory
  ./git.nix       # File
  ./development   # Directory
];

# ❌ Incorrect
imports = [
  ./apps.nix      # Directory should not have .nix
  ./git           # File should have .nix
];
```

### 2. Formatting

We use **Alejandra** for consistent formatting:

```bash
# Format all files
nix fmt

# Format specific file
alejandra path/to/file.nix
```

### 3. Code Style

#### Indentation
- Use 2 spaces for indentation
- No tabs

#### Attribute Sets
```nix
# ✅ Good - aligned and readable
{
  enable = true;
  package = pkgs.myPackage;
  settings = {
    option1 = "value";
    option2 = 42;
  };
}

# ❌ Bad - inconsistent alignment
{
  enable=true;
    package= pkgs.myPackage;
  settings={option1="value"; option2=42;};
}
```

#### Let Bindings
```nix
# ✅ Good - organized and clear
let
  cfg = config.programs.myProgram;
  inherit (lib) mkIf mkEnableOption;
  myHelper = x: x + 1;
in {
  options = { ... };
  config = mkIf cfg.enable { ... };
}
```

#### Comments
```nix
# Single-line comments for brief explanations
programs.git.enable = true;  # Enable Git

# Multi-line comments for complex logic
# This configuration enables the gaming feature which includes:
# - Steam with Proton support
# - GameMode for performance optimization
# - GPU drivers with 32-bit support
features.gaming.enable = true;
```

### 4. Module Structure

Every module should follow this structure:

```nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.myFeature;
  inherit (lib) mkIf mkEnableOption mkOption types;
in {
  # Options definition
  options.programs.myFeature = {
    enable = mkEnableOption "my feature";
    
    package = mkOption {
      type = types.package;
      default = pkgs.myPackage;
      description = "Package to use";
    };
    
    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Configuration settings";
    };
  };

  # Configuration implementation
  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    
    programs.myFeature = {
      settings = cfg.settings;
    };
  };
}
```

### 5. Package Organization

When adding packages, organize them by category:

```nix
home.packages = with pkgs;
  # Development tools
  [
    git
    gh
    direnv
  ]
  # System utilities
  ++ [
    htop
    btop
    ripgrep
  ]
  # Platform-specific
  ++ platformLib.platformPackages
    [ /* Linux */ ]
    [ /* Darwin */ ];
```

### 6. Feature Flags

Use feature flags for toggleable functionality:

```nix
# In module
{
  options.features.gaming = lib.mkEnableOption "gaming support";
  
  config = lib.mkIf config.features.gaming.enable {
    programs.steam.enable = true;
  };
}

# In host config
features.gaming.enable = true;
```

See [`docs/guides/feature-flags.md`](docs/guides/feature-flags.md) for details.

### 7. Naming Conventions

- **Files**: `kebab-case.nix` (e.g., `my-feature.nix`)
- **Directories**: `kebab-case` (e.g., `my-feature/`)
- **Attributes**: `camelCase` (e.g., `myFeature`)
- **Options**: `dot.notation` (e.g., `programs.myFeature.enable`)
- **Variables**: `camelCase` (e.g., `myVariable`)

## Adding Features

### Adding a New Module

1. **Choose location:**
   - System-level: `modules/{shared,darwin,nixos}/`
   - User-level: `home/{common,darwin,nixos}/`

2. **Create module file:**
```nix
# modules/nixos/my-feature.nix
{config, lib, pkgs, ...}: {
  options.features.myFeature = {
    enable = lib.mkEnableOption "my feature";
  };
  
  config = lib.mkIf config.features.myFeature.enable {
    # Implementation
  };
}
```

3. **Add to parent default.nix:**
```nix
{...}: {
  imports = [
    ./my-feature.nix
  ];
}
```

4. **Update module index:**
   - Add entry to [`modules/INDEX.md`](modules/INDEX.md)
   - Include description and status

5. **Test:**
```bash
nix flake check
nix build .#nixosConfigurations.jupiter.config.system.build.toplevel
```

### Adding a New Package

1. **For user packages:**
   Add to `home/common/apps/packages.nix` in the appropriate category

2. **For system packages:**
   Add to the relevant module in `modules/`

3. **For custom packages:**
   Create in `pkgs/` and add an overlay in `overlays/`

### Adding an Overlay

1. **Create overlay file:**
```nix
# overlays/my-package.nix
{inputs}: final: prev: {
  my-package = prev.callPackage ../pkgs/my-package {};
}
```

2. **It's automatically included!**
   The `overlays/default.nix` imports all overlays.

### Adding a New Host

1. **Create host directory:**
```bash
mkdir hosts/my-host
```

2. **Create configuration files:**
```nix
# hosts/my-host/default.nix
{
  username = "myuser";
  useremail = "my@email.com";
  system = "x86_64-linux";  # or "aarch64-darwin"
  hostname = "my-host";
}
```

```nix
# hosts/my-host/configuration.nix
{...}: {
  imports = [
    # ./hardware-configuration.nix  # For NixOS
  ];
  
  # Host-specific config
}
```

3. **Register in `lib/hosts.nix`:**
```nix
hosts = {
  my-host = import ../hosts/my-host;
  # ... other hosts
};
```

## Testing

### Before Committing

Run these checks:

```bash
# 1. Format check
nix fmt

# 2. Flake validation
nix flake check

# 3. Build configurations
nix build .#darwinConfigurations.Lewiss-MacBook-Pro.system
nix build .#nixosConfigurations.jupiter.config.system.build.toplevel

# 4. Verify no temporary files
find . -name "*.tmp" -type f

# 5. Run linters (if configured)
statix check .
deadnix .
```

### Testing Changes Locally

```bash
# For NixOS
sudo nixos-rebuild test --flake .#my-host

# For nix-darwin
darwin-rebuild check --flake .#my-host

# For Home Manager only
home-manager switch --flake .#my-host
```

### Validation Helpers

Use the validation library:

```nix
let
  validation = import ./lib/validation.nix {inherit lib pkgs;};
  hostCheck = validation.validateHostConfig myHostConfig;
in
  assert hostCheck.status == "pass"; myHostConfig
```

## Submitting Changes

### Commit Messages

Follow this format:

```
type: brief description (50 chars max)

Detailed explanation if needed (wrap at 72 chars):
- What changed
- Why it changed
- Any breaking changes

Refs: #issue-number
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code restructuring
- `docs`: Documentation changes
- `style`: Formatting changes
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**

```
feat: add gaming feature module with Steam support

- Add gaming.nix module for NixOS
- Include Steam, GameMode, and Proton support
- Add feature flag: features.gaming.enable
- Update module index with gaming entry

Refs: #123
```

```
refactor: reorganize system modules by category

- Create nix/, integration/, maintenance/ subdirs
- Move files to logical locations
- Update imports in default.nix
- Delete empty file-management.nix

This improves discoverability and reduces the catch-all
nature of the system/ directory.
```

### Pre-commit Hooks

We use pre-commit hooks for:
- `alejandra` - Code formatting
- `deadnix` - Dead code detection
- `statix` - Linting

Install with:
```bash
pre-commit install  # If using pre-commit framework
```

Or just run manually:
```bash
alejandra .
deadnix .
statix check .
```

## Common Tasks

### Adding a System Package

```nix
# modules/shared/packages.nix
environment.systemPackages = with pkgs; [
  # Add your package here
  myNewPackage
];
```

### Adding a User Package

```nix
# home/common/apps/packages.nix
home.packages = with pkgs;
  # System utilities
  [
    myNewPackage  # Add here
  ]
```

### Enabling a Feature

```nix
# hosts/my-host/configuration.nix
features = {
  gaming.enable = true;
  development.enable = true;
};
```

### Adding a Development Shell

```nix
# shells/my-language.nix
{pkgs}: {
  buildInputs = with pkgs; [
    # Development tools
  ];
  
  shellHook = ''
    echo "Welcome to my development shell!"
  '';
}
```

### Creating a Custom Package

```nix
# pkgs/my-package/default.nix
{
  lib,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation rec {
  pname = "my-package";
  version = "1.0.0";
  
  src = fetchFromGitHub {
    owner = "owner";
    repo = "repo";
    rev = "v${version}";
    sha256 = "...";
  };
  
  meta = with lib; {
    description = "My awesome package";
    license = licenses.mit;
    maintainers = [maintainers.yourname];
  };
}
```

## Getting Help

- **Module Index**: [`modules/INDEX.md`](modules/INDEX.md)
- **Architecture Docs**: [`docs/reference/architecture.md`](docs/reference/architecture.md)
- **Feature Flags**: [`docs/guides/feature-flags.md`](docs/guides/feature-flags.md)
- **Directory Structure**: [`docs/reference/directory-structure.md`](docs/reference/directory-structure.md)

## Resources

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nix Pills](https://nixos.org/guides/nix-pills/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Darwin Manual](https://daiderd.com/nix-darwin/manual/)

---

**Remember:** Always test your changes before committing, and maintain the high standards established in this configuration. Quality over speed!

Thank you for contributing! 🎉
