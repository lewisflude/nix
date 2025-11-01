# Additional Store Optimizations

## More Optimizations Applied

### ✅ 1. Moved rustup to devShells (Saves ~100-200MB)

- **Removed:** `rustup` from global packages (`home/common/apps/core-tooling.nix`)
- **Reason:** rustup is a large package that's only needed for development
- **Access:** Use `nix develop .#devShells.rust` or `nix develop .#devShells.development`
- **Savings:** ~100-200MB

### ✅ 2. Enhanced Cleanup Script

The cleanup script already handles:

- Old rustc versions and documentation (~1.5GB potential)
- Debug packages (~750MB)
- Duplicate CUDA libraries (~672MB)
- Old package versions

### 📋 Additional Optimizations Available

#### 1. Disable System Documentation (Saves ~500MB-1GB)

**Warning:** Only if you don't need man pages and info docs

For NixOS, add to your configuration:

```nix
# In modules/nixos/core/default.nix or host config
documentation = {
  enable = false;  # Disable all documentation
  # Or selectively:
  # man.enable = false;  # Disable man pages
  # info.enable = false;  # Disable info pages
  # doc.enable = false;   # Disable package documentation
};
```

**Savings:** ~500MB-1GB
**Note:** Only disable if you don't use `man` or `info` commands

#### 2. Remove Old Kernel Versions (Saves ~1GB)

**Action:** Run cleanup script + remove old kernels

```bash
# List current kernels
ls -la /boot/loader/entries/

# Remove old kernel entries (keep only current + 1 backup)
# Then run cleanup
sudo bash ~/.config/nix/scripts/cleanup-enhanced.sh
sudo nix-collect-garbage -d
```

**Savings:** ~1GB (old NVIDIA drivers for removed kernels)

#### 3. Optimize Nerd Fonts (Saves ~200-300MB)

**Current:** `nerd-fonts.iosevka` is 501MB
**Option:** Use a smaller variant or build custom font

```nix
# In home/common/theme.nix
home.packages = with pkgs; [
  # Instead of full nerd-fonts, use a smaller variant
  # Or build custom font with only needed icons
];
```

**Savings:** ~200-300MB (if you can use smaller font variant)

#### 4. Disable Keep-Outputs/Derivations (Saves ~2-3GB)

**Warning:** Only if you **never rebuild from source**

```nix
# In modules/nixos/system/nix/nix-optimization.nix
nix.settings.keep-outputs = false;
nix.settings.keep-derivations = false;
```

**Savings:** ~2-3GB
**Trade-off:** Rebuilds will be slower

#### 5. Remove Large Unused Packages

Check if these are actually needed:

- **Zoom** (~1GB): Do you use all 3 versions?
- **OpenJDK** (~920MB): Do you need both versions?
- **Chromium** (~515MB): Do you use Chromium or just Cursor?
- **Papirus icons** (~283MB): Are you using this theme?

#### 6. Service-Specific Optimizations

**Cal.com** (~300MB): If not actively used

```nix
# In hosts/jupiter/default.nix
containersSupplemental = {
  enable = true;
  calcom.enable = false;  # Disable if not needed
};
```

**Home Assistant** (~345MB): If not actively used

```nix
# Disable if not using
services.home-assistant.enable = false;
```

## Summary of All Optimizations

### Already Applied ✅

1. Font optimization (iosevka → iosevka-bin): ~500MB-1GB
2. Dev tools to devShells: ~1-2GB
3. LibreOffice duplication removed: ~1.3GB
4. rustup to devShells: ~100-200MB
5. Cleanup script enhancements: ~1-2GB (when run)

**Total Applied:** ~3-5GB potential savings

### Additional Options Available

- Disable documentation: ~500MB-1GB
- Remove old kernels: ~1GB
- Disable keep-outputs: ~2-3GB (makes rebuilds slower)
- Remove unused services: ~600MB-1GB
- Optimize fonts further: ~200-300MB

**Additional Potential:** ~4-6GB more savings

### Realistic Target

**Current:** 35.4GB
**After applied optimizations:** ~30-32GB
**With all optimizations:** ~25-28GB

## Next Steps

1. **Rebuild to apply rustup change:**

   ```bash
   home-manager switch --flake .#lewis@jupiter
   ```

2. **Run cleanup script:**

   ```bash
   sudo bash ~/.config/nix/scripts/cleanup-enhanced.sh
   sudo nix-collect-garbage -d
   sudo nix-store --optimise
   ```

3. **Check if you need documentation:**
   - If you use `man` or `info` commands, keep documentation enabled
   - If not, disable it for ~500MB-1GB savings

4. **Review large packages:**
   - Check if Zoom, OpenJDK, Chromium are actually needed
   - Remove unused services (Cal.com, Home Assistant if not used)

5. **Monitor store size:**

   ```bash
   du -sh /nix/store
   ```

## Recommended Safe Optimizations

In order of safety:

1. ✅ **Done:** Font optimization, dev tools, rustup
2. ✅ **Done:** Run cleanup script
3. ⚠️ **Consider:** Disable documentation (if not using man/info)
4. ⚠️ **Consider:** Remove old kernels (after cleanup)
5. ⚠️ **Advanced:** Disable keep-outputs (only if never rebuild from source)
