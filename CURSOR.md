# CURSOR.md

> **📍 Documentation Moved:** This guide has been consolidated into [`docs/ai-assistants/`](docs/ai-assistants/) for better organization.
>
> **→ Go to:** [`docs/ai-assistants/README.md`](docs/ai-assistants/README.md) for the complete AI assistant guide.

---

This guide provides Cursor AI with an overview of the repository.

The project defines a cross-platform Nix setup using flakes. Both macOS and Linux machines share Home Manager modules, and development shells in `shells/` offer reproducible tooling for multiple languages.

## Important Locations
- `hosts/` – per-host system configurations
- `modules/` – system modules (`common`, `darwin`, `nixos`)
- `home/` – user-level Home Manager modules
- `shells/` – dev shells and direnv templates
- `lib/` – helper functions

Coding conventions and AI behaviour are configured under `.cursor/rules`. Format Nix files with `nix fmt` and consult `README.md` or `CLAUDE.md` for deeper details. Global style guidance lives in `home/common/apps/cursor/global-cursor-rules.md`.
