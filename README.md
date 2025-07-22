# Nix Configuration

A modern, cross-platform Nix setup for both macOS (nix-darwin) and Linux (NixOS), with shared Home Manager and development environments.

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
Replace `<hostname>` with the directory name under `hosts/` that matches your
machine (e.g. `Lewiss-MacBook-Pro` or `jupiter`).

- **macOS:**
  ```bash
  sudo darwin-rebuild switch --flake ~/.config/nix#<hostname>
  ```
- **Linux:**
  ```bash
  sudo nixos-rebuild switch --flake ~/.config/nix#<hostname>
  ```

## 📁 Directory Structure

```
.
├── flake.nix                # Main flake configuration (inputs/outputs)
├── hosts/                   # Host-specific configs (per machine)
│   ├── jupiter/             # Example NixOS host
│   └── Lewiss-MacBook-Pro/  # Example macOS host
├── modules/                 # System-level modules
│   ├── common/              # Shared modules (all platforms)
│   ├── darwin/              # macOS-specific modules
│   └── nixos/               # Linux-specific modules
├── home/                    # Home Manager configs
│   └── common/              # Cross-platform user configs
├── shells/                  # Development environments
│   ├── projects/            # Project-specific shells
│   ├── envrc-templates/     # .envrc templates for direnv
│   └── utils/               # Utility shells (e.g., shell-selector)
├── lib/                     # Helper functions/utilities
├── secrets/                 # Secrets management (SOPS)
├── templates/               # Module templates for new configs
├── graph.svg                # Dependency graph (generated)
└── README.md                # This file
```

## 🛠️ Development Environments

Development shells are managed in `shells/`. See [`shells/README.md`](shells/README.md) for full details and best practices.

### Quick Usage
- **Interactive shell selection:**
  ```bash
  nix develop ~/.config/nix#shell-selector
  select_dev_shell
  ```
- **Direct shell usage:**
  ```bash
  nix develop ~/.config/nix#node            # Node.js/TypeScript
  nix develop ~/.config/nix#python          # Python
  nix develop ~/.config/nix#rust            # Rust
  nix develop ~/.config/nix#go              # Go
  nix develop ~/.config/nix#web             # Full-stack web
  nix develop ~/.config/nix#devops          # DevOps/Infra
  # ...and more (see shells/README.md)
  ```
- **Project-based with direnv:**
  1. Copy a template:
     ```bash
     cp ~/.config/nix/shells/envrc-templates/node .envrc
     direnv allow
     ```
  2. The environment loads automatically when you `cd` into the project.

## 🔐 Secrets Management

Secrets are managed with SOPS and age keys.

### Setup
1. Generate an age key:
   ```bash
   mkdir -p ~/.config/sops/age
   age-keygen -o ~/.config/sops/age/keys.txt
   ```
2. Create/edit secrets:
   ```bash
   cd ~/.config/nix/secrets
   sops secrets.yaml
   ```

## 🖥️ Configuration Overview

- **System packages:** Add to the appropriate module in `modules/` (see `common/`, `darwin/`, `nixos/`)
- **User packages:** Add to `home/common/apps.nix`
- **Development tools:** Add to the relevant shell in `shells/`
- **Host-specific config:** Add or edit hosts in `hosts/` following the existing pattern

## 🧩 Home Manager & System Modules
- **Home Manager:**
  - Shared user config: `home/common/`
  - Apps: `home/common/apps/`
  - Development: `home/common/development/`
  - Desktop/system: `home/common/desktop/`, `home/common/system/`
- **System Modules:**
  - Shared: `modules/common/`
  - macOS: `modules/darwin/`
  - Linux: `modules/nixos/`

## 🧹 Maintenance

- **Update flake inputs:**
  ```bash
  nix flake update
  nix flake check       # Verify builds
  ```
- **System update:**
  ```bash
  # macOS
  sudo darwin-rebuild switch --flake ~/.config/nix#<hostname>
  # Linux
  sudo nixos-rebuild switch --flake ~/.config/nix#<hostname>
  ```
- **Cleanup:**
  ```bash
  nix-collect-garbage -d
  nix store optimise
  ```

## 🐛 Troubleshooting

- **Build failures:** Check logs (`journalctl -u nix-daemon` on Linux)
- **Permission issues:** Ensure your user is in the `nix-users` group
- **Home Manager issues:**
  ```bash
  home-manager switch --backup-extension .bak
  ```
- **Isolated testing:**
  ```bash
  nix develop
  ```

## 📚 References

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Home Manager](https://nix-community.github.io/home-manager/)
- [nix-darwin](https://github.com/LnL7/nix-darwin)
- [SOPS-nix](https://github.com/Mic92/sops-nix)
- [shells/README.md](shells/README.md) (for advanced shell usage)

---

For advanced usage, adding new environments, or best practices, see the detailed [`shells/README.md`](shells/README.md).
