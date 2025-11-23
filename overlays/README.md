# Overlays Directory

This directory contains Nix overlays for custom packages and package overrides.

## Structure

- `default.nix` - Main overlay file containing all overlays
- `sources.toml` - nvfetcher configuration for batch source updates
- `npm-packages.nix` - Custom NPM packages overlay

## Current Overlays

### gemini-cli-latest

Overrides nixpkgs `gemini-cli` with the latest version from GitHub.

**Update Methods:**

1. **updateScript** (Recommended):

   ```bash
   # Run the updateScript
   nix eval --raw '.#overlays.gemini-cli-latest.gemini-cli.passthru.updateScript' | bash
   ```

2. **nix-update**:

   ```bash
   nix-update gemini-cli-latest --override-filename overlays/default.nix
   ```

3. **nvfetcher** (Batch updates):

   ```bash
   nvfetcher -c overlays/sources.toml -o overlays/_sources
   # Then update default.nix to use sources.gemini-cli
   ```

**Note:** After updating version/hash, you'll need to update `npmDepsHash`:

```bash
nix build .#gemini-cli-latest.gemini-cli
# Copy the npmDepsHash from the error message
```

### claude-code-overlay

Uses the `github:ryoppippi/claude-code-overlay` flake input.

**Update:**

```bash
nix flake update claude-code-overlay
```

The overlay maintainer handles version updates automatically.

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

The workflow:

- Runs the `updateScript` for gemini-cli
- Updates flake inputs (claude-code-overlay)
- Creates a PR with changes

## Adding New Overlays

1. Add overlay to `overlays/default.nix`
2. Optionally add to `overlays/sources.toml` for nvfetcher
3. Add `updateScript` if you want automated updates
4. Update `.github/workflows/update-overlays.yml` if needed

## References

- [NixOS Overlays Documentation](https://nixos.org/manual/nixpkgs/stable/#chap-overlays)
- [nvfetcher](https://github.com/berberman/nvfetcher)
- [nix-update](https://github.com/Mic92/nix-update)
