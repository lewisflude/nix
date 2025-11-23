# Automated GitHub Hash Overlay Updates

This guide explains how NixOS and nix-darwin users automatically keep their GitHub hash overlays up to date with the latest versions.

## Overview

There are several approaches to automatically update GitHub hash overlays:

1. **`updateScript` passthru** - Built into packages, can be run manually or via automation
2. **`nix-update`** - Community tool for updating package versions and hashes
3. **`nvfetcher`** - Batch source updates with TOML configuration
4. **GitHub Actions** - Automated CI/CD workflows
5. **`nixpkgs-update` / `r-ryantm`** - Automated services (for nixpkgs contributions)

## Method 1: `updateScript` Passthru (Recommended for Overlays)

Many overlays provide an `updateScript` in their `passthru` attribute that can automatically fetch the latest version and update hashes.

### How It Works

When a package has `passthru.updateScript`, you can run:

```bash
# Run the update script for a specific package
nix-shell -p nix-update --run "nix-update <package-name>"

# Or if the package exposes updateScript directly
nix-shell -p <package> --run "nix eval --raw '<package>.passthru.updateScript' | bash"
```

### Example: claude-code-overlay

The `claude-code-overlay` we just added has an `updateScript`:

```nix
passthru = {
  updateScript = ./update;
};
```

To update it:

```bash
# Method 1: Use nix-update (if it detects the updateScript)
nix-update claude-code --flake

# Method 2: Run the update script directly
cd $(nix eval --raw 'github:ryoppippi/claude-code-overlay#default.outPath')
./update
```

### Adding updateScript to Your Overlays

For your custom overlays (like `gemini-cli-latest`), you can add an `updateScript`:

```nix
# overlays/default.nix
gemini-cli-latest = _final: prev: {
  gemini-cli = prev.buildNpmPackage rec {
    # ... existing config ...

    passthru = {
      updateScript = prev.writeShellScript "update-gemini-cli" ''
        set -euo pipefail

        # Get latest version from GitHub API
        LATEST_VERSION=$(curl -s https://api.github.com/repos/google-gemini/gemini-cli/releases/latest | \
          jq -r '.tag_name' | sed 's/^v//')

        # Get latest commit hash
        LATEST_REV=$(curl -s "https://api.github.com/repos/google-gemini/gemini-cli/commits/main" | \
          jq -r '.sha')

        # Update the overlay file
        sed -i "s/version = \".*\";/version = \"$LATEST_VERSION\";/" overlays/default.nix
        sed -i "s/rev = \".*\";/rev = \"v$LATEST_VERSION\";/" overlays/default.nix

        # Get new hash
        NEW_HASH=$(nix-prefetch-github google-gemini gemini-cli --rev "v$LATEST_VERSION" | jq -r '.hash')
        sed -i "s|hash = \".*\";|hash = \"$NEW_HASH\";|" overlays/default.nix

        # Get npmDepsHash (this requires building, so we'll need to handle it)
        echo "Updated to version $LATEST_VERSION"
        echo "⚠️  You'll need to update npmDepsHash manually after building"
      '';
    };
  };
};
```

## Method 2: `nix-update` (Most Common)

`nix-update` is the community standard tool for updating package versions and hashes.

### Installation

```bash
# Already in your devShell
nix develop

# Or install globally
home.packages = [ pkgs.nix-update ];
```

### Usage

```bash
# Update a package in your overlay
nix-update gemini-cli-latest --override-filename overlays/default.nix

# Update with automatic hash fetching
nix-update gemini-cli-latest --override-filename overlays/default.nix --version=latest

# Update and commit automatically
nix-update gemini-cli-latest --override-filename overlays/default.nix --commit
```

### Supported Hash Types

`nix-update` automatically handles:

- `sha256`, `hash` - Source hashes
- `vendorHash` - Go modules
- `cargoHash`, `cargoSha256` - Rust packages
- `npmDepsHash` - Node packages (requires build)
- `mvnHash` - Maven packages

### For npmDepsHash

For `npmDepsHash`, `nix-update` will:

1. Update the version and source hash
2. Attempt to build to get `npmDepsHash`
3. If build fails, it will show you the correct hash in the error

```bash
# This will try to build and get npmDepsHash
nix-update gemini-cli-latest --override-filename overlays/default.nix --build
```

## Method 3: `nvfetcher` (Batch Updates)

`nvfetcher` is excellent for managing multiple GitHub sources in a declarative way.

### Setup

1. Create a TOML file for your sources:

```toml
# overlays/sources.toml
[gemini-cli]
src.github = "google-gemini/gemini-cli"
fetch.github = "owner=google-gemini,repo=gemini-cli"
```

2. Generate sources:

```bash
nvfetcher -c overlays/sources.toml
```

3. Use in your overlay:

```nix
# overlays/default.nix
let
  sources = import ./_sources/generated.nix { inherit (prev) fetchFromGitHub; };
in
{
  gemini-cli-latest = _final: prev: {
    gemini-cli = prev.buildNpmPackage {
      src = sources.gemini-cli;
      # ... rest of config ...
    };
  };
}
```

4. Update all sources:

```bash
nvfetcher -c overlays/sources.toml
```

### Benefits

- Declarative source management
- Batch updates with one command
- Automatic hash generation
- Works well with CI/CD

## Method 4: GitHub Actions Automation

Automate updates via GitHub Actions workflows.

### Example Workflow

```yaml
# .github/workflows/update-overlays.yml
name: Update Overlays

on:
  schedule:
    # Run weekly on Monday
    - cron: '0 0 * * 1'
  workflow_dispatch:

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5

      - uses: DeterminateSystems/nix-installer-action@v21

      - name: Update gemini-cli
        run: |
          nix-update gemini-cli-latest \
            --override-filename overlays/default.nix \
            --version=latest \
            --commit \
            --commit-message "chore: update gemini-cli to latest"

      - name: Create PR
        uses: peter-evans/create-pull-request@v5
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          commit-message: "chore: update overlays"
          title: "chore: update overlays"
          body: "Automated overlay updates"
          branch: update/overlays
```

### Using updateScript in CI

```yaml
- name: Update claude-code
  run: |
    # Clone the overlay repo temporarily
    git clone --depth 1 https://github.com/ryoppippi/claude-code-overlay /tmp/claude-overlay
    cd /tmp/claude-overlay
    ./update

    # The update script updates sources.json, commit it
    git diff sources.json
    # Then update your flake lock
    cd ${{ github.workspace }}
    nix flake update claude-code-overlay
```

## Method 5: Automated Services (For nixpkgs)

For packages you want to contribute to nixpkgs:

- **`nixpkgs-update`** - Automated PR bot for nixpkgs
- **`r-ryantm`** - Automated version bumping service

These are mainly for nixpkgs contributions, not personal overlays.

## Recommended Approach for Your Setup

Based on your current configuration, here's the recommended approach:

### For claude-code-overlay

Since it's a flake input with its own `updateScript`, you can:

1. **Manual**: Just update the flake input

   ```bash
   nix flake update claude-code-overlay
   ```

2. **Automated**: The overlay maintainer runs their own update script, so you just need to update the flake input periodically.

### For gemini-cli-latest (Custom Overlay)

1. **Add updateScript** (see example above)
2. **Use nix-update** for manual updates:

   ```bash
   nix-update gemini-cli-latest --override-filename overlays/default.nix
   ```

3. **Automate with GitHub Actions** (see workflow example above)

### For cursor (Using nixpkgs code-cursor)

No manual updates needed! `nix flake update nixpkgs` will bring in the latest version automatically.

## Complete Automation Example

Here's a complete setup for automating your overlay updates:

### 1. Add updateScript to gemini-cli overlay

```nix
# overlays/default.nix
gemini-cli-latest = _final: prev: {
  gemini-cli = prev.buildNpmPackage rec {
    # ... existing config ...

    passthru = {
      updateScript = prev.writeShellScript "update-gemini-cli" ''
        #!/usr/bin/env bash
        set -euo pipefail

        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        OVERLAY_FILE="$SCRIPT_DIR/overlays/default.nix"

        # Get latest version
        LATEST=$(curl -s https://api.github.com/repos/google-gemini/gemini-cli/releases/latest | \
          jq -r '.tag_name' | sed 's/^v//')

        # Update version
        sed -i "s/version = \".*\";/version = \"$LATEST\";/" "$OVERLAY_FILE"
        sed -i "s/rev = \".*\";/rev = \"v$LATEST\";/" "$OVERLAY_FILE"

        # Get new hash
        HASH=$(nix-prefetch-github google-gemini gemini-cli --rev "v$LATEST" | jq -r '.hash')
        sed -i "s|hash = \".*\";|hash = \"$HASH\";|" "$OVERLAY_FILE"

        echo "Updated gemini-cli to $LATEST"
        echo "⚠️  Run 'nix build' to get npmDepsHash"
      '';
    };
  };
};
```

### 2. Create GitHub Actions Workflow

```yaml
# .github/workflows/update-overlays.yml
name: Update Overlays

on:
  schedule:
    - cron: '0 0 * * 1'  # Weekly on Monday
  workflow_dispatch:

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
        with:
          token: ${{ secrets.GITHUB_TOKEN }}

      - uses: DeterminateSystems/nix-installer-action@v21

      - name: Update gemini-cli
        run: |
          nix-update gemini-cli-latest \
            --override-filename overlays/default.nix \
            --version=latest

      - name: Get npmDepsHash
        run: |
          # Try to build to get npmDepsHash
          nix build .#gemini-cli-latest.gemini-cli 2>&1 | \
            grep -oP 'got:\s+sha256-\S+' | \
            head -1 | \
            sed 's/got: //' > /tmp/npmhash || true

          if [ -s /tmp/npmhash ]; then
            HASH=$(cat /tmp/npmhash)
            sed -i "s|npmDepsHash = \".*\";|npmDepsHash = \"$HASH\";|" overlays/default.nix
          fi

      - name: Create PR
        uses: peter-evans/create-pull-request@v5
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          commit-message: "chore: update gemini-cli overlay"
          title: "chore: update gemini-cli overlay"
          branch: update/gemini-cli
```

## Summary

| Method | Best For | Automation Level |
|--------|----------|------------------|
| **updateScript** | Packages with built-in update logic | Manual or CI |
| **nix-update** | General package updates | Manual or CI |
| **nvfetcher** | Multiple sources, batch updates | Manual or CI |
| **GitHub Actions** | Fully automated updates | Fully automated |
| **Flake inputs** | External overlays (like claude-code) | Just update flake |

## Quick Reference

```bash
# Update flake inputs (includes claude-code-overlay)
nix flake update

# Update custom overlay with nix-update
nix-update gemini-cli-latest --override-filename overlays/default.nix

# Update using updateScript (if available)
nix-shell -p <package> --run "nix eval --raw '<package>.passthru.updateScript' | bash"

# Batch update with nvfetcher
nvfetcher -c overlays/sources.toml
```

## References

- [nix-update](https://github.com/Mic92/nix-update) - Package update tool
- [nvfetcher](https://github.com/berberman/nvfetcher) - Batch source fetcher
- [NixOS updateScript documentation](https://nixos.org/manual/nixpkgs/stable/#sec-passthru-updateScript)
- [claude-code-overlay](https://github.com/ryoppippi/claude-code-overlay) - Example overlay with updateScript
