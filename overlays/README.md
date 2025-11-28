# Overlays Directory

This directory contains Nix overlays for custom packages and package overrides.

## Structure

- `default.nix` - Main overlay file containing all overlays
- `sources.toml` - nvfetcher configuration for batch source updates

## Current Overlays

Using nixpkgs versions of packages where available (cursor, claude-code, gemini-cli, etc.).

**Available overlays:**

- `nh` - Nix helper tool
- `nix-topology` - Network topology visualization
- `flake-editors` - Stable zed-editor from nixpkgs
- `fenix-overlay` - Rust toolchains
- `flake-git-tools` - Lazygit from flake
- `flake-cli-tools` - Atuin from flake
- `niri` - Niri compositor (Linux only)
- `comfyui` - ComfyUI native package

## Using nvfetcher

nvfetcher provides declarative source management for batch updates.

### Setup

1. Define sources in `sources.toml`:

   ```toml
   [gemini-cli]
   src.github = "google-gemini/gemini-cli"
   fetch.github = "owner=google-gemini,repo=gemini-cli"
   git.tag = "latest"
   ```

2. Generate sources:

   ```bash
   nvfetcher -c overlays/sources.toml -o overlays/_sources
   ```

3. Use in overlay:

   ```nix
   let
     sources = import ./_sources/generated.nix { inherit (prev) fetchFromGitHub; };
   in
   {
     gemini-cli-latest = _final: prev: {
       gemini-cli = prev.buildNpmPackage {
         src = sources.gemini-cli;
         # ... rest of config
       };
     };
   }
   ```

### Benefits

- Declarative source management
- Batch updates with one command
- Automatic hash generation
- Works well with CI/CD

### Limitations

- For packages requiring additional hashes (like `npmDepsHash`), you still need to update those manually
- Some packages may need custom fetch logic

## Automated Updates

See `.github/workflows/update-overlays.yml` for automated weekly updates via GitHub Actions.

The workflow updates flake inputs that provide overlays.

## Adding New Overlays

1. Add overlay to `overlays/default.nix`
2. Optionally add to `overlays/sources.toml` for nvfetcher
3. Add `updateScript` if you want automated updates
4. Update `.github/workflows/update-overlays.yml` if needed

## References

- [NixOS Overlays Documentation](https://nixos.org/manual/nixpkgs/stable/#chap-overlays)
- [nvfetcher](https://github.com/berberman/nvfetcher)
- [nix-update](https://github.com/Mic92/nix-update)
