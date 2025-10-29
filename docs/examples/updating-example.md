# Updating Examples

Real-world examples of updating your Nix configuration.

## Example 1: Weekly Update Routine

```bash
# Monday morning - update everything
cd ~/.config/nix

# 1. Create an update branch
git checkout -b updates/2025-10-28

# 2. Run the master update script
./scripts/maintenance/update-all.sh

# Output:
# === 🚀 Starting Full Update Process ===
# [INFO] Flake directory: /Users/lewisflude/.config/nix
# 
# === 1️⃣  Updating Flake Inputs ===
# [INFO] Updating flake inputs...
# • Updated 'nixpkgs': 'github:NixOS/nixpkgs/6a08e6bb...' -> 'github:NixOS/nixpkgs/8f3c9fa...'
# • Updated 'home-manager': ...
# 
# === 2️⃣  Updating ZSH Plugins ===
# [INFO] ZSH plugins updated
# 
# === ✨ Done! ===

# 3. Review what changed
git diff

# 4. Test the build (dry run)
nh os build --dry

# 5. Commit
git add -A
git commit -m "chore: update dependencies 2025-10-28"

# 6. Actually apply
nh os switch

# 7. If everything works, merge and push
git checkout main
git merge updates/2025-10-28
git push
```

## Example 2: Update Just nixpkgs

```bash
# Only update nixpkgs (maybe there's a security fix)
cd ~/.config/nix

nix flake update nixpkgs

# Review changes
git diff flake.lock

# Test
nh os build --dry

# Commit
git add flake.lock
git commit -m "chore: update nixpkgs for security fix"

# Apply
nh os switch
```

## Example 3: Update a Single ZSH Plugin

```bash
cd ~/.config/nix

# Let's say zsh-defer has a new feature you want
./scripts/maintenance/update-git-hash.sh romkatv zsh-defer

# Output:
# [INFO] Fetching info for romkatv/zsh-defer...
# [CMD] nix-prefetch-github romkatv zsh-defer
# [INFO] Found:
#   Owner:  romkatv
#   Repo:   zsh-defer
#   Rev:    a1b2c3d4e5f6...
#   SHA256: sha256-ABC123...
# 
# Found in:
#   - home/common/shell.nix
# 
# Update these files? (y/N) y
# [INFO] ✅ Updated home/common/shell.nix
# [INFO] Done! Review changes with: git diff

# Review
git diff home/common/shell.nix

# Test
nh os build --dry

# Commit
git add home/common/shell.nix
git commit -m "feat: update zsh-defer plugin"
```

## Example 4: Update to Specific Version

```bash
# Update zsh-abbr to version 5.9.0
./scripts/maintenance/update-git-hash.sh olets zsh-abbr v5.9.0

# Output shows the tag and its hash
# Follow the same review, test, commit workflow
```

## Example 5: Broken Update - Rollback

```bash
# You ran update-all and something broke
./scripts/maintenance/update-all.sh

# After testing, the build fails
nh os build --dry
# Error: some-package evaluation failed

# Option 1: Revert just flake.lock
git checkout flake.lock
nh os build --dry  # Works now!

# Option 2: Revert everything
git reset --hard HEAD

# Option 3: Update one at a time to find the culprit
nix flake update nixpkgs
nh os build --dry  # Works
nix flake update home-manager
nh os build --dry  # Works
nix flake update ghostty
nh os build --dry  # Fails! Found it!

# Pin ghostty to previous version in flake.nix
# inputs.ghostty.url = "github:ghostty-org/ghostty/<old-commit>";
```

## Example 6: Migration to nvfetcher

If you want to use nvfetcher for your plugins:

```bash
cd ~/.config/nix/home/common

# 1. The config file is already created: zsh-plugins.toml
cat zsh-plugins.toml

# 2. Run nvfetcher
nix-shell -p nvfetcher --run "nvfetcher -c zsh-plugins.toml -o _sources"

# This creates _sources/generated.nix with:
# {
#   zsh-defer = { ... };
#   zsh-autopair = { ... };
#   # etc
# }

# 3. Modify shell.nix to use the generated sources
# At the top:
let
  sources = import ./_sources/generated.nix {
    inherit (pkgs) fetchgit fetchFromGitHub;
  };
in {
  # Then replace manual fetchFromGitHub with:
  src = sources.zsh-defer;
}

# 4. Test
nh os build --dry

# 5. Now updating is easy:
./scripts/maintenance/update-zsh-plugins.sh
# Updates ALL plugins at once!
```

## Example 7: Preview Updates Without Applying

```bash
# See what would change without actually changing anything
./scripts/maintenance/update-all.sh --dry-run

# Output shows what WOULD be updated
# No files are modified
```

## Example 8: GitHub Automated Updates

Your config already has automated updates set up:

```yaml
# .github/workflows/update-flake.yml
# Runs weekly on Mondays at 9 AM UTC
```

When the action runs:
1. Updates flake inputs
2. Creates a branch `automated-updates/YYYY-MM-DD`
3. Commits changes
4. (Optionally) Creates a PR

You can then:
- Review the PR
- Test locally: `git fetch && git checkout automated-updates/2025-10-28`
- Merge if good

## Example 9: Update After Adding New Input

```bash
# You added a new input to flake.nix
inputs.new-package.url = "github:owner/repo";

# Update just this input
nix flake lock --update-input new-package

# Or update everything
nix flake update

# Test
nh os build --dry

# Commit both flake.nix and flake.lock
git add flake.nix flake.lock
git commit -m "feat: add new-package input"
```

## Example 10: Quick Security Update

```bash
# CVE announced affecting nixpkgs
# Quick patch flow:

# 1. Update nixpkgs
nix flake update nixpkgs

# 2. Quick test (if you trust it)
nh os switch

# 3. Commit after (system already updated)
git add flake.lock
git commit -m "security: update nixpkgs for CVE-YYYY-XXXXX"
git push

# System is secured, documentation follows
```

## Example 11: Batch Update Multiple Packages

```bash
# Update several flake inputs at once
nix flake update nixpkgs home-manager darwin

# Or multiple manual packages
for repo in "romkatv/zsh-defer" "hlissner/zsh-autopair" "Tarrasch/zsh-bd"; do
  IFS='/' read -r owner repo_name <<< "$repo"
  ./scripts/maintenance/update-git-hash.sh "$owner" "$repo_name"
done

# Review all changes
git diff

# One commit for all
git add -A
git commit -m "chore: batch update ZSH plugins"
```

## Troubleshooting Examples

### Hash Mismatch

```bash
# You manually edited a rev but didn't update the hash
nh os build
# Error: hash mismatch
#   expected: sha256-OLD...
#   got:      sha256-NEW...

# Solution: Use the script to get correct hash
./scripts/maintenance/update-git-hash.sh owner repo
```

### Plugin Not Loading After Update

```bash
# Updated a plugin but it's not working

# 1. Check the new rev actually exists
cd ~/.config/nix
grep -A 5 "zsh-defer" home/common/shell.nix

# 2. Test fetching manually
nix-shell -p nix-prefetch-github --run \
  "nix-prefetch-github romkatv zsh-defer --rev <THE-REV>"

# 3. If fetch fails, the rev is wrong
# Either use latest:
./scripts/maintenance/update-git-hash.sh romkatv zsh-defer

# Or pin to known good version:
./scripts/maintenance/update-git-hash.sh romkatv zsh-defer <old-working-rev>
```

## Best Practices Summary

1. **Always branch** for updates
2. **Always test** with `--dry` first
3. **Commit frequently** (per-component or per-category)
4. **Document breaking changes** in commit messages
5. **Keep a stable branch** you can rollback to
6. **Update regularly** but not necessarily immediately
7. **Pin critical packages** if you need stability
8. **Review changelogs** for major version bumps

## Quick Reference

| Task | Command |
|------|---------|
| Update everything | `./scripts/maintenance/update-all.sh` |
| Preview updates | `./scripts/maintenance/update-all.sh --dry-run` |
| Update flake only | `nix flake update` |
| Update one input | `nix flake update <input>` |
| Update one plugin | `./scripts/maintenance/update-git-hash.sh owner repo` |
| Update all plugins | `./scripts/maintenance/update-zsh-plugins.sh` |
| Rollback | `git checkout flake.lock` |
| Test build | `nh os build --dry` |
| Apply build | `nh os switch` |
