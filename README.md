# Nix Configuration

[![CI](https://github.com/lewisflude/nix-config/workflows/CI/badge.svg)](https://github.com/lewisflude/nix-config/actions/workflows/ci.yml)
[![Nix Flake](https://img.shields.io/badge/nix-flake-blue.svg)](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html)
[![NixOS 24.11](https://img.shields.io/badge/NixOS-24.11-blue.svg)](https://nixos.org)

A modern, cross-platform Nix setup for both macOS (nix-darwin) and Linux (NixOS), with shared Home Manager and development environments.

> **📚 Full Documentation:** [`docs/`](docs/) - Comprehensive guides, references, and examples

## 🚀 Quick Start

### 1. Install Nix

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### 2. Clone This Configuration

```bash
git clone <your-repo-url> ~/.config/nix
cd ~/.config/nix
```

### 3. Build Your System

Replace `<hostname>` with your machine name (e.g., `jupiter` for Linux or `Lewiss-MacBook-Pro` for macOS):

- **macOS:** `sudo darwin-rebuild switch --flake ~/.config/nix#<hostname>`
- **Linux:** `sudo nixos-rebuild switch --flake ~/.config/nix#<hostname>`

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
| **🗄️ Cachix & FlakeHub** | [`docs/CACHIX_FLAKEHUB_SETUP.md`](docs/CACHIX_FLAKEHUB_SETUP.md) | Set up binary cache and flake publishing |
| **🎨 Developer Experience** | [`docs/DX_GUIDE.md`](docs/DX_GUIDE.md) | DX tooling, commits, and best practices |
| **🏗️ Architecture** | [`docs/reference/architecture.md`](docs/reference/architecture.md) | System design and patterns |
| **⚙️ Features** | [`docs/FEATURES.md`](docs/FEATURES.md) | Feature-based configuration system |
| **⌨️ Keyboard Layout** | [`docs/reference/keyboard-keymap.md`](docs/reference/keyboard-keymap.md) | WKL F13 TKL ergonomic keymap for software engineers |
| **🔄 Updating** | [`docs/UPDATING.md`](docs/UPDATING.md) | How to update dependencies and inputs |
| **💬 Code Review** | [`docs/CONVENTIONAL_COMMENTS.md`](docs/CONVENTIONAL_COMMENTS.md) | Conventional comments for reviews |
| **🔍 Build Profiling** | [`docs/BUILD_PROFILING.md`](docs/BUILD_PROFILING.md) | Tools for profiling builds |
| **📊 Performance Tuning** | [`docs/PERFORMANCE_TUNING.md`](docs/PERFORMANCE_TUNING.md) | Performance optimizations and configurations |
| **📈 Performance Monitoring** | [`docs/reference/performance-monitoring.md`](docs/reference/performance-monitoring.md) | Monitoring and tracking performance metrics |
| **🔍 Cache Behavior** | [`docs/SUBSTITUTER_QUERY_BEHAVIOR.md`](docs/SUBSTITUTER_QUERY_BEHAVIOR.md) | How Nix queries binary caches |
| **⚡ Cache Error Impact** | [`docs/CACHE_ERROR_IMPACT.md`](docs/CACHE_ERROR_IMPACT.md) | How cache errors affect build performance |
| **🤝 Contributing** | [`CONTRIBUTING.md`](CONTRIBUTING.md) | How to contribute to this repo |

## 🎯 Common Tasks

- **Add a package:** See [DX Guide](docs/DX_GUIDE.md) or [Features Guide](docs/FEATURES.md) for configuration patterns
- **Set up dev environment:** `nix develop` - includes pre-commit hooks, formatters, and linters
- **Update dependencies:** See [Updating Guide](docs/UPDATING.md) or run `nix run .#update-all`
- **Format code:** `nix fmt` or `treefmt` for all files, automatic via pre-commit hooks
- **Write good commits:** See [DX Guide → Conventional Commits](docs/DX_GUIDE.md#conventional-commits)
- **Troubleshoot issues:** See [Build Profiling](docs/BUILD_PROFILING.md) or [Performance Tuning](docs/PERFORMANCE_TUNING.md)

## 🛠️ Maintenance

```bash
# Update all dependencies (automated)
nix run .#update-all

# Or manually update inputs
nix flake update
sudo nixos-rebuild switch --flake ~/.config/nix#<hostname>  # Linux
sudo darwin-rebuild switch --flake ~/.config/nix#<hostname> # macOS

# Cleanup
nix-collect-garbage -d && nix store optimise
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

**Setup guide:** [`docs/CACHIX_FLAKEHUB_SETUP.md`](docs/CACHIX_FLAKEHUB_SETUP.md)

### FlakeHub - Flake Publishing

This configuration can be published to FlakeHub for easy discovery and versioned releases.

**Use this config:**

```nix
{
  inputs.lewisflude-nix.url = "https://flakehub.com/f/lewisflude/nix/*";
}
```

**Setup guide:** [`docs/CACHIX_FLAKEHUB_SETUP.md`](docs/CACHIX_FLAKEHUB_SETUP.md)

---

**Need more help?** Check out the [`docs/`](docs/) directory for comprehensive guides and references.
