# Nix Config — AI Guidelines

## Critical Rules

- **Never rebuild systems** — no `nh os switch`, `sudo nixos-rebuild`,
  `sudo darwin-rebuild`. Suggest commands for the user to run.
- **Never create docs/scripts** — no new `.md` or `.sh` files without explicit
  permission. Update existing files instead.
- **Use POG scripts** (`pkgs/pog-scripts/`) for new CLI tools, not shell
  scripts.

## Architecture

Dendritic pattern: every `.nix` file (except `flake.nix`) is a flake-parts
module. See @DENDRITIC_PATTERN.md for full reference. Use `/dendritic-pattern`
skill when writing modules.

Key rules:

- Two scopes: top-level (flake-parts `config.*`) and platform-level
  (NixOS/Darwin/home-manager)
- Share values via top-level `config.*` — no `specialArgs`
- Constants via `config.constants` — no direct imports
- Hosts compose features via imports; infrastructure only transforms

## Module Placement

- **`flake.modules.nixos.*`** — system services, kernel, hardware, daemons,
  boot, networking
- **`flake.modules.homeManager.*`** — user apps, dotfiles, dev tools, shell,
  editor, tray applets

## Common Tasks

- New module: `nix run .#new-module`
- Update deps: `nix run .#update-all`
- Format: `nix fmt`
- Check: `nix flake check`

## Conventions

- Conventional commits: `<type>(<scope>): <description>`
- Never use `with pkgs;` — use explicit `pkgs.package`
- Format all Nix with `nix fmt` (treefmt-nix)

## Verification Protocol (NixOS-Specific)

- **Use mcp-nixos** to verify NixOS options, Home Manager options, and package
  names exist before suggesting them. Never invent option paths.
- **Check flake.lock** for actual nixpkgs version in use before giving
  version-specific advice.
- **Use Context7** for library/framework docs when writing modules that
  configure third-party tools.
- **WebSearch** for niche packages or options you're uncertain about.
- If an option or package can't be verified, say so and suggest the user check
  with `nix search` or `man configuration.nix`.
