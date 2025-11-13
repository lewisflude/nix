# Quick Fix Checklist

Critical issues that can be fixed in the next 1-2 hours.

## ✅ Immediate Actions (30 minutes)

### 1. Delete Duplicate/Wrong Files

```bash
# Delete podman from home-manager (already in system config)
git rm home/nixos/system/podman.nix

# Delete duplicate graphics packages
git rm home/nixos/system/graphics.nix

# Update imports
# Edit home/nixos/system/default.nix and remove lines 10 and 11
```

**Edit** `home/nixos/system/default.nix`:
```nix
{
  imports = [
    ./keyboard.nix
    ./mangohud.nix
    ./usb.nix
    ./yubikey-touch-detector.nix
    ./audio.nix
    ./networking.nix
    ./yubikey-tools.nix
    # REMOVED: ./graphics.nix
    # REMOVED: ./podman.nix
    ./gnome-keyring.nix
  ];
}
```

### 2. Remove Hardcoded Timezone

**Edit** `modules/nixos/features/desktop/desktop-environment.nix`:

Remove line 13:
```nix
time.timeZone = "Europe/London";  # DELETE THIS LINE
```

### 3. Fix SOPS Conditional

**Edit** `modules/shared/sops.nix:29`:

**Before**:
```nix
resolvedOwner = if isDarwin then config.host.username else config.host.username;
```

**After**:
```nix
resolvedOwner = config.host.username;
```

### 4. Test & Commit

```bash
# Build to verify no breakage
nix flake check

# For NixOS users: build system
nh os build

# For all users: build home-manager
home-manager build

# If successful, commit
git add -A
git commit -m "fix: remove duplicate packages and hardcoded values

- Remove home/nixos/system/podman.nix (duplicate of system config)
- Remove home/nixos/system/graphics.nix (duplicate packages)
- Remove hardcoded timezone from desktop module
- Fix redundant SOPS owner conditional

These changes eliminate boundary violations between home-manager and
system configuration, remove ~200MB of duplicate packages, and improve
flexibility for multi-host/multi-timezone setups."
```

---

## 📋 High Priority (Next 2-3 hours)

### 5. Rename Confusing Directory

```bash
# Rename for clarity
git mv home/nixos/system home/nixos/hardware-tools

# Update import in home/nixos/default.nix
sed -i 's|./system|./hardware-tools|' home/nixos/default.nix

# Commit
git commit -m "refactor: rename home/nixos/system to hardware-tools

The 'system' name was confusing as it implied system-level configuration
but actually contains user-level hardware interaction tools."
```

### 6. Improve Platform Detection

**Edit** `lib/functions.nix:4-6`:

**Before**:
```nix
isLinux = system: lib.hasInfix "linux" system;
isDarwin = system: lib.hasInfix "darwin" system;
```

**After**:
```nix
isLinux = system: lib.hasSuffix "-linux" system || system == "linux";
isDarwin = system: lib.hasSuffix "-darwin" system || system == "darwin";
```

```bash
git commit -m "fix: improve platform detection precision

Use hasSuffix instead of hasInfix to prevent false positives.
Handles both 'x86_64-linux' and 'linux' formats correctly."
```

---

## 🔍 Validation Commands

After each fix, run these to verify:

```bash
# Check flake is valid
nix flake check

# Check for the antipatterns we just fixed
echo "Checking for podman in home-manager..."
! grep -r "home.packages.*podman" home/ || echo "❌ Still found"

echo "Checking for duplicate graphics packages..."
! grep -r "vulkan-tools\|mesa-demos" home/ || echo "⚠️  Still in home-manager"

echo "Checking for hardcoded timezone..."
! grep "time.timeZone" modules/nixos/features/desktop/ || echo "❌ Still hardcoded"

# Build config
nh os build  # NixOS users
home-manager build  # All users
```

---

## 📊 Expected Results

After completing these quick fixes:

- **Removed**: 2 files, ~50 lines of code
- **Eliminated**: ~200MB of duplicate package builds
- **Fixed**: 3 architectural boundary violations
- **Improved**: Platform detection precision
- **Time Saved**: Future rebuilds will be faster

---

## ⚠️ Before You Start

1. **Backup**: Ensure your config is in git with no uncommitted changes
2. **Test Environment**: Consider testing on a non-production system first
3. **Time**: Set aside 30-60 minutes uninterrupted
4. **Rollback Plan**: Know how to `nixos-rebuild switch --rollback` if needed

---

## 🆘 If Something Breaks

### Podman doesn't work
```bash
# Verify system config is enabled
grep -r "virtualisation.podman.enable" hosts/

# Should be true in your host config
# If not, check modules/nixos/features/virtualisation.nix
```

### Graphics tools missing
```bash
# They should be in system packages
which vulkaninfo
which vainfo

# If missing, check system config
grep -r "hardware.graphics" modules/nixos/features/desktop/graphics.nix
```

### Time zone wrong
```bash
# Check your host config
grep "timeZone" hosts/jupiter/configuration.nix

# Manually set if needed
timedatectl set-timezone Europe/London
```

### Rollback Everything
```bash
# NixOS
sudo nixos-rebuild switch --rollback

# Home Manager
home-manager generations
home-manager switch --switch-generation <number>
```

---

**Estimated Time**: 30-60 minutes
**Risk Level**: Low (all changes are deletions or simplifications)
**Testing Required**: Build + basic validation commands

Good luck! 🚀
