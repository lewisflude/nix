# Nix Config — AI Guidelines

**Read [`AGENTS.md`](AGENTS.md) first.** It is the canonical instruction file
for all agents in this repo; this file exists because Claude Code loads it
automatically.

The three rules that must never be violated, restated here so they are always in
context:

- **Never rebuild systems** — no `nh os switch`, `sudo nixos-rebuild`,
  `sudo darwin-rebuild`. Suggest commands for the user to run.
- **Never create docs/scripts** — no new `.md` or `.sh` files without explicit
  permission. Update existing files instead.
- **Use POG scripts** (`pkgs/pog-scripts/`) for new CLI tools. `scripts/` holds
  pre-existing one-off diagnostics — fix them in place, never add to them.

Everything else lives in:

- [`AGENTS.md`](AGENTS.md) — orientation, architecture, verification protocol,
  commands
- [`DENDRITIC_PATTERN.md`](DENDRITIC_PATTERN.md) — module architecture (also
  available as the `/dendritic-pattern` skill)
- [`NIX_PRACTICES.md`](NIX_PRACTICES.md) — Nix language, packaging, options,
  secrets, and the review checklist
