---
description: "Update flake inputs and dependencies"
---

# Update Nix Dependencies

Update Nix flake inputs and other dependencies using the project's update tools.

## What This Does

Updates:
- Nix flake inputs (nixpkgs, home-manager, etc.)
- ZSH plugins
- Other tracked dependencies

## Usage

```
/nix:update [input-name]
```

**Arguments**:
- `$1` (optional) - Specific input to update (e.g., "nixpkgs", "home-manager")
- If omitted, updates all inputs

**Examples**:
```
/nix:update
/nix:update nixpkgs
/nix:update home-manager
```

## Update Methods

### Method 1: POG Script (Recommended)

```bash
nix run .#update-all
```

This interactive tool:
- Updates all flake inputs
- Updates ZSH plugins
- Commits changes with proper message
- Shows changelog/diff

### Method 2: Manual Flake Update

```bash
# Update all inputs
nix flake update

# Update specific input
nix flake update nixpkgs

# Update and commit
nix flake update && git add flake.lock && git commit -m "chore(deps): update flake inputs"
```

## Your Task

1. **Determine what to update**:
   - All inputs (default)
   - Specific input (if provided)
   - Ask user if unclear

2. **Choose method**:
   - **Recommended**: Use POG script for interactive experience
   - **Quick**: Use `nix flake update` for command-line update

3. **Run update**:
   ```bash
   nix run .#update-all
   ```

   Or:

   ```bash
   nix flake update <input-name>
   ```

4. **Review changes**:
   - Check what versions changed
   - Look at `flake.lock` diff
   - Note any major version bumps

5. **Test** (recommend to user):
   - Build configuration: `nix flake check`
   - Test in VM or on system
   - Watch for breaking changes

6. **Commit** (if using manual method):
   ```bash
   git add flake.lock
   git commit -m "chore(deps): update <input-name> to version X.Y.Z"
   ```

## Flake Inputs Reference

Common inputs in this project:

- **nixpkgs** - Package repository
- **home-manager** - User environment manager
- **darwin** - nix-darwin (macOS support)
- **flake-parts** - Flake organization framework
- **import-tree** - Auto-import modules (dendritic pattern)

Check `flake.nix` for the full list.

## Before Updating

**Check**:
1. ✅ Current build is working
2. ✅ No uncommitted changes (or stash them)
3. ✅ Ready to test after update

## After Updating

**Validate**:
1. ✅ Run `nix flake check` to verify
2. ✅ Test build in VM or test environment
3. ✅ Watch for deprecation warnings
4. ✅ Check changelogs for breaking changes

**Rollback if needed**:
```bash
git checkout flake.lock
```

## Handling Breaking Changes

If update introduces breaking changes:

1. **Identify the issue**:
   - Read error messages
   - Check upstream changelogs
   - Search NixOS Discourse/GitHub issues

2. **Fix configuration**:
   - Update affected modules
   - Adjust syntax if needed
   - Remove deprecated options

3. **Test thoroughly**:
   - Build and switch in test environment
   - Verify all features work
   - Check services start correctly

## Related Commands

- `/nix:check-build` - Validate after updates
- `nix run .#update-all` - Interactive update tool

## Related Documentation

- `CLAUDE.md` - AI assistant guidelines
- `flake.nix` - Input definitions and versions
