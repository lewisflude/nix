# Store Optimization - Changes Applied ✅

## Summary of Changes

All optimization changes have been successfully applied to your configuration:

### ✅ 1. Font Optimization

- **File:** `home/common/theme.nix`
- **Change:** `iosevka` → `iosevka-bin` (pre-built binary instead of building from source)
- **Savings:** ~500MB-1GB

### ✅ 2. Development Tools Moved to devShells

- **Files Modified:**
  - `home/common/apps/packages.nix` - Removed dev tools from global packages
  - `home/common/apps/core-tooling.nix` - Removed dev tools from global packages
  - `shells/default.nix` - Added development shell
- **New File:** `shells/projects/development.nix` - Created devShell with common tools
- **Tools Moved:** `cmake`, `gnumake`, `pkg-config`, `openssl`, `libsecret`, `libiconv`
- **Usage:** `nix develop .#devShells.development`
- **Savings:** ~1-2GB

### ✅ 3. LibreOffice Duplication Removed

- **File:** `home/nixos/desktop-apps.nix`
- **Change:** Removed `libreoffice` (now only installed via productivity feature)
- **Savings:** Prevents duplicate installation (~1.3GB potential savings)

### ✅ 4. Documentation Created

- `docs/STORE_OPTIMIZATION_GUIDE.md` - Comprehensive optimization guide
- `docs/OPTIMIZATION_IMPLEMENTATION.md` - Implementation details

---

## Next Steps to Apply Changes

### Step 1: Rebuild Home Manager

Rebuild your home-manager configuration to apply the font and LibreOffice changes:

```bash
cd ~/.config/nix
home-manager switch --flake .#lewis@jupiter
```

**Expected:** Configuration rebuilds with new font package and without duplicate LibreOffice

### Step 2: Run Cleanup Script

Remove old packages and duplicates:

```bash
sudo bash ~/.config/nix/scripts/cleanup-enhanced.sh
```

**Expected:** Removes old package versions, debug packages, and duplicates

### Step 3: Run Garbage Collection

Remove unused packages:

```bash
sudo nix-collect-garbage -d
```

**Expected:** Removes packages not referenced by current system or profiles

### Step 4: Optimize Store

Deduplicate identical files:

```bash
sudo nix-store --optimise
```

**Expected:** Hard-links identical files to save space

### Step 5: Verify Results

Check new store size:

```bash
du -sh /nix/store
```

**Expected:** Store size reduced from 35.4GB to ~30-32GB

---

## Expected Results

### Before Optimization

- **Store Size:** 35.4GB
- **Fonts:** Building from source (larger)
- **Dev Tools:** Installed globally (always in closure)
- **LibreOffice:** Potentially duplicated

### After Optimization

- **Store Size:** ~30-32GB (**3-5GB reduction**)
- **Fonts:** Pre-built binary (smaller)
- **Dev Tools:** Only in devShells (not in global closure)
- **LibreOffice:** Single installation

### Breakdown of Savings

- Font optimization: ~500MB-1GB
- Dev tools to devShells: ~1-2GB
- Cleanup old packages: ~1-2GB
- **Total: ~3-5GB reduction**

---

## Verification Commands

After rebuilding, verify everything works:

```bash
# Check store size
du -sh /nix/store

# Verify fonts are working
fc-list | grep -i iosevka

# Verify devShell works
nix develop .#devShells.development
which cmake  # Should work in shell
exit
which cmake  # Should NOT be in global PATH

# Check LibreOffice is still available
which libreoffice
```

---

## Using Development Tools

Development tools are now in devShells. To use them:

### Option 1: Activate devShell Directly

```bash
nix develop .#devShells.development
```

### Option 2: Use in Project Directory

Create `.envrc` in your project:

```bash
echo "use flake ~/.config/nix#devShells.development" > .envrc
direnv allow
```

### Option 3: Add to Existing Project devShell

Import the development shell in your project's `shell.nix` or `flake.nix`

---

## Troubleshooting

### If fonts look different

- `iosevka-bin` may have slightly different features than `iosevka`
- If needed, revert to `iosevka` in `home/common/theme.nix`

### If dev tools are missing

- Use `nix develop .#devShells.development` to access them
- Or add to project-specific devShells

### If LibreOffice is missing

- Check `hosts/jupiter/default.nix` has `productivity.office = true`
- It's now only installed via the productivity feature

---

## Additional Optimizations Available

See `docs/STORE_OPTIMIZATION_GUIDE.md` for more aggressive optimizations:

- Remove old package versions (Zoom, OpenJDK, Ollama)
- More aggressive GC settings
- Optional: Disable keep-outputs (makes rebuilds slower)

---

## What Changed in Your Config

### Modified Files

1. `home/common/theme.nix` - Font optimization
2. `home/common/apps/packages.nix` - Removed dev tools
3. `home/common/apps/core-tooling.nix` - Removed dev tools
4. `home/nixos/desktop-apps.nix` - Removed LibreOffice duplicate
5. `shells/default.nix` - Added development shell
6. `shells/projects/development.nix` - New devShell file

### New Files

- `docs/STORE_OPTIMIZATION_GUIDE.md`
- `docs/OPTIMIZATION_IMPLEMENTATION.md`
- `shells/projects/development.nix`

All changes are ready to apply! Run the steps above to see the space savings.
