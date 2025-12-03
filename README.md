# 🔷 Nix Configuration

[![CI](https://github.com/lewisflude/nix/workflows/CI/badge.svg)](https://github.com/lewisflude/nix/actions/workflows/ci.yml)
[![Nix Flake](https://img.shields.io/badge/nix-flake-blue.svg)](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html)
[![NixOS 24.11](https://img.shields.io/badge/NixOS-24.11-blue.svg)](https://nixos.org)
[![nix-darwin](https://img.shields.io/badge/nix--darwin-supported-blue.svg)](https://github.com/LnL7/nix-darwin)
[![GitHub last commit](https://img.shields.io/github/last-commit/lewisflude/nix)](https://github.com/lewisflude/nix/commits)
[![GitHub stars](https://img.shields.io/github/stars/lewisflude/nix?style=social)](https://github.com/lewisflude/nix)

> **A modern, declarative, cross-platform Nix configuration** for both macOS (nix-darwin) and Linux (NixOS), featuring shared Home Manager configurations, comprehensive development environments, and production-ready tooling.

## 📖 Table of Contents

- [✨ Key Features](#-key-features)
- [🚀 Quick Start](#-quick-start)
- [📁 Structure Overview](#-structure-overview)
- [📚 Documentation](#-documentation)
- [🛠️ Tech Stack](#️-tech-stack)
- [🎯 Common Tasks](#-common-tasks)
- [🛠️ Maintenance](#️-maintenance)
- [🎨 Developer Experience](#-developer-experience)
- [🚀 Binary Cache & Publishing](#-binary-cache--publishing)
- [💡 Support & Help](#-support--help)

## ✨ Key Features

- 🌍 **Cross-Platform**: Unified configuration for NixOS (Linux) and nix-darwin (macOS)
- 🏠 **Home Manager Integration**: Consistent user environment across all systems
- 🔄 **Flake-Based**: Modern Nix flakes for reproducible builds
- 🚀 **Binary Cache Ready**: Pre-configured Cachix support for faster builds (10-30s vs 10-20min)
- 🔐 **Secrets Management**: SOPS-nix integration for secure credential handling
- 🛠️ **DX Tooling**: Pre-commit hooks, formatters, linters, and conventional commits
- 🎨 **Feature System**: Modular, reusable feature-based configuration
- 📊 **CI/CD**: Automated testing and validation via GitHub Actions
- 🔧 **POG Scripts**: Interactive CLI tools for common tasks (module creation, updates, visualization)

> **📚 Full Documentation:** [`docs/`](docs/) - Comprehensive guides, references, and examples

## 🚀 Quick Start

### Prerequisites

- A supported system: **macOS** (10.14+) or **Linux** (any modern distro)
- Internet connection for downloading Nix packages

### 1. Install Nix

```bash
# Using Determinate Systems installer (recommended - includes flakes by default)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### 2. Clone This Configuration

```bash
# Clone to your preferred location (e.g., ~/.config/nix)
git clone https://github.com/lewisflude/nix.git ~/.config/nix
cd ~/.config/nix
```

### 3. Configure Your Host

Create a host configuration for your machine in `hosts/` directory (or use an existing one), then build:

```bash
# Replace <hostname> with your machine name
# Examples: jupiter (Linux) | Lewiss-MacBook-Pro (macOS)

# macOS (nix-darwin)
sudo darwin-rebuild switch --flake ~/.config/nix#<hostname>

# Linux (NixOS)
sudo nixos-rebuild switch --flake ~/.config/nix#<hostname>
```

### 4. Enter Development Environment (Optional)

```bash
# Sets up pre-commit hooks, formatters, and linters automatically
nix develop
```

> **💡 Tip:** Use Cachix to speed up builds! See [Binary Cache & Publishing](#-binary-cache--publishing) section.

## 📁 Structure Overview

```
.
├── 📄 README.md              # This file - quick start
├── 📄 flake.nix              # Main flake configuration
├── 📁 docs/                  # 📚 Complete documentation
├── 📁 hosts/                 # 🖥️  Host-specific configs
├── 📁 modules/               # ⚙️  System-level modules
│   ├── shared/               #     Cross-platform modules
│   ├── darwin/               #     macOS-specific modules
│   └── nixos/                #     Linux-specific modules
├── 📁 home/                  # 🏠 Home Manager configs
│   ├── common/               #     Cross-platform user configs
│   ├── darwin/               #     macOS user configs
│   └── nixos/                #     Linux user configs
├── 📁 shells/                # 💻 Development environments
├── 📁 scripts/               # 🔧 Utility scripts
├── 📁 secrets/               # 🔐 SOPS secrets management
└── 📁 lib/                   # 🛠️  Helper functions
```

## 📚 Documentation

| Topic | Link | Description |
|-------|------|-------------|
| **🚀 Quick Start** | See [Quick Start](#-quick-start) above | Get up and running in 5 minutes |
| **🗄️ Cachix & FlakeHub** | [`docs/archive/CACHIX_FLAKEHUB_SETUP.md`](docs/archive/CACHIX_FLAKEHUB_SETUP.md) | Set up binary cache and flake publishing (archived) |
| **🎨 Developer Experience** | [`docs/DX_GUIDE.md`](docs/DX_GUIDE.md) | DX tooling, commits, and best practices |
| **🔄 Continuous Integration** | [`docs/CI.md`](docs/CI.md) | GitHub Actions workflows and CI setup |
| **🏗️ Architecture** | [`docs/reference/architecture.md`](docs/reference/architecture.md) | System design and patterns |
| **⚙️ Features** | [`docs/FEATURES.md`](docs/FEATURES.md) | Feature-based configuration system |
| **⌨️ Keyboard Layout** | [`docs/reference/keyboard-keymap.md`](docs/reference/keyboard-keymap.md) | WKL F13 TKL ergonomic keymap for software engineers |
| **🔄 Updating** | [`docs/UPDATING.md`](docs/UPDATING.md) | How to update dependencies and inputs |
| **💬 Code Review** | [`docs/CONVENTIONAL_COMMENTS.md`](docs/CONVENTIONAL_COMMENTS.md) | Conventional comments for reviews |
| **📊 Performance Tuning** | [`docs/PERFORMANCE_TUNING.md`](docs/PERFORMANCE_TUNING.md) | Performance optimizations and configurations |
| **📈 Performance Monitoring** | [`docs/reference/performance-monitoring.md`](docs/reference/performance-monitoring.md) | Monitoring and tracking performance metrics |
| **🎵 Real-Time Audio** | [`docs/REALTIME_AUDIO_GUIDE.md`](docs/REALTIME_AUDIO_GUIDE.md) | Professional audio with musnix, RT kernel, and USB audio interfaces |
| **🤝 Contributing** | [`CONTRIBUTING.md`](CONTRIBUTING.md) | How to contribute to this repo |

## 🛠️ Tech Stack

<details>
<summary>Click to expand core technologies</summary>

- **Nix Flakes** - Reproducible, composable package management
- **NixOS** - Declarative Linux distribution
- **nix-darwin** - Nix modules for macOS system configuration
- **Home Manager** - User environment management
- **SOPS-nix** - Secrets management with age/GPG encryption
- **Treefmt** - Multi-language code formatting
- **Pre-commit Hooks** - Automated code quality checks
- **GitHub Actions** - Continuous integration and testing
- **Cachix** - Binary cache for faster builds
- **FlakeHub** - Flake publishing and versioning

</details>

## 🎯 Common Tasks

| Task | Command | Documentation |
|------|---------|---------------|
| **🔧 Enter dev environment** | `nix develop` | Auto-configures hooks, formatters, linters |
| **📦 Add a package** | See guides → | [DX Guide](docs/DX_GUIDE.md) \| [Features Guide](docs/FEATURES.md) |
| **🔄 Update dependencies** | `nix run .#update-all` | [Updating Guide](docs/UPDATING.md) |
| **✨ Format code** | `nix fmt` or `treefmt` | Runs automatically via pre-commit |
| **✍️ Write good commits** | Follow convention → | [Conventional Commits](docs/DX_GUIDE.md#conventional-commits) |
| **🆕 Create module** | `nix run .#new-module` | Interactive scaffolding tool |
| **📊 Visualize modules** | `nix run .#visualize-modules` | Generate dependency graphs |
| **🐛 Troubleshoot** | See docs → | [Performance Tuning](docs/PERFORMANCE_TUNING.md) |
| **🧹 Cleanup** | `nix-collect-garbage -d` | Reclaim disk space |

## 🛠️ Maintenance

### Update Dependencies

```bash
# 🎯 Recommended: Automated update (flake inputs + ZSH plugins)
nix run .#update-all

# Or manually update flake inputs
nix flake update

# Apply updates to your system
sudo nixos-rebuild switch --flake ~/.config/nix#<hostname>  # Linux
sudo darwin-rebuild switch --flake ~/.config/nix#<hostname> # macOS
```

### Cleanup & Optimization

```bash
# Remove old generations and optimize store
nix-collect-garbage -d && nix store optimise

# List generations (to see what you're deleting)
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Delete specific generations
sudo nix-env --delete-generations 14d --profile /nix/var/nix/profiles/system
```

### Health Checks

```bash
# Verify flake
nix flake check

# Check configuration syntax
nix flake show

# Dry-run build (test without applying)
sudo nixos-rebuild dry-run --flake ~/.config/nix#<hostname>
```

## 🎨 Developer Experience

This repository includes comprehensive DX tooling:

- **✅ Pre-commit Hooks**: Automatic formatting, linting, and validation
- **📝 Conventional Commits**: Standardized commit messages with enforcement
- **💬 Conventional Comments**: Structured code review feedback
- **⚙️ EditorConfig**: Consistent code style across editors
- **🔧 Development Shells**: Language-specific environments with all tools

**Get started:** `nix develop` (auto-configures everything!)

**Learn more:** See [DX Guide](docs/DX_GUIDE.md) and [Contributing Guide](CONTRIBUTING.md)

## 🚀 Binary Cache & Publishing

### Cachix - Fast Binary Cache

Speed up your builds by using pre-built packages:

```bash
# Use the personal cache (setup required)
cachix use lewisflude-nix
```

Rebuilds will be **10-30 seconds** instead of 10-20 minutes!

**Setup guide:** [`docs/archive/CACHIX_FLAKEHUB_SETUP.md`](docs/archive/CACHIX_FLAKEHUB_SETUP.md)

### FlakeHub - Flake Publishing

This configuration can be published to FlakeHub for easy discovery and versioned releases.

**Use this config:**

```nix
{
  inputs.lewisflude-nix.url = "https://flakehub.com/f/lewisflude/nix/*";
}
```

**Setup guide:** [`docs/archive/CACHIX_FLAKEHUB_SETUP.md`](docs/archive/CACHIX_FLAKEHUB_SETUP.md)

---

## 💡 Support & Help

### 📚 Documentation

- **Primary Docs**: Browse the [`docs/`](docs/) directory for comprehensive guides
- **Architecture**: Understand the system design in [`docs/reference/architecture.md`](docs/reference/architecture.md)
- **DX Guide**: Learn best practices in [`docs/DX_GUIDE.md`](docs/DX_GUIDE.md)
- **Features**: Explore the feature system in [`docs/FEATURES.md`](docs/FEATURES.md)

### 🤝 Contributing

Contributions are welcome! Please read the [Contributing Guide](CONTRIBUTING.md) for:
- Code style guidelines
- Commit message conventions
- Pull request process
- Development setup

### 📝 License

This configuration is personal but shared as reference material. Feel free to fork and adapt for your own use.

### 🔗 Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nix-Darwin Manual](https://daiderd.com/nix-darwin/manual/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Pills](https://nixos.org/guides/nix-pills/) - In-depth Nix tutorial

---

**Questions?** Check the documentation or open an issue for help!
