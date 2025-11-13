# Size Reduction Summary

## ? Completed Changes

### 1. Removed LibreOffice (~1.3GB savings)

**File**: `hosts/jupiter/default.nix`

- Changed `office = false`
- LibreOffice will no longer be included in system closure

### 2. Moved Dev Toolchains to DevShells (~2-4GB savings)

**Files Modified**:

- `hosts/jupiter/default.nix` - Disabled global rust/python/node
- `shells/projects/rust.nix` - Created Rust devShell
- `shells/projects/python.nix` - Created Python devShell
- `shells/projects/node.nix` - Created Node.js devShell
- `shells/default.nix` - Added new shells to exports

**How to use**:

```bash
# Enter Rust shell
nix develop .#rust

# Enter Python shell
nix develop .#python

# Enter Node shell
nix develop .#node

# Or use direnv (recommended)
# Create .envrc in your project:
echo "use flake .#rust" > .envrc
direnv allow
```

**What changed**:

- `rust`, `python`, `node` are no longer in system closure
- They're only loaded when you enter a devShell
- Saves ~2-4GB from system build

### 3. Home Assistant Component Analysis

**File**: See `/tmp/analyze-ha-components.md` (or check Home Assistant docs)

**Large components to consider removing** (if not used):

- `music_assistant` (~100-200MB)
- `esphome` (~50-100MB)
- `unifi` / `unifiprotect` (~50-100MB each)
- `zha` (~50-100MB)
- `spotify` (~20-30MB)
- `apple_tv` (~20-30MB)

**To remove components**, edit `modules/nixos/services/home-assistant.nix` and remove from `extraComponents` list.

---

## ? About Cleanup Script and Build Size

**Question**: Will cleaning up old versions affect the 32GB build size?

**Answer**: **No, it won't directly affect your build size**, but it will free up disk space.

### The Difference

1. **Build Size (32GB)** = Size of your system closure (all packages referenced by `/run/current-system`)
   - This is what gets built when you run `nh os switch`
   - Cleanup script does NOT affect this
   - Only removing packages from your config affects this

2. **Store Size** = Total size of `/nix/store` (all packages ever built)
   - This includes old versions, unreferenced packages, etc.
   - Cleanup script DOES affect this
   - Frees up disk space but doesn't change what gets built

### What the Cleanup Script Does

- Removes old package versions from `/nix/store` that are NOT referenced by your current system
- Example: If you have `ollama-0.12.6` and `ollama-0.12.9`, and your system uses `0.12.9`, it removes `0.12.6`
- This frees disk space but doesn't change your system closure size

### To Actually Reduce Build Size

You need to remove packages from your configuration (which we've done):

- ? Removed LibreOffice from config ? reduces build size
- ? Moved dev toolchains to devShells ? reduces build size
- ? Cleanup script ? only frees disk space, doesn't reduce build size

---

## ?? Expected Results

After these changes:

**Before**: ~32GB system closure
**After**: ~27-29GB system closure (estimated)

**Savings**:

- LibreOffice: ~1.3GB
- Dev toolchains: ~2-4GB
- **Total: ~3.3-5.3GB reduction**

**Next steps for more savings**:

1. Disable 32-bit support (if you only play modern games): ~4-6GB
2. Remove unused Home Assistant components: ~200-500MB
3. Run cleanup script (frees disk space, not build size): ~2-5GB disk space

---

## ?? After Rebuilding

After you rebuild with `nh os switch`, verify the changes:

```bash
# Check system closure size
nix path-info -rS /run/current-system | awk '{sum+=$1} END {print sum/1024/1024/1024 " GB"}'

# Verify LibreOffice is gone
which libreoffice  # Should return nothing

# Verify dev toolchains are in devShells
nix flake show | grep -A 5 devShells
# Should show: rust, python, node

# Test a devShell
nix develop .#rust --command rustc --version
```

---

## ?? Notes

- Dev toolchains are now only available in devShells
- You'll need to use `nix develop` or `direnv` to access them
- This is actually better practice - keeps your system lean
- LibreOffice can be reinstalled later if needed: `nix profile install nixpkgs#libreoffice-fresh`
