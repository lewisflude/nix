# AGENTS.md

Entry point for AI coding agents working in this repository. Written to the
[AGENTS.md](https://agents.md) convention, so Claude Code, Codex, Cursor,
Copilot, Gemini CLI, Zed, Aider and others read the same instructions.

Humans: start with [`README.md`](README.md) instead.

## Critical rules

1. **Never rebuild or activate systems.** No `nh os switch`,
   `sudo nixos-rebuild`, `sudo darwin-rebuild`. Building and evaluating is fine;
   activation is the user's call. Propose the command, do not run it.
2. **Never create new `.md` or `.sh` files** without explicit permission. Update
   existing files instead.
3. **Use POG scripts** (`pkgs/pog-scripts/`) for new CLI tooling. `scripts/`
   holds pre-existing one-off diagnostics — fix them in place, never add to
   them.

## Documentation map

| Read this               | When                                                    |
| ----------------------- | ------------------------------------------------------- |
| `AGENTS.md` (this file) | Always — orientation and critical rules                 |
| `DENDRITIC_PATTERN.md`  | Writing, creating, or refactoring any `.nix` module     |
| `NIX_PRACTICES.md`      | Nix language, packaging, options, secrets, verification |
| `README.md`             | Repo layout, hosts, common commands                     |
| `CLAUDE.md`             | Claude Code pointer to this file                        |

Claude Code users also have a `/dendritic-pattern` skill and a `nix-module`
subagent, both defined in `pkgs/claude-code/`.

## Architecture in one paragraph

Dendritic pattern: every `.nix` file except `flake.nix` is a flake-parts module,
auto-imported by import-tree. There are two scopes of `config` — top-level
(flake-parts) and platform-level (NixOS / Darwin / Home Manager). Values are
shared through top-level `config.*` (notably `config.constants`), never through
`specialArgs` or direct `import`. Hosts compose features by importing from
`config.flake.modules`; infrastructure modules only transform. Full reference:
`DENDRITIC_PATTERN.md`.

Module placement:

- `flake.modules.nixos.*` — system services, kernel, hardware, daemons, boot,
  networking
- `flake.modules.homeManager.*` — user apps, dotfiles, dev tools, shell, editor,
  tray applets

## Before you write Nix

Read `NIX_PRACTICES.md`. The short version:

- No `with pkgs;`, no `rec` where `let` works, no `<nixpkgs>`, no `--impure`
- No secrets in the store — reference `config.sops.secrets.<NAME>.path`
- `lib.mkIf` / `lib.optionals` inside config, never `if` around a config block
- Home Manager modules must not set `nixpkgs.*` (this repo uses `useGlobalPkgs`)
- Do not touch `stateVersion`

## Verification protocol

- Verify every NixOS / Home Manager / nix-darwin option path and package name
  before suggesting it. Use the `nixos` MCP server if you have it, otherwise
  `nix search` and <https://search.nixos.org>. Never invent an option path; if
  you cannot verify one, say so.
- Check `flake.lock` for the nixpkgs revision actually in use before giving
  version-specific advice.
- Use Context7 for third-party library or framework docs.

## Commands

```bash
nix run .#new-module    # scaffold a module
nix run .#update-all    # update dependencies
nix fmt                 # nixfmt + statix + deadnix + prettier + shfmt
nix flake check         # evaluation + pre-commit hooks
```

Commit style: conventional commits, `<type>(<scope>): <description>`.
