# Component Extraction Implementation Guide

A comprehensive guide for extracting components from this Nix configuration and releasing them as standalone open-source projects.

**Version**: 1.0
**Last Updated**: 2026-01-16
**Target Audience**: Engineers, maintainers, contributors

---

## Table of Contents

1. [Pre-Extraction Assessment](#1-pre-extraction-assessment)
2. [Repository Setup & Structure](#2-repository-setup--structure)
3. [Code Extraction & Refactoring](#3-code-extraction--refactoring)
4. [Documentation Requirements](#4-documentation-requirements)
5. [Testing & CI/CD Setup](#5-testing--cicd-setup)
6. [Licensing & Legal Considerations](#6-licensing--legal-considerations)
7. [Release Process](#7-release-process)
8. [Community Engagement](#8-community-engagement)
9. [Post-Launch Maintenance](#9-post-launch-maintenance)
10. [Appendices](#10-appendices)

---

## 1. Pre-Extraction Assessment

Before beginning extraction, complete this assessment to ensure the component is ready for public release.

### 1.1 Readiness Checklist

**Technical Readiness**:
- [ ] Component is well-defined with clear boundaries
- [ ] Code is reasonably modular and can be extracted
- [ ] No hard dependencies on other private code
- [ ] No embedded secrets or sensitive information
- [ ] Works on target platforms (NixOS, Darwin, or both)
- [ ] Has been tested in production (your own config)

**Value Proposition**:
- [ ] Solves a real problem for others
- [ ] No existing solution, or significantly better than alternatives
- [ ] Target audience identified and validated
- [ ] Unique value clearly articulated

**Maintenance Commitment**:
- [ ] Willing to maintain for at least 6-12 months
- [ ] Time available for initial release work (20-40 hours)
- [ ] Plan for handling issues and PRs
- [ ] Exit strategy if maintenance becomes unsustainable

### 1.2 Scope Definition

Document the exact scope of what you're extracting:

```markdown
## Component Scope

**Name**: [Component name]
**Type**: [Home Manager module / NixOS module / Package / Tool / Theme]
**Purpose**: [One-sentence description]

### Included
- [List specific files/modules being extracted]
- [Features being included]
- [Dependencies being bundled]

### Excluded
- [User-specific configuration]
- [Private utilities]
- [Experimental features]

### Dependencies
- **Nix**: [Minimum version]
- **NixOS**: [Version compatibility] (if applicable)
- **Home Manager**: [Version compatibility] (if applicable)
- **External packages**: [List with versions]
```

### 1.3 Audience Research

**Primary Audience**: [Who will use this?]
- Nix experience level: [Beginner / Intermediate / Advanced]
- Common use cases: [List 3-5 scenarios]
- Pain points solved: [What problems does this address?]

**Secondary Audiences**: [Who else might benefit?]

**Community Validation**:
- [ ] Discussed in Matrix/Discord channels
- [ ] Posted "would this be useful?" poll on Discourse
- [ ] Reviewed similar projects for gaps
- [ ] Confirmed no duplicate effort underway

---

## 2. Repository Setup & Structure

### 2.1 Repository Creation

**Platform**: GitHub (recommended for Nix ecosystem)

**Repository Name Guidelines**:
- Use lowercase with hyphens: `my-project-name`
- Descriptive and searchable
- Include relevant keywords: `nix`, `nixos`, `home-manager`, `flake`
- Avoid generic names

**Examples**:
- ✅ `mcp-home-manager` (clear, specific)
- ✅ `ironbar-signal-theme` (descriptive)
- ✅ `protonvpn-portforward-nix` (platform-specific)
- ❌ `utils` (too generic)
- ❌ `my-configs` (not descriptive)

### 2.2 Flake Structure

Use the **[Blueprint](https://github.com/numtide/blueprint)** pattern for scalable projects, or a simpler structure for smaller projects.

#### Option A: Simple Structure (Small Projects)

```
my-project/
├── flake.nix                 # Main flake definition
├── flake.lock               # Locked dependencies
├── README.md                # Project documentation
├── LICENSE                  # License file
├── CHANGELOG.md             # Version history
├── .github/
│   └── workflows/
│       └── ci.yml           # CI/CD pipeline
├── modules/
│   ├── default.nix          # Main module
│   └── options.nix          # Option definitions (if complex)
├── packages/
│   └── default.nix          # Package definitions
├── tests/
│   └── basic.nix            # Basic tests
├── examples/
│   ├── basic.nix            # Simple example
│   └── advanced.nix         # Advanced example
└── docs/
    ├── installation.md      # Installation guide
    ├── configuration.md     # Configuration guide
    └── troubleshooting.md   # Common issues
```

#### Option B: Blueprint Structure (Large Projects)

Following the [Blueprint](https://github.com/numtide/blueprint) pattern:

```
my-project/
├── flake.nix                # Uses blueprint library
├── flake.lock
├── README.md
├── LICENSE
├── CHANGELOG.md
├── .github/
│   └── workflows/
│       └── ci.yml
├── apps/                    # Maps to flake.apps
│   └── default.nix
├── checks/                  # Maps to flake.checks
│   ├── format.nix
│   └── tests.nix
├── devshells/               # Maps to flake.devShells
│   └── default.nix
├── homeModules/             # Maps to flake.homeModules
│   ├── default.nix
│   └── my-module/
│       ├── default.nix
│       └── options.nix
├── nixosModules/            # Maps to flake.nixosModules
│   └── default.nix
├── packages/                # Maps to flake.packages
│   └── default.nix
├── overlays/                # Maps to flake.overlays
│   └── default.nix
├── templates/               # Maps to flake.templates
│   └── basic/
│       ├── flake.nix
│       └── README.md
├── examples/
│   ├── basic.nix
│   └── advanced.nix
└── docs/
    ├── installation.md
    ├── configuration.md
    └── api-reference.md
```

**Blueprint Advantages**:
- Automatic flake output mapping
- Reduces boilerplate by 99%
- Standard structure familiar to community
- Easier to maintain as project grows

### 2.3 Flake Template

#### Simple Flake (Recommended for First Release)

```nix
{
  description = "Brief description of your project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # For Home Manager modules
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        # Packages
        packages = {
          default = self.packages.${system}.my-package;
          my-package = pkgs.callPackage ./packages/default.nix { };
        };

        # Development shell
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nixpkgs-fmt
            statix
            deadnix
            nil
          ];
        };

        # Checks (run with `nix flake check`)
        checks = {
          format = pkgs.runCommand "check-format" { } ''
            ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt --check ${./.}
            touch $out
          '';
        };

        # Formatters (run with `nix fmt`)
        formatter = pkgs.nixpkgs-fmt;
      }
    ) // {
      # Home Manager module
      homeManagerModules = {
        default = self.homeManagerModules.my-module;
        my-module = import ./modules/default.nix;
      };

      # NixOS module
      nixosModules = {
        default = self.nixosModules.my-module;
        my-module = import ./modules/default.nix;
      };
    };
}
```

#### Blueprint-Based Flake

```nix
{
  description = "Brief description of your project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: inputs.blueprint { prefix = ""; };
}
```

**Note**: Blueprint automatically maps folders to flake outputs. See the [Blueprint documentation](https://github.com/numtide/blueprint) for details.

### 2.4 Initial Files

**Required Files**:
1. **README.md** - See [Section 4.1](#41-readme-structure)
2. **LICENSE** - See [Section 6](#6-licensing--legal-considerations)
3. **flake.nix** - See [Section 2.3](#23-flake-template)
4. **.gitignore**:
   ```gitignore
   result
   result-*
   .direnv/
   .envrc
   *.swp
   *.swo
   *~
   ```

5. **.editorconfig** (optional but recommended):
   ```ini
   root = true

   [*]
   charset = utf-8
   end_of_line = lf
   insert_final_newline = true
   trim_trailing_whitespace = true

   [*.nix]
   indent_style = space
   indent_size = 2

   [*.md]
   trim_trailing_whitespace = false
   ```

---

## 3. Code Extraction & Refactoring

### 3.1 Extraction Process

#### Step 1: Copy Source Files

```bash
# Create new repository
mkdir my-project && cd my-project
git init

# Copy relevant files from original config
cp -r /path/to/original/modules/my-module ./modules/
cp /path/to/original/some-file.nix ./
```

#### Step 2: Identify Dependencies

List all dependencies your code relies on:

```bash
# Find imports
rg "import " --type nix

# Find package references
rg "pkgs\." --type nix

# Find home-manager references
rg "config\." --type nix | grep -v "config = "
```

#### Step 3: Remove User-Specific Code

**Common User-Specific Patterns**:

❌ **Remove**:
```nix
# Hardcoded paths
home.file.".config/my-app".source = /home/myuser/my-configs/app;

# Personal secrets
password = "my-secret-password";

# User-specific defaults
username = "myuser";
email = "myuser@example.com";

# Absolute paths to user directories
configPath = "/home/myuser/.config";
```

✅ **Replace with**:
```nix
# Relative to config
home.file.".config/my-app".source = ./app;

# Secret management integration
password = config.sops.secrets.my-app-password.path;

# Configurable options
options.my-app = {
  username = mkOption {
    type = types.str;
    description = "Username for my-app";
  };
  email = mkOption {
    type = types.str;
    description = "Email address";
  };
};

# Use built-in home directory
configPath = "${config.home.homeDirectory}/.config";
```

#### Step 4: Generalize Configuration

**Before (User-Specific)**:
```nix
# modules/my-service.nix
{ config, pkgs, ... }:
{
  services.myService = {
    enable = true;
    port = 8080;  # Hardcoded
    dataDir = "/mnt/storage/myservice";  # User-specific path
    users = [ "alice" "bob" ];  # Hardcoded users
  };
}
```

**After (Generalized)**:
```nix
# modules/my-service.nix
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.myService;
in
{
  options.services.myService = {
    enable = mkEnableOption "My Service";

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port for the service to listen on";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/myservice";
      description = "Directory for service data";
    };

    users = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "alice" "bob" ];
      description = "List of authorized users";
    };
  };

  config = mkIf cfg.enable {
    # Implementation
  };
}
```

### 3.2 Module API Design

Follow [Home Manager module guidelines](https://nix-community.github.io/home-manager/) and [NixOS module conventions](https://nixos.wiki/wiki/NixOS_modules).

#### Good Option Design Principles

1. **Sensible Defaults**: Options should work out-of-box for most users
2. **Type Safety**: Use appropriate types with validation
3. **Clear Descriptions**: Each option needs good documentation
4. **Composability**: Options should work together logically
5. **Escape Hatches**: Provide `extraConfig` or similar for advanced users

#### Option Type Reference

```nix
options.my-module = {
  # Boolean flag
  enable = mkEnableOption "my module";

  # String option
  username = mkOption {
    type = types.str;
    default = "default-user";
    description = "Username for authentication";
  };

  # Nullable string
  optionalSetting = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Optional setting";
  };

  # Integer with constraints
  port = mkOption {
    type = types.port;  # 0-65535
    default = 8080;
    description = "Port number";
  };

  # List of strings
  tags = mkOption {
    type = types.listOf types.str;
    default = [ ];
    example = [ "tag1" "tag2" ];
    description = "List of tags";
  };

  # Submodule for complex configuration
  advanced = mkOption {
    type = types.submodule {
      options = {
        enabled = mkOption {
          type = types.bool;
          default = false;
        };
        settings = mkOption {
          type = types.attrs;
          default = { };
        };
      };
    };
    default = { };
    description = "Advanced configuration";
  };

  # Package option
  package = mkOption {
    type = types.package;
    default = pkgs.my-package;
    defaultText = literalExpression "pkgs.my-package";
    description = "Package to use";
  };

  # Escape hatch for raw config
  extraConfig = mkOption {
    type = types.attrs;
    default = { };
    example = literalExpression ''
      {
        custom-setting = "value";
      }
    '';
    description = "Additional configuration options";
  };
};
```

### 3.3 Cross-Platform Support

If supporting both NixOS and Darwin:

```nix
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.myService;

  # Platform detection
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  # Platform-specific paths
  configDir = if isDarwin
    then "${config.home.homeDirectory}/Library/Application Support/MyApp"
    else "${config.home.homeDirectory}/.config/myapp";

  # Platform-specific services
  serviceConfig = if isDarwin
    then {
      # launchd configuration for macOS
      launchd.agents.myservice = {
        enable = true;
        config = {
          ProgramArguments = [ "${cfg.package}/bin/myservice" ];
          RunAtLoad = true;
        };
      };
    }
    else {
      # systemd configuration for Linux
      systemd.user.services.myservice = {
        Unit.Description = "My Service";
        Service = {
          ExecStart = "${cfg.package}/bin/myservice";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
in
{
  options.services.myService = {
    enable = mkEnableOption "My Service";
    # ... other options
  };

  config = mkIf cfg.enable (mkMerge [
    # Common configuration
    {
      home.packages = [ cfg.package ];
      home.file."${configDir}/config.json".text = /* ... */;
    }

    # Platform-specific configuration
    serviceConfig
  ]);
}
```

### 3.4 Testing During Extraction

Test continuously during extraction:

```bash
# Check syntax
nix flake check

# Build packages
nix build .#my-package

# Test in development VM (NixOS modules)
nix build .#nixosConfigurations.test-vm.config.system.build.vm
./result/bin/run-*-vm

# Test with home-manager (Home Manager modules)
nix build .#homeConfigurations.test-user.activationPackage
```

---

## 4. Documentation Requirements

### 4.1 README Structure

Follow [README best practices](https://github.com/jehna/readme-best-practices) for open-source projects.

#### Essential Sections

```markdown
# Project Name

> Brief, compelling one-line description

[![FlakeHub](https://img.shields.io/endpoint?url=https://flakehub.com/f/username/project/badge)](https://flakehub.com/flake/username/project)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## ✨ Highlights

- **Key Feature 1**: Brief description
- **Key Feature 2**: Brief description
- **Key Feature 3**: Brief description
- **Key Feature 4**: Brief description

## 📸 Screenshots / Demo

[Include visual demonstration if applicable]

![Screenshot](docs/images/screenshot.png)

## 🚀 Quick Start

```nix
# Add to flake inputs
{
  inputs.my-project.url = "github:username/my-project";
}

# Use in configuration
{
  imports = [ inputs.my-project.homeManagerModules.default ];

  services.myService.enable = true;
}
```

## 📦 Installation

### Flake-based Configuration

Add to your `flake.nix`:

[Detailed installation instructions]

### Non-Flake Configuration

[Legacy installation method if applicable]

## ⚙️ Configuration

### Basic Configuration

```nix
# Example basic setup
services.myService = {
  enable = true;
  # Common options
};
```

### Advanced Configuration

```nix
# Example advanced setup
services.myService = {
  enable = true;
  # Advanced options
};
```

### All Options

See [Configuration Reference](docs/configuration.md) for all available options.

## 🎯 Use Cases

### Use Case 1: [Title]
[Brief description and example]

### Use Case 2: [Title]
[Brief description and example]

## 🤝 Comparison with Alternatives

| Feature | This Project | Alternative 1 | Alternative 2 |
|---------|-------------|---------------|---------------|
| Feature A | ✅ | ❌ | ✅ |
| Feature B | ✅ | ✅ | ❌ |

## 🛠️ Development

```bash
# Clone repository
git clone https://github.com/username/my-project
cd my-project

# Enter development shell
nix develop

# Run tests
nix flake check

# Format code
nix fmt
```

## 🔍 Troubleshooting

### Common Issue 1
**Problem**: Description
**Solution**: Solution steps

### Common Issue 2
**Problem**: Description
**Solution**: Solution steps

See [Troubleshooting Guide](docs/troubleshooting.md) for more.

## 📚 Documentation

- [Installation Guide](docs/installation.md)
- [Configuration Reference](docs/configuration.md)
- [API Documentation](docs/api-reference.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Contributing Guide](CONTRIBUTING.md)

## 🤝 Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md).

## 📄 License

[MIT License](LICENSE) - see LICENSE file for details.

## 🙏 Acknowledgments

- [List key inspirations, dependencies, or contributors]

## 📞 Support

- 💬 [GitHub Discussions](https://github.com/username/project/discussions)
- 🐛 [Issue Tracker](https://github.com/username/project/issues)
- 💡 [NixOS Discourse](https://discourse.nixos.org/)
```

### 4.2 Additional Documentation Files

#### CHANGELOG.md

Use [Keep a Changelog](https://keepachangelog.com/) format:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New features go here

### Changed
- Changes to existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security fixes

## [1.0.0] - 2026-01-16

### Added
- Initial release
- Feature 1
- Feature 2

[Unreleased]: https://github.com/username/project/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/username/project/releases/tag/v1.0.0
```

#### CONTRIBUTING.md

```markdown
# Contributing to [Project Name]

Thank you for your interest in contributing!

## Ways to Contribute

- 🐛 Report bugs
- 💡 Suggest features
- 📖 Improve documentation
- 🔧 Submit pull requests

## Development Setup

[Setup instructions]

## Code Style

We follow standard Nix formatting conventions:

```bash
# Format code
nix fmt

# Check for issues
nix flake check
```

## Commit Guidelines

- Use conventional commits: `feat:`, `fix:`, `docs:`, `chore:`
- Keep commits focused and atomic
- Write clear commit messages

## Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Update documentation
6. Submit pull request

## Code of Conduct

Be respectful, inclusive, and constructive.

## Questions?

Ask in [GitHub Discussions](link) or [Matrix](link).
```

#### docs/configuration.md

Comprehensive option reference:

```markdown
# Configuration Reference

## services.myService

### enable

- **Type**: `boolean`
- **Default**: `false`
- **Description**: Whether to enable My Service

### port

- **Type**: `integer (0-65535)`
- **Default**: `8080`
- **Example**: `9000`
- **Description**: Port for the service to listen on

[Continue for all options...]

## Examples

### Minimal Configuration
[Example]

### Production Configuration
[Example]

### Advanced Use Cases
[Examples]
```

### 4.3 Code Comments

**Module Header**:
```nix
# My Service Module
#
# A brief description of what this module does and its purpose.
#
# Example usage:
#   services.myService = {
#     enable = true;
#     port = 8080;
#   };
#
# References:
#   - https://example.com/docs
#   - https://github.com/upstream/project
```

**Complex Logic**:
```nix
# Calculate the effective configuration by merging user settings
# with defaults. Priority: user config > defaults > fallback
let
  effectiveConfig = lib.recursiveUpdate
    defaultConfig
    (lib.optionalAttrs (cfg.extraConfig != {}) cfg.extraConfig);
in
```

**Non-Obvious Decisions**:
```nix
# Use writeShellScriptBin instead of writeScriptBin to ensure
# shell syntax highlighting and proper shebang handling in editors
wrapper = pkgs.writeShellScriptBin "my-service-wrapper" ''
  # ...
'';
```

---

## 5. Testing & CI/CD Setup

### 5.1 Local Testing

#### Test Suite Structure

```
tests/
├── basic.nix           # Basic functionality tests
├── integration.nix     # Integration tests
├── vm-test.nix        # NixOS VM tests (if applicable)
└── examples/
    ├── basic.nix      # Test basic example works
    └── advanced.nix   # Test advanced example works
```

#### Basic Test Example

```nix
# tests/basic.nix
{ pkgs, ... }:
pkgs.runCommand "basic-test" { } ''
  # Test that module loads without errors
  ${pkgs.nix}/bin/nix eval --impure --expr '
    let
      nixpkgs = builtins.getFlake "nixpkgs";
      my-project = builtins.getFlake "path:${./.}";
    in
      (nixpkgs.lib.evalModules {
        modules = [
          my-project.homeManagerModules.default
          { services.myService.enable = true; }
        ];
      }).config.services.myService.enable
  '

  touch $out
''
```

#### VM Test Example (NixOS Modules)

```nix
# tests/vm-test.nix
{ pkgs, ... }:
import (pkgs.path + "/nixos/tests/make-test-python.nix") {
  name = "my-service-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../modules/default.nix ];
    services.myService = {
      enable = true;
      port = 8080;
    };
  };

  testScript = ''
    machine.wait_for_unit("my-service.service")
    machine.wait_for_open_port(8080)
    machine.succeed("curl http://localhost:8080")
  '';
}
```

### 5.2 GitHub Actions CI/CD

Following [best practices for Nix in GitHub Actions](https://github.com/marketplace/actions/install-nix):

#### .github/workflows/ci.yml

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  flake-check:
    name: Flake check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Nix
        uses: cachix/install-nix-action@v31
        with:
          extra_nix_config: |
            experimental-features = nix-command flakes
            accept-flake-config = true

      - name: Setup Cachix
        uses: cachix/cachix-action@v15
        with:
          name: my-project
          authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'

      - name: Check flake
        run: nix flake check -L

  build:
    name: Build packages
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Nix
        uses: cachix/install-nix-action@v31
        with:
          extra_nix_config: |
            experimental-features = nix-command flakes

      - name: Setup Cachix
        uses: cachix/cachix-action@v15
        with:
          name: my-project
          authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'

      - name: Build packages
        run: |
          nix build .#default -L

  format:
    name: Check formatting
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Nix
        uses: cachix/install-nix-action@v31
        with:
          extra_nix_config: |
            experimental-features = nix-command flakes

      - name: Check formatting
        run: |
          nix fmt
          git diff --exit-code

  test:
    name: Run tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Nix
        uses: cachix/install-nix-action@v31
        with:
          extra_nix_config: |
            experimental-features = nix-command flakes

      - name: Setup Cachix
        uses: cachix/cachix-action@v15
        with:
          name: my-project
          authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'

      - name: Run tests
        run: |
          nix build .#checks.x86_64-linux.basic -L
          nix build .#checks.x86_64-linux.integration -L

  # Optional: Update flake.lock automatically
  update-flake:
    name: Update flake.lock
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4

      - name: Install Nix
        uses: cachix/install-nix-action@v31
        with:
          extra_nix_config: |
            experimental-features = nix-command flakes

      - name: Update flake.lock
        uses: DeterminateSystems/update-flake-lock@v24
        with:
          pr-title: "chore: update flake.lock"
          pr-labels: |
            dependencies
            automated
```

#### .github/workflows/release.yml

```yaml
name: Release

on:
  push:
    tags:
      - 'v*.*.*'

jobs:
  create-release:
    name: Create Release
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Nix
        uses: cachix/install-nix-action@v31

      - name: Build release artifacts
        run: |
          nix build .#default

      - name: Create Release
        uses: softprops/action-gh-release@v2
        with:
          draft: false
          prerelease: false
          generate_release_notes: true
```

### 5.3 Cachix Setup

[Cachix](https://www.cachix.org) provides binary cache hosting for Nix projects.

#### Setup Steps

1. **Create Cachix Account**: Visit [cachix.org](https://www.cachix.org) and sign up

2. **Create Binary Cache**:
   ```bash
   # Install cachix
   nix-env -iA cachix -f https://cachix.org/api/v1/install

   # Create cache (public for open source)
   cachix create my-project
   ```

3. **Generate Auth Token**:
   - Go to [app.cachix.org](https://app.cachix.org)
   - Select your cache → Settings
   - Generate write access token

4. **Add to GitHub Secrets**:
   - Repository Settings → Secrets → Actions
   - Add `CACHIX_AUTH_TOKEN` with your token

5. **Configure Users to Use Cache**:

   Add to flake documentation:

   ```nix
   # Add to flake.nix or configuration.nix
   nix.settings = {
     substituters = [
       "https://cache.nixos.org"
       "https://my-project.cachix.org"
     ];
     trusted-public-keys = [
       "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
       "my-project.cachix.org-1:YOUR_PUBLIC_KEY_HERE="
     ];
   };
   ```

---

## 6. Licensing & Legal Considerations

### 6.1 License Selection

**Recommended Licenses for Nix Projects**:

| License | Use Case | Nixpkgs Compatible |
|---------|----------|-------------------|
| **MIT** | Permissive, simple, popular | ✅ Yes |
| **Apache 2.0** | Permissive with patent grant | ✅ Yes |
| **BSD 3-Clause** | Permissive, similar to MIT | ✅ Yes |
| **GPL v3** | Strong copyleft | ✅ Yes (for modules) |
| **LGPL v3** | Library-focused copyleft | ✅ Yes |

**Most Common in Nix Ecosystem**: MIT or Apache 2.0

#### MIT License Template

```
MIT License

Copyright (c) 2026 [Your Name]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### 6.2 License Compatibility

**If Extracting from This Repository**:

This repository's license: [Check LICENSE file]

Ensure your extracted component is compatible:
- If original is MIT/Apache → Can use MIT, Apache, or more restrictive
- If original is GPL → Must use GPL-compatible license
- Document any mixed licensing in README

### 6.3 Copyright Attribution

**If Code Includes Contributions from Multiple Sources**:

```nix
# Original code adapted from:
#   - https://github.com/original/repo (MIT License)
#   - https://github.com/another/repo (Apache 2.0)
# Modified by [Your Name] 2026
```

### 6.4 Trademark Considerations

**If using third-party names**:
- Don't imply official endorsement
- Example: ❌ "Official ProtonVPN Module" → ✅ "ProtonVPN Port Forwarding for NixOS"

---

## 7. Release Process

### 7.1 Pre-Release Checklist

**Code Quality**:
- [ ] All tests passing (`nix flake check`)
- [ ] Code formatted (`nix fmt`)
- [ ] No warnings or errors
- [ ] Examples work correctly
- [ ] Documentation is complete and accurate

**Version Management**:
- [ ] Update version numbers in flake.nix
- [ ] Update CHANGELOG.md with release notes
- [ ] Tag commit with version (`vX.Y.Z`)

**Documentation**:
- [ ] README is up to date
- [ ] Installation instructions tested
- [ ] Configuration examples verified
- [ ] Breaking changes documented

### 7.2 Semantic Versioning

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (X.0.0): Breaking changes
- **MINOR** (0.X.0): New features, backward compatible
- **PATCH** (0.0.X): Bug fixes, backward compatible

**Examples**:
- `1.0.0` → Initial stable release
- `1.1.0` → Add new option (backward compatible)
- `1.1.1` → Fix bug
- `2.0.0` → Rename option (breaking change)

### 7.3 Release Steps

#### 1. Update Version

```bash
# Update flake.nix version (if present)
# Update any version strings in code

# Update CHANGELOG.md
$EDITOR CHANGELOG.md
```

#### 2. Commit and Tag

```bash
# Commit version bump
git add .
git commit -m "chore: bump version to v1.0.0"

# Create annotated tag
git tag -a v1.0.0 -m "Release v1.0.0

- Feature 1
- Feature 2
- Bug fix"

# Push to GitHub
git push origin main
git push origin v1.0.0
```

#### 3. GitHub Release

GitHub Actions will automatically create release when tag is pushed. If not:

1. Go to repository → Releases → Draft a new release
2. Choose tag: `v1.0.0`
3. Release title: `v1.0.0`
4. Copy CHANGELOG entries to release notes
5. Attach any build artifacts
6. Publish release

#### 4. Announce Release

Post announcements (see [Section 8](#8-community-engagement)):
- [NixOS Discourse Announcements](https://discourse.nixos.org/c/announcements/8)
- r/NixOS on Reddit
- Matrix/Discord channels
- Your own social media

### 7.4 Flake Registry

**Submit to FlakeHub** (optional but recommended):

1. Visit [flakehub.com](https://flakehub.com)
2. Connect GitHub account
3. Add your repository
4. Configure automatic publishing

**Benefits**:
- Discoverable at `flakehub:username/project`
- Automatic version tracking
- Usage statistics

---

## 8. Community Engagement

### 8.1 Announcement Strategy

#### Phase 1: Soft Launch (Week 1)

**Goals**: Test with early adopters, gather feedback

**Channels**:
1. **Personal Network**:
   - Share with friends/colleagues
   - Post in small community channels
   - DM relevant people who might be interested

2. **Niche Communities**:
   - Relevant Matrix rooms
   - Discord servers for specific use cases
   - Small subreddits

**Message Template**:
```markdown
Hi! I've extracted [component] from my personal Nix config and
published it as a standalone project. It's designed to [brief purpose].

I'd love feedback before announcing it more widely:
[GitHub link]

Key features:
- Feature 1
- Feature 2
- Feature 3

Still rough around edges, but functional. Let me know what you think!
```

#### Phase 2: Public Launch (Week 2-3)

**Goals**: Broad visibility, attract users and contributors

**Channels** (in order):

1. **[NixOS Discourse - Announcements](https://discourse.nixos.org/c/announcements/8)**:
   ```markdown
   Title: [Announcing] Project Name - Brief Description

   Hi everyone,

   I'm excited to announce [Project Name], a [module/package/tool] for [purpose].

   ## What is it?

   [2-3 sentences explaining the project]

   ## Key Features

   - Feature 1
   - Feature 2
   - Feature 3

   ## Why I built this

   [Brief motivation - what problem does it solve?]

   ## Getting Started

   ```nix
   [Simple example]
   ```

   ## Links

   - GitHub: [link]
   - Documentation: [link]
   - Examples: [link]

   ## What's Next

   [Roadmap items, areas where help is needed]

   Looking forward to your feedback!
   ```

2. **Reddit - r/NixOS**:
   - Similar content to Discourse
   - Add link to Discourse thread for discussion
   - More casual tone acceptable

3. **Matrix/Discord**:
   - Post in relevant channels:
     - #announcements in NixOS
     - Related project channels
   - Keep brief, link to full announcement

4. **Social Media**:
   - Twitter/Mastodon with #NixOS hashtag
   - LinkedIn (if professional tool)
   - Your blog (if you have one)

#### Phase 3: Sustained Engagement (Ongoing)

**Content Ideas**:
- Blog posts about design decisions
- Video tutorials
- Case studies / success stories
- Integration guides with popular tools
- Comparison with alternatives

### 8.2 Announcement Template

```markdown
# [Project Name] v1.0.0 - [One-line Description]

I'm excited to announce the first stable release of [Project Name]!

## 🎯 What is it?

[2-3 paragraph explanation of purpose and value]

## ✨ Key Features

- **Feature 1**: Description
- **Feature 2**: Description
- **Feature 3**: Description

## 🚀 Quick Start

\`\`\`nix
{
  inputs.my-project.url = "github:username/my-project";
}
\`\`\`

[Brief usage example]

## 📚 Why I Built This

[Personal story - what problem were you solving?]
[Why existing solutions weren't sufficient]

## 🎉 What Makes It Different?

[Comparison with alternatives, if applicable]

## 🗺️ Roadmap

- [ ] Planned feature 1
- [ ] Planned feature 2
- [ ] Planned feature 3

## 🤝 Get Involved

- 📖 [Documentation](link)
- 💬 [Discussions](link)
- 🐛 [Issue Tracker](link)
- 🔧 [Contributing Guide](link)

## 🙏 Thanks

[Acknowledge anyone who helped, inspired, or tested]

---

**Links**:
- GitHub: [link]
- Documentation: [link]
- FlakeHub: [link] (if available)

Looking forward to your feedback!
```

### 8.3 Responding to Feedback

**Good Practices**:

1. **Acknowledge Quickly**: Respond to issues/PRs within 24-48 hours
2. **Be Gracious**: Thank people for feedback, even if critical
3. **Be Clear**: If you won't implement something, explain why
4. **Document Decisions**: Link to issues in commit messages
5. **Encourage Contributions**: Point out "good first issue" items

**Response Templates**:

**Bug Report**:
```markdown
Thanks for reporting this! This looks like a legitimate issue.

Can you provide:
- Your NixOS/Home Manager version
- Minimal reproduction steps
- Relevant log output

I'll investigate and get back to you soon.
```

**Feature Request**:
```markdown
Interesting idea! I can see how this would be useful for [use case].

Some questions:
- [Question 1]
- [Question 2]

Would you be interested in contributing this feature? I'm happy to
provide guidance.
```

**Pull Request**:
```markdown
Thank you for the contribution!

The change looks good overall. A few minor comments:
- [Comment 1]
- [Comment 2]

Once these are addressed, I'll merge this.
```

---

## 9. Post-Launch Maintenance

### 9.1 Issue Management

**Triage Process**:

1. **Label**: Apply appropriate labels
   - `bug` - Something broken
   - `enhancement` - New feature request
   - `documentation` - Docs improvement
   - `good first issue` - Easy for newcomers
   - `help wanted` - Accepting contributions
   - `question` - Not a bug or feature

2. **Prioritize**:
   - **P0 (Critical)**: Broken core functionality
   - **P1 (High)**: Major features broken
   - **P2 (Medium)**: Minor bugs, nice-to-have features
   - **P3 (Low)**: Edge cases, future enhancements

3. **Close Invalid**:
   - Duplicates (link to original)
   - Already fixed (link to PR/commit)
   - Won't fix (explain reasoning)
   - Out of scope

### 9.2 Versioning Strategy

**Release Cadence Options**:

1. **Time-Based** (e.g., monthly):
   - Predictable for users
   - Good for mature projects
   - Example: Release on first Monday of month

2. **Feature-Based**:
   - Release when significant features complete
   - More flexible
   - Good for early projects

3. **As-Needed**:
   - Release when critical bugs fixed
   - Minimal overhead
   - Can feel unpredictable

**Recommended for New Projects**: Feature-based initially, move to time-based once stable.

### 9.3 Deprecation Policy

When removing/changing features:

1. **Announce Early** (at least one release in advance):
   ```nix
   options.oldOption = mkOption {
     # ...
     description = ''
       DEPRECATED: Use newOption instead. This option will be
       removed in version 2.0.0.
     '';
   };

   config = {
     # Add deprecation warning
     warnings = lib.optional (cfg.oldOption != null) ''
       services.myService.oldOption is deprecated and will be removed
       in version 2.0.0. Please use services.myService.newOption instead.
     '';

     # Provide compatibility shim
     services.myService.newOption =
       lib.mkDefault (cfg.oldOption or cfg.newOption);
   };
   ```

2. **Document in CHANGELOG**:
   ```markdown
   ## [1.5.0] - 2026-01-16

   ### Deprecated
   - `oldOption` in favor of `newOption`. Will be removed in v2.0.0.
   ```

3. **Remove in Major Version**:
   ```markdown
   ## [2.0.0] - 2026-06-16

   ### Removed
   - `oldOption` (deprecated in v1.5.0). Use `newOption` instead.
   ```

### 9.4 Maintainer Burnout Prevention

**Strategies**:

1. **Set Boundaries**:
   - Define "office hours" for maintenance
   - Use GitHub's "Limited availability" status
   - It's okay to take breaks

2. **Automate**:
   - Use bots for common tasks (stale issues, formatting checks)
   - Template responses for common questions
   - CI/CD for testing and releases

3. **Delegate**:
   - Add co-maintainers
   - Create contributor guide
   - Mark issues as "help wanted"

4. **Scale Back**:
   - Mark project as "maintenance mode" if needed
   - Be honest about capacity
   - Archive if truly done

---

## 10. Appendices

### 10.A Checklist: Ready for v1.0

**Code**:
- [ ] All core features implemented
- [ ] Test coverage adequate
- [ ] No known critical bugs
- [ ] API is stable (breaking changes unlikely)
- [ ] Examples work

**Documentation**:
- [ ] README is comprehensive
- [ ] All options documented
- [ ] Installation guide complete
- [ ] At least 3 examples provided
- [ ] Troubleshooting section exists

**Infrastructure**:
- [ ] CI/CD working
- [ ] Cachix configured (if applicable)
- [ ] License file present
- [ ] Contributing guide exists
- [ ] Code of conduct added (optional)

**Community**:
- [ ] Project announced
- [ ] At least 5 users (not including you)
- [ ] Feedback incorporated
- [ ] Issue tracker active

### 10.B Template: Issue Templates

#### Bug Report (.github/ISSUE_TEMPLATE/bug_report.md)

```markdown
---
name: Bug Report
about: Report a problem
title: '[BUG] '
labels: bug
assignees: ''
---

## Description

[Clear description of the bug]

## Steps to Reproduce

1.
2.
3.

## Expected Behavior

[What should happen]

## Actual Behavior

[What actually happens]

## Environment

- NixOS version: [e.g., 25.05]
- Home Manager version: [if applicable]
- Project version: [e.g., v1.0.0]

## Configuration

\`\`\`nix
# Relevant configuration
\`\`\`

## Logs

\`\`\`
# Error messages or logs
\`\`\`

## Additional Context

[Any other relevant information]
```

#### Feature Request (.github/ISSUE_TEMPLATE/feature_request.md)

```markdown
---
name: Feature Request
about: Suggest a new feature
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

## Problem

[What problem does this feature solve?]

## Proposed Solution

[How should this work?]

## Alternatives Considered

[What other approaches did you consider?]

## Additional Context

[Any other relevant information]

## Would you contribute this?

[Yes/No/Maybe - Would you be willing to implement this with guidance?]
```

### 10.C Template: Pull Request Template

#### .github/pull_request_template.md

```markdown
## Description

[Clear description of changes]

## Motivation

[Why is this change needed?]

## Changes

- [ ] Change 1
- [ ] Change 2

## Testing

[How was this tested?]

## Checklist

- [ ] Code follows project style
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] All checks passing

## Related Issues

Fixes #[issue number]
```

### 10.D Resources

**Nix Documentation**:
- [Nix Manual](https://nix.dev/manual/nix/2.24/)
- [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Flakes](https://wiki.nixos.org/wiki/Flakes)

**Best Practices**:
- [Blueprint](https://github.com/numtide/blueprint) - Standard folder structure
- [nix.dev](https://nix.dev/) - Official Nix documentation
- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/)

**Tools**:
- [Cachix](https://www.cachix.org) - Binary cache hosting
- [FlakeHub](https://flakehub.com) - Flake registry
- [nixpkgs-fmt](https://github.com/nix-community/nixpkgs-fmt) - Code formatter
- [statix](https://github.com/nerdypepper/statix) - Linter
- [deadnix](https://github.com/astro/deadnix) - Dead code finder

**Community**:
- [NixOS Discourse](https://discourse.nixos.org/)
- [Reddit r/NixOS](https://reddit.com/r/NixOS)
- [Matrix Chat](https://matrix.to/#/#community:nixos.org)
- [GitHub Discussions](https://github.com/NixOS/nixpkgs/discussions)

---

## Conclusion

Extracting and publishing a component from your private Nix configuration is a significant undertaking, but following this guide will help ensure success.

**Key Takeaways**:

1. **Start Small**: Pick one well-defined component
2. **Quality Over Speed**: Take time to generalize properly
3. **Document Everything**: Good docs are essential
4. **Test Thoroughly**: CI/CD and tests save time later
5. **Engage Community**: Listen to feedback, iterate
6. **Be Patient**: Building momentum takes time

**Estimated Timeline**:

- **Week 1**: Assessment, extraction, generalization
- **Week 2**: Documentation, testing, CI/CD setup
- **Week 3**: Soft launch, gather feedback
- **Week 4**: Polish, public launch

Good luck with your extraction project!

---

**Sources Referenced**:
- [Flakes - NixOS Wiki](https://nixos.wiki/wiki/Flakes)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nixpkgs Contributing Guide](https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md)
- [Blueprint - Standard folder structure](https://github.com/numtide/blueprint)
- [Install Nix - GitHub Actions](https://github.com/marketplace/actions/install-nix)
- [Cachix Documentation](https://docs.cachix.org/)
- [README Best Practices](https://github.com/jehna/readme-best-practices)
- [NixOS Discourse](https://discourse.nixos.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)
