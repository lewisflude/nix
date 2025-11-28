# AI Tools Update - Flake Integration

This document summarizes the updates made to integrate official/unofficial Nix flakes for AI coding tools.

## Changes Made

### 1. Claude Code - Pre-built Binary Overlay ✅

**Added:** `github:ryoppippi/claude-code-overlay`

**Benefits:**

- Uses official pre-built binaries from Anthropic (faster than Node.js builds)
- Automated hourly updates via GitHub Actions
- Lower memory footprint and faster startup
- Direct from Anthropic's distribution servers

**Files Modified:**

- `flake.nix` - Added claude-code-overlay input
- `overlays/default.nix` - Added claude-code-overlay overlay
- `home/common/apps/claude-code.nix` - Updated to use overlay version

**Status:** Ready to use. The overlay automatically provides `pkgs.claude-code` which will be used by `programs.claude-code`.

**Update:** Just run `nix flake update claude-code-overlay` - the overlay maintainer handles version updates.

### 2. Cursor - Use nixpkgs code-cursor for Linux ✅

**Changed:** Now uses `pkgs.code-cursor` from nixpkgs-unstable for Linux

**Benefits:**

- Automatically maintained by nixpkgs
- No manual version updates needed
- Better integration with NixOS

**Files Modified:**

- `home/common/apps/cursor/default.nix` - Updated to use `pkgs.code-cursor` on Linux

**Status:** Ready to use. Falls back to custom cursor package for Darwin.

**Update:** Just run `nix flake update nixpkgs` - updates come automatically.

### 3. Gemini CLI - Latest Version from GitHub ✅

**Added:** Custom overlay to build latest version from GitHub source

**Current Version:** `0.19.0-nightly.20251123.dadd606c0` (latest from GitHub)
**Previous Version:** `0.15.3` (from nixpkgs)

**Files Modified:**

- `overlays/default.nix` - Added gemini-cli-latest overlay with `updateScript`

**Status:** ✅ Fully automated with multiple update methods

**Update Methods:**

1. **updateScript** (Built-in):

   ```bash
   nix eval --raw '.#overlays.gemini-cli-latest.gemini-cli.passthru.updateScript' | bash
   ```

2. **nix-update**:

   ```bash
   nix-update gemini-cli-latest --override-filename overlays/default.nix
   ```

3. **GitHub Actions** (Automated):
   - Runs weekly via `.github/workflows/update-overlays.yml`
   - Creates PRs automatically

4. **nvfetcher** (Batch updates):

   ```bash
   nvfetcher -c overlays/sources.toml -o overlays/_sources
   ```

**Note:** After updating version/hash, you'll need to update `npmDepsHash`:

```bash
nix build .#gemini-cli-latest.gemini-cli
# Copy the npmDepsHash from the error message
```

## Automation Setup

### GitHub Actions Workflow

Created `.github/workflows/update-overlays.yml` that:

- Runs weekly on Mondays
- Updates gemini-cli overlay using `updateScript`
- Updates flake inputs (claude-code-overlay)
- Creates PRs with changes automatically

### nvfetcher Configuration

Created `overlays/sources.toml` for batch source management:

- Declarative source definitions
- Batch updates with one command
- Integrated into `nix run .#update-all`

## Next Steps

### 1. Update Flake Lock

```bash
# Update flake inputs to fetch the new claude-code-overlay
nix flake update

# Or update just the new input
nix flake update claude-code-overlay
```

### 2. Test the Changes

```bash
# Validate the flake builds
nix flake check

# Test home-manager configuration
nix build .#homeConfigurations.$(hostname)

# If successful, rebuild (user must run this)
# nh os switch  # or your preferred rebuild command
```

### 3. Get npmDepsHash for Gemini CLI

The gemini-cli overlay uses a placeholder `npmDepsHash`. On first build, nix will provide the correct hash:

```bash
# Try to build (will fail with correct hash)
nix build .#gemini-cli-latest.gemini-cli

# Copy the correct npmDepsHash from the error message
# Update overlays/default.nix with the correct hash
```

**Alternative:** The GitHub Actions workflow will attempt to get this automatically.

## Version Comparison

| Tool | Previous | New | Source | Update Method |
|------|----------|-----|--------|---------------|
| **claude-code** | `2.0.42` (nixpkgs) | Latest (overlay) | `github:ryoppippi/claude-code-overlay` | `nix flake update claude-code-overlay` |
| **cursor** | `2.0.69` (custom) | Latest (nixpkgs) | `pkgs.code-cursor` (Linux only) | `nix flake update nixpkgs` |
| **gemini-cli** | `0.15.3` (nixpkgs) | `0.19.0-nightly` (GitHub) | Custom overlay | `updateScript` or `nix-update` |

## Benefits Summary

1. **Claude Code**: Faster startup, lower memory, official binaries, automated updates
2. **Cursor**: Automatic updates via nixpkgs, less maintenance
3. **Gemini CLI**: Latest features from GitHub, multiple update methods, fully automated

## Automation Features

✅ **updateScript** - Built into gemini-cli overlay for easy updates
✅ **GitHub Actions** - Weekly automated updates with PR creation
✅ **nvfetcher** - Batch source management for future overlays
✅ **nix-update** - Manual update tool integration

## Troubleshooting

### Claude Code Not Using Overlay Version

If `programs.claude-code` still uses the nixpkgs version:

- Check that `claude-code-overlay` is in `flake.nix` inputs
- Verify overlay is applied in `overlays/default.nix`
- Run `nix flake update claude-code-overlay`

### Gemini CLI Build Fails

The first build will fail with an error message containing the correct `npmDepsHash`. Update `overlays/default.nix` with the provided hash.

**Or** wait for the GitHub Actions workflow to handle it automatically.

### Cursor Not Using code-cursor

On Linux, verify `pkgs.code-cursor` is available:

```bash
nix eval nixpkgs#code-cursor.version
```

If unavailable, the configuration falls back to the custom cursor package.

## References

- [claude-code-overlay](https://github.com/ryoppippi/claude-code-overlay)
- [cursor-flake](https://github.com/omarcresp/cursor-flake) (alternative, not used)
- [gemini-cli GitHub](https://github.com/google-gemini/gemini-cli)
- [Automated Overlay Updates Guide](docs/AUTOMATED_OVERLAY_UPDATES.md)
- [Overlays README](overlays/README.md)
