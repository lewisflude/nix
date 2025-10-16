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
| **🚀 Quick Start** | [`docs/guides/quick-start.md`](docs/guides/quick-start.md) | Get up and running in 5 minutes |
| **💻 Development** | [`docs/guides/development.md`](docs/guides/development.md) | Development environments and shells |
| **⚙️ Configuration** | [`docs/guides/configuration.md`](docs/guides/configuration.md) | Adding packages, hosts, and modules |
| **🔐 Secrets** | [`docs/guides/secrets.md`](docs/guides/secrets.md) | SOPS secrets management |
| **🏗️ Architecture** | [`docs/reference/architecture.md`](docs/reference/architecture.md) | System design and patterns |
| **⌨️ Keyboard Layout** | [`docs/reference/keyboard-keymap.md`](docs/reference/keyboard-keymap.md) | WKL F13 TKL ergonomic keymap for software engineers |
| **🤖 AI Assistants** | [`docs/ai-assistants/`](docs/ai-assistants/) | Claude, ChatGPT, Cursor guidance |

## 🎯 Common Tasks

- **Add a package:** See [Configuration Guide → Adding Packages](docs/guides/configuration.md#adding-packages)
- **Set up dev environment:** See [Development Guide → Getting Started](docs/guides/development.md#getting-started)
- **Troubleshoot issues:** See [Troubleshooting Guide](docs/guides/troubleshooting.md)
- **Update system:** See [System Management Guide](docs/guides/system-management.md)

## 🛠️ Maintenance

```bash
# Update inputs and rebuild
nix flake update
sudo nixos-rebuild switch --flake ~/.config/nix#<hostname>  # Linux
sudo darwin-rebuild switch --flake ~/.config/nix#<hostname> # macOS

# Cleanup
nix-collect-garbage -d && nix store optimise
```

---

**Need more help?** Check out the [`docs/`](docs/) directory for comprehensive guides and references.
