# CODEX.md

This file guides the ChatGPT Codex CLI when working with this repository.

## Overview

This project contains a flake-based Nix configuration supporting both macOS (nix-darwin) and Linux (NixOS). It shares Home Manager modules across platforms and provides reproducible development shells.

### Key Directories
- `flake.nix` – main flake entry
- `hosts/` – per-host system configs
- `modules/` – reusable system modules (`common`, `darwin`, `nixos`)
- `home/` – Home Manager modules
- `shells/` – development environments and `.envrc` templates
- `config-vars.nix` – user preferences
- `secrets/` – SOPS-encrypted secrets

## Typical Commands
```bash
# Build and switch
sudo darwin-rebuild switch --flake ~/.config/nix#<hostname>
sudo nixos-rebuild switch --flake ~/.config/nix#<hostname>

# Update inputs and format
nix flake update
nix fmt

# Launch development shell
nix develop ~/.config/nix#shell-selector
select_dev_shell
```

## Coding Guidelines
- Keep cross-platform logic in `common/` directories
- Use helpers from `lib/functions.nix` for platform detection
- Run `nix fmt` before committing
- Validate changes with `nix flake check`
- Document non-obvious configuration choices
