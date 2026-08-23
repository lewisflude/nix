# Nix Configuration

[![CI](https://github.com/lewisflude/nix/workflows/CI/badge.svg)](https://github.com/lewisflude/nix/actions/workflows/ci.yml)
[![Nix Flake](https://img.shields.io/badge/nix-flake-blue.svg)](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html)
[![NixOS 25.05](https://img.shields.io/badge/NixOS-25.05-blue.svg)](https://nixos.org)
[![nix-darwin](https://img.shields.io/badge/nix--darwin-supported-blue.svg)](https://github.com/LnL7/nix-darwin)

A cross-platform Nix configuration for NixOS (Linux) and nix-darwin (macOS),
using the **dendritic pattern** with flake-parts.

## Architecture

This configuration uses the
[dendritic pattern](https://github.com/snowfallorg/dendritic) - every `.nix`
file (except `flake.nix`) is a flake-parts module.

### Structure

```
.
├── flake.nix                 # Flake entry point (only non-module)
├── modules/                  # All flake-parts modules
│   ├── infrastructure/       # System builders (NixOS, Darwin, Home Manager)
│   ├── hosts/                # Host definitions (compose features)
│   │   ├── jupiter/          # Linux workstation
│   │   └── mercury/          # macOS laptop
│   ├── per-system/           # perSystem outputs (treefmt, checks, apps, shells)
│   ├── shell/                # Shell configuration (zsh, prompt, integrations)
│   ├── options/              # Option declarations
│   ├── constants.nix         # Shared constants (config.constants)
│   ├── meta.nix              # Shared metadata (config.username, etc.)
│   └── *.nix                 # Feature modules (one file per feature)
├── overlays/                 # nixpkgs overlays + nvfetcher sources
├── secrets/                  # SOPS-encrypted secrets
├── templates/                # Module scaffolding templates
├── scripts/                  # Pre-existing one-off diagnostic scripts
└── pkgs/                     # Custom packages and POG scripts
```

### How It Works

1. **Feature modules** define `flake.modules.nixos.*` and
   `flake.modules.homeManager.*`
2. **Host definitions** compose features by importing from
   `config.flake.modules`
3. **Infrastructure modules** transform host definitions into system outputs
4. **Values flow through `config.*`**, not `specialArgs` or direct imports

Example module:

```nix
# modules/shell.nix
{ config, lib, ... }:
{
  flake.modules.homeManager.shell = nixosArgs: {
    programs.fish.enable = true;
    home.sessionVariables.EDITOR = "hx";
  };
}
```

Example host definition:

```nix
# modules/hosts/jupiter/definition.nix
{ config, ... }:
let
  inherit (config.flake.modules) nixos homeManager;
in
{
  configurations.nixos.jupiter.module = {
    imports = [
      nixos.base
      nixos.audio
      nixos.gaming
    ];
  };

  configurations.homeManager."lewis@jupiter".module = {
    imports = [
      homeManager.shell
      homeManager.git
    ];
  };
}
```

## Quick Start

### Prerequisites

- **macOS** (10.14+) or **Linux**
- Internet connection

### 1. Install Nix

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### 2. Clone

```bash
git clone https://github.com/lewisflude/nix.git ~/.config/nix
cd ~/.config/nix
```

### 3. Build

```bash
# NixOS
sudo nixos-rebuild switch --flake ~/.config/nix#jupiter

# nix-darwin (macOS)
darwin-rebuild switch --flake ~/.config/nix#mercury
```

### 4. Development Environment (Optional)

```bash
nix develop  # Sets up pre-commit hooks and formatters
```

## Documentation

| Document                                       | Description                                                   |
| ---------------------------------------------- | ------------------------------------------------------------- |
| [`DENDRITIC_PATTERN.md`](DENDRITIC_PATTERN.md) | Module architecture: invariants, anti-patterns, checklist     |
| [`NIX_PRACTICES.md`](NIX_PRACTICES.md)         | Nix/NixOS/Home Manager best practices and anti-patterns       |
| [`AGENTS.md`](AGENTS.md)                       | Instructions for AI coding agents (Claude, Codex, Copilot, …) |
| [`CLAUDE.md`](CLAUDE.md)                       | Claude Code entry point (points at `AGENTS.md`)               |

## Available Tools

### POG Scripts

Interactive CLI tools:

```bash
nix run .#new-module         # Create new modules interactively
nix run .#update-all         # Update flake inputs and ZSH plugins
nix run .#visualize-modules  # Generate module dependency graphs
nix run .#setup-cachix       # Configure Cachix binary cache
```

### Utility Scripts

Located in `scripts/`:

- `diagnose-qbittorrent-seeding.sh` - qBittorrent diagnostics
- `test-ssh-performance.sh` - SSH performance benchmarking
- `monitor-hdd-storage.sh` - Storage monitoring

## Common Tasks

| Task                  | Command                  |
| --------------------- | ------------------------ |
| Enter dev environment | `nix develop`            |
| Format code           | `nix fmt`                |
| Check configuration   | `nix flake check`        |
| Update dependencies   | `nix run .#update-all`   |
| Create module         | `nix run .#new-module`   |
| Garbage collect       | `nix-collect-garbage -d` |

## Binary Cache

Speed up builds with Cachix:

```bash
cachix use lewisflude-nix
```

## Key Concepts

### Two Scopes of `config`

```nix
{ config, ... }:                          # Outer: top-level flake-parts config
{
  flake.modules.nixos.myFeature = nixosArgs: {
    # nixosArgs.config is platform-level (NixOS/Darwin)
    users.users.${config.username}.shell = nixosArgs.config.programs.fish.package;
  };
}
```

### Constants Access

```nix
{ config, ... }:
{
  flake.modules.nixos.myService = { ... }: {
    services.app.port = config.constants.ports.services.app;
  };
}
```

### Anti-Patterns to Avoid

- `with pkgs;` - Use explicit package references
- `specialArgs` / `extraSpecialArgs` - Use `config.*` instead
- Direct imports (`import ../lib/foo.nix`) - Use `config.*` options
- Shadowing outer `config` in inner modules

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [nix-darwin Manual](https://daiderd.com/nix-darwin/manual/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [flake-parts Documentation](https://flake.parts/)
- [Dendritic Pattern](https://github.com/snowfallorg/dendritic)

## License

Personal configuration shared as reference material. Fork and adapt for your own
use.
