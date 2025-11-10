# System Size Analysis - January 2025

## Current System Size: **33.74 GiB**

Based on nix-tree analysis, here are the major space consumers and recommendations for reduction.

---

## ?? Major Findings

### 1. **Home Manager Generation: 13.26 GiB**

#### Largest Items

- **ghostty-1.1.4**: **1.5 GiB**
  - GTK4 stack: ~1.7GB (libadwaita, gtk4, gtk4-layer-shell)
  - ghostty-cache: 576.51 MiB (build cache - can be removed)
  - GStreamer plugins: ~630MB (for media support)

- **cursor-1.0.0**: **828.79 MiB** ? **DISABLED** (saves ~828MB)

- **hm_.cursorextensions.extensionsimmutable.json**: **214.47 MiB** ? **DISABLED** (saves ~214MB)
  - This was a huge JSON file storing extension data
  - Likely contained extension binaries/cache

#### Recommendations

1. **Remove ghostty-cache** (576MB) - This is a build cache, not needed at runtime
2. ? **Cursor disabled** - **DONE** (saves ~1.04 GiB: cursor 828MB + extensions 214MB)
3. **Consider lighter terminal** - If you don't need GTK4 features, consider alacritty or foot (~50MB vs 1.5GB)

---

### 2. **System Path: 13.75 GiB**

#### Gaming Stack (~10-12 GiB total)

- **steam-1.0.0.85**: **5.48 GiB** (largest single package!)
- **ollama-0.12.9**: **1.9 GiB** (with CUDA support)
- **protontricks-1.13.0**: **1.63 GiB**
- **steamcmd-20180104**: **1.62 GiB**
- **steam-run**: **1.62 GiB**
- **protonup-qt-2.13.0**: **1.59 GiB**
- **wine-10.0**: **1.55 GiB**
- **gamescope-3.16.17**: **980.22 MiB**
- **mangohud-0.8.1**: **841.75 MiB**

#### Other Large Packages

- **speech-dispatcher-0.12.1**: **1.67 GiB** ?? **UNUSUALLY LARGE**
  - espeak-ng: 1.61 GiB (voice data)
  - mbrola: 676.03 MiB (voice data)
  - flite: 168.93 MiB (TTS engine)
  - svox: 38.26 MiB (TTS engine)
  - **Likely not needed if you don't use screen readers/TTS**

- **1password-8.11.18-34.BETA**: **1.62 GiB**
- **nvidia-settings-580.95.05**: **1.38 GiB**
- **nvidia-x11-580.95.05**: **1.17 GiB**
- **niri-unstable**: **1.16 GiB**
- **gvfs-1.57.2**: **1.16 GiB**

---

## ?? Potential Savings

### Quick Wins (If Not Used)

1. **Disable Gaming Stack** (if not gaming): **~10-12 GiB**

   ```nix
   # hosts/jupiter/default.nix
   gaming = {
     enable = false;  # Saves ~10-12GB
   };
   ```

2. **Remove speech-dispatcher** (if not using TTS/screen readers): **~1.67 GiB** ?? **NEEDS INVESTIGATION**
   - Found: Appears as user unit (likely from Home Manager or desktop environment)
   - **Issue**: `services.speech-dispatcher` doesn't exist as a NixOS option - it's pulled in as a dependency
   - **Next step**: Need to find what's pulling it in (check Home Manager config or desktop environment)
   - **Savings**: ~1.67 GiB (espeak-ng: 1.61GB, mbrola: 676MB, flite: 169MB, svox: 38MB)

3. **Remove ghostty-cache**: **~576 MiB**
   - This is a build cache, safe to remove
   - May need to check ghostty package definition

4. ? **Cursor disabled** - **DONE** (saves ~1.04 GiB)
   - Check if extensions can be cleaned up
   - May contain cached extension data

### Medium Impact

5. **Disable Ollama** (if not using AI tools): **~1.9 GiB**

   ```nix
   # hosts/jupiter/default.nix
   aiTools = {
     enable = false;  # Saves ~1.9GB
   };
   ```

6. **Use lighter terminal** (if GTK4 not needed): **~1.3 GiB**
   - Replace ghostty with alacritty or foot
   - Saves ~1.3GB (GTK4 stack)

### Total Potential Savings

- **If not gaming**: ~10-12 GiB
- **If not using TTS**: ~1.67 GiB
- **If not using AI tools**: ~1.9 GiB
- **If switch terminal**: ~1.3 GiB
- **Other optimizations**: ~800 MiB

**Maximum potential**: ~15-17 GiB reduction (down to ~16-18 GiB)

---

## ?? Action Items

### Immediate Actions

1. **Find what's pulling in speech-dispatcher**:

   ```bash
   # Find the hash first
   nix-store -q --references /run/current-system | grep speech-dispatcher

   # Then trace dependencies
   nix why-depends /run/current-system <hash>
   ```

2. **Check if gaming is actually used**:
   - Review `hosts/jupiter/default.nix`
   - If not gaming, disable: `gaming.enable = false`

3. **Investigate ghostty-cache**:
   - Check `pkgs/` or nixpkgs for ghostty definition
   - See if cache can be excluded from closure

4. ? **Cursor disabled** - **DONE**
   - Removed from `home/common/apps/default.nix`
   - Removed from `home/common/profiles/optional.nix`
   - Removed `cursor-cli` from `home/common/apps/packages.nix`
   - Disabled cursor theme in `modules/shared/features/desktop/default.nix`

### Configuration Changes Needed

1. **Disable unused features** in `hosts/jupiter/default.nix`
2. ? **Disable speech-dispatcher** - **DONE** (added to `modules/nixos/core/security.nix`)
3. **Consider terminal replacement** if GTK4 not needed
4. **Clean up ghostty-cache** if possible

---

## ?? Size Breakdown Summary

| Category | Size | Notes |
|----------|------|-------|
| **Gaming Stack** | ~10-12 GiB | Steam, Proton, Wine, etc. |
| **Home Manager** | ~12.2 GiB | ghostty (1.5GB), ~~cursor (828MB)~~, ~~extensions (214MB)~~ |
| **AI Tools** | ~1.9 GiB | Ollama with CUDA |
| **TTS/Accessibility** | ~1.67 GiB | speech-dispatcher (likely unnecessary) |
| **NVIDIA Drivers** | ~2.5 GiB | nvidia-settings + nvidia-x11 |
| **Desktop Environment** | ~2.5 GiB | niri, gvfs, xdg-desktop-portal, etc. |
| **Other System** | ~2-3 GiB | Firmware, kernel, systemd, etc. |

---

## ?? Recommended Priority

1. **High Priority** (if not used):
   - Disable gaming: **~10-12 GiB**
   - Remove speech-dispatcher: **~1.67 GiB**

2. **Medium Priority**:
   - Disable Ollama if not using: **~1.9 GiB**
   - Switch terminal if GTK4 not needed: **~1.3 GiB**

3. **Low Priority** (smaller gains):
   - Clean ghostty-cache: **~576 MiB**
   - ? Cursor disabled: **~1.04 GiB**

---

## ?? Next Steps

1. ? **Disable speech-dispatcher** - **DONE** (saves ~1.67 GiB)
2. Review gaming usage - disable if not needed (saves ~10-12 GiB)
3. Consider terminal replacement (saves ~1.3 GiB)
4. Rebuild system: `nh os switch`
5. Measure new size and verify savings
6. Run cleanup script: `nix run .#cleanup-duplicates`

---

## ?? Investigation Commands

```bash
# Find what pulls in speech-dispatcher
nix-store -q --references /run/current-system | grep speech-dispatcher
nix why-depends /run/current-system <hash-of-speech-dispatcher>

# Check system closure size
nix path-info -rS /run/current-system | awk '{sum+=$1} END {print sum/1024/1024/1024 " GB"}'

# Find largest packages
nix path-info -rS /run/current-system | sort -rn | head -20

# Check Home Manager size
nix path-info -rS $(readlink -f ~/.nix-profile) | awk '{sum+=$1} END {print sum/1024/1024/1024 " GB"}'
```
