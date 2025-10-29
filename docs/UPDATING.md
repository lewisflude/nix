# Updating Dependencies Guide

This guide explains how to programmatically update git commit references in your Nix configuration.

## 🎯 Overview

Your Nix configuration has **two types** of git references:

1. **Flake Inputs** (in `flake.lock`) - managed by Nix
2. **Manual `fetchFromGitHub` calls** (in `.nix` files) - require manual or tool-based updates

## 🛠️ Available Tools

### 1. Update Everything (Recommended)

```bash
# Update all dependencies
./scripts/maintenance/update-all.sh

# Preview what would be updated
./scripts/maintenance/update-all.sh --dry-run

# Update only flake inputs
./scripts/maintenance/update-all.sh --skip-plugins
```

### 2. Update Flake Inputs Only

```bash
# Update all inputs
nix flake update

# Update specific input
nix flake update nixpkgs
nix flake update home-manager
nix flake update ghostty

# Preview changes
nix flake lock --update-input nixpkgs --dry-run

# Using the script (includes validation)
./scripts/maintenance/update-flake.sh
```

### 3. Update ZSH Plugins

If using the `nvfetcher` approach:

```bash
./scripts/maintenance/update-zsh-plugins.sh
```

Manual approach with nix-update:

```bash
# Enter devShell (has nix-update)
nix develop

# Update a specific package
nix-update --override-filename path/to/package.nix

# Update to specific version
nix-update --version=1.2.3 --override-filename path/to/package.nix
```

### 4. Update Individual Package

For any `fetchFromGitHub` reference:

```bash
# Use integrated update-all script (recommended)
nix run .#update-all

# Or enter devShell for manual control
nix develop

# Update package to latest
nix-update --override-filename path/to/package.nix

# Update with build verification
nix-update --build --override-filename path/to/package.nix
```

See `docs/NIX_UPDATE_GUIDE.md` for full documentation.

## 📋 Current Manual References

Your configuration currently has these manual git references:

### ZSH Plugins (`home/common/shell.nix`)

| Plugin | Owner/Repo | Current Rev |
|--------|-----------|-------------|
| zsh-defer | romkatv/zsh-defer | `53a26e28...` |
| zsh-autopair | hlissner/zsh-autopair | `396c38a7...` |
| zsh-bd | Tarrasch/zsh-bd | `d4a55e66...` |
| zsh_codex | tom-doerr/zsh_codex | `6ede649f...` |

### Home Assistant Component

| Package | Owner/Repo | Current Version |
|---------|-----------|-----------------|
| home-llm | acon96/home-llm | v0.3.9 |

## 🔄 Recommended Workflow

### Weekly/Monthly Updates

```bash
# 1. Create a branch
git checkout -b updates/$(date +%Y-%m-%d)

# 2. Run full update
nix run .#update-all

# 3. Review changes
git diff

# 4. Test build (Darwin)
nh os build --dry

# 5. Commit and test
git add -A
git commit -m "chore: update dependencies $(date +%Y-%m-%d)"

# 6. Actually build and test
nh os switch
```

### Update Specific Component

```bash
# Just nixpkgs
nix flake update nixpkgs

# Just custom packages
nix run .#update-all -- --skip-flake --skip-plugins

# Review and commit
git add flake.lock
git commit -m "chore: update nixpkgs"
```

## 🚀 Automated Updates

You already have GitHub Actions set up:

- `.github/workflows/update-flake.yml` - Weekly flake updates
- `.github/workflows/update-workflow.yml` - Workflow updates

To enable automated PRs, ensure the workflow has permissions to create PRs.

## 🔧 Advanced: Migrate to nvfetcher

For better automation, consider migrating your ZSH plugins to `nvfetcher`:

1. **Configuration created**: `home/common/zsh-plugins.toml`
2. **Update script created**: `scripts/maintenance/update-zsh-plugins.sh`
3. **To migrate**: Modify `shell.nix` to use generated sources

### Example Migration

Instead of:

```nix
src = pkgs.fetchFromGitHub {
  owner = "romkatv";
  repo = "zsh-defer";
  rev = "53a26e287fbbe2dcebb3aa1801546c6de32416fa";
  sha256 = "sha256-MFlvAnPCknSgkW3RFA8pfxMZZS/JbyF3aMsJj9uHHVU=";
};
```

Use:

```nix
# At top of file
let
  sources = import ./_sources/generated.nix { inherit (pkgs) fetchgit fetchFromGitHub; };
in
{
  # ...
  src = sources.zsh-defer;
}
```

Then update all plugins with:

```bash
./scripts/maintenance/update-zsh-plugins.sh
```

## 📚 Tool Reference

### Built-in Nix Commands

```bash
# Flake operations
nix flake update                    # Update all inputs
nix flake update <input>            # Update specific input
nix flake lock --update-input <in>  # Same as above
nix flake metadata                  # Show current versions

# Hash fetching
nix-prefetch-url <url>             # Get hash for URL
nix-prefetch-git <repo>            # Get hash for git repo
```

### Third-party Tools

```bash
# nix-prefetch-github - Easy GitHub fetching
nix-shell -p nix-prefetch-github --run "nix-prefetch-github owner repo"

# nix-update - Automated package updates
nix-shell -p nix-update --run "nix-update package-name"

# nvfetcher - Batch source updates
nix-shell -p nvfetcher --run "nvfetcher build"
```

## 🐛 Troubleshooting

### Cross-Platform Configuration Error

If you see an error like "required system or feature not available":

```
error: Cannot build '/nix/store/...'.
Reason: required system or feature not available
Required system: 'x86_64-linux' with features {}
Current system: 'aarch64-darwin' with features {...}
```

**This is normal!** You're on macOS trying to validate a NixOS configuration (or vice versa).

**Solution:** The update scripts have been fixed to only check your current system's configuration.

If you need to check a specific configuration:

```bash
# Check darwin config
./scripts/maintenance/check-config.sh Lewiss-MacBook-Pro darwin

# Check nixos config (on linux machine)
./scripts/maintenance/check-config.sh jupiter nixos
```

### Hash Mismatch

If you get a hash mismatch error:

```bash
# Method 1: Let Nix tell you the correct hash
# (Set hash to empty string and run build)

# Method 2: Use nix-prefetch
nix-prefetch-github owner repo --rev <commit-hash>

# Method 3: Use nix flake prefetch
nix flake prefetch github:owner/repo/<rev>
```

### Build Fails After Update

```bash
# Revert flake.lock
git checkout flake.lock

# Or revert everything
git reset --hard HEAD

# Then update one input at a time
nix flake update nixpkgs
# test
nix flake update home-manager
# test
```

### Update Breaks Configuration

```bash
# Pin to previous working version in flake.nix
inputs.nixpkgs.url = "github:nixos/nixpkgs/<commit-hash>";

# Then run
nix flake update
```

## 📅 Update Schedule

Recommended update frequency:

- **nixpkgs**: Weekly (follows unstable)
- **home-manager**: Weekly (follows nixpkgs)
- **Other flake inputs**: Monthly
- **Manual fetchFromGitHub**: Monthly or as needed
- **Security updates**: Immediately

## 🔗 Useful Links

- [Nix Flakes Reference](https://nixos.wiki/wiki/Flakes)
- [nix-update GitHub](https://github.com/Mic92/nix-update)
- [nvfetcher GitHub](https://github.com/berberman/nvfetcher)
- [nix-prefetch-github](https://github.com/seppeljordan/nix-prefetch-github)
