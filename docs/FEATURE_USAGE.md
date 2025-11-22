# Feature Usage Across Hosts

**Last updated:** 2025-11-22
**Total hosts:** 3 (jupiter, mercury, Lewiss-MacBook-Pro)

This document tracks which features are actively used across all hosts to help identify unused options during regular audits.

---

## Development

| Feature | Jupiter (NixOS) | Mercury (macOS) | Lewiss-MacBook-Pro (macOS) | Status |
|---------|----------------|-----------------|---------------------------|---------|
| `enable` | ✅ | ✅ (default) | ✅ (default) | **Keep** |
| `git` | ✅ | ✅ (default) | ✅ (default) | **Keep** |
| `rust` | ❌ (devShell) | ✅ (default) | ✅ (default) | **Keep** |
| `python` | ❌ (devShell) | ✅ (default) | ✅ (default) | **Keep** |
| `node` | ❌ (devShell) | ✅ (default) | ✅ (default) | **Keep** |
| `lua` | ✅ | ❌ | ❌ | **Keep** |
| `go` | ❌ | ❌ | ❌ | Monitor |
| `java` | ❌ | ❌ | ❌ | Monitor |
| `nix` | Available | Available | Available | **Keep** |
| `docker` | ❌ | ❌ | ❌ | **Keep** |

**Notes:**
- Jupiter uses devShells for rust/python/node to reduce system size (~2-4GB savings)
- Go and Java kept as options but not currently used

---

## Gaming

| Feature | Jupiter (NixOS) | Mercury (macOS) | Lewiss-MacBook-Pro (macOS) | Status |
|---------|----------------|-----------------|---------------------------|---------|
| `enable` | ✅ | ❌ | ❌ | **Keep** |
| `steam` | ✅ | ❌ | ❌ | **Keep** |
| `performance` | ✅ | ❌ | ❌ | **Keep** |

**Notes:**
- Gaming features only used by Jupiter
- Removed: `lutris`, `emulators` (never used)

---

## Virtualisation

| Feature | Jupiter (NixOS) | Mercury (macOS) | Lewiss-MacBook-Pro (macOS) | Status |
|---------|----------------|-----------------|---------------------------|---------|
| `enable` | ✅ | ❌ | ❌ | **Keep** |
| `docker` | ❌ | ❌ | ❌ | **Keep** |
| `podman` | ✅ | ❌ | ❌ | **Keep** |

**Notes:**
- Jupiter uses Podman for containers
- Removed: `qemu`, `virtualbox` (never used)

---

## Home Server

| Feature | Jupiter (NixOS) | Mercury (macOS) | Lewiss-MacBook-Pro (macOS) | Status |
|---------|----------------|-----------------|---------------------------|---------|
| `enable` | ✅ | ❌ | ❌ | **Keep** |
| `fileSharing` | ✅ | ❌ | ❌ | **Keep** |

**Notes:**
- Only Jupiter acts as home server
- Removed: `homeAssistant`, `mediaServer`, `backups` (never used or managed separately)

---

## Desktop

| Feature | Jupiter (NixOS) | Mercury (macOS) | Lewiss-MacBook-Pro (macOS) | Status |
|---------|----------------|-----------------|---------------------------|---------|
| `enable` | ✅ | ✅ (default) | ✅ (default) | **Keep** |
| `niri` | ✅ | ❌ | ❌ | **Keep** |
| `hyprland` | ❌ | ❌ | ❌ | **Keep** |
| `theming` | ✅ (default) | ✅ (default) | ✅ (default) | **Keep** |
| `utilities` | ✅ | ❌ | ❌ | **Keep** |
| `signalTheme` | ✅ (default) | ✅ (default) | ✅ (default) | **Keep** |

**Notes:**
- All hosts use desktop features
- Jupiter uses Niri compositor

---

## Productivity

| Feature | Jupiter (NixOS) | Mercury (macOS) | Lewiss-MacBook-Pro (macOS) | Status |
|---------|----------------|-----------------|---------------------------|---------|
| `enable` | ✅ | ✅ | ✅ | **Keep** |
| `notes` | ✅ | ✅ | ✅ | **Keep** |
| `email` | ✅ | ❌ | ❌ | **Keep** |
| `calendar` | ✅ | ❌ | ❌ | **Keep** |
| `resume` | ❌ | ✅ | ✅ | **Keep** |

**Notes:**
- macOS hosts use notes + resume
- Jupiter uses notes + email + calendar
- Removed: `office` (explicitly disabled, LibreOffice ~1.3GB)

---

## Media

| Feature | Jupiter (NixOS) | Mercury (macOS) | Lewiss-MacBook-Pro (macOS) | Status |
|---------|----------------|-----------------|---------------------------|---------|
| `enable` | ✅ | ❌ | ❌ | **Keep** |
| `audio.enable` | ✅ | ❌ | ❌ | **Keep** |
| `audio.production` | ❌ | ❌ | ❌ | **Keep** |
| `audio.realtime` | ✅ | ❌ | ❌ | **Keep** |
| `audio.audioNix.*` | ✅ (disabled) | ❌ | ❌ | **Keep** |

**Notes:**
- Only Jupiter uses media features (audio production setup)
- Removed: `audio.streaming`, `video.*`, `streaming.*` (entire sections never used)

---

## Security

| Feature | Jupiter (NixOS) | Mercury (macOS) | Lewiss-MacBook-Pro (macOS) | Status |
|---------|----------------|-----------------|---------------------------|---------|
| `enable` | ✅ (default) | ✅ (default) | ✅ (default) | **Keep** |
| `yubikey` | ✅ (default) | ✅ (default) | ✅ (default) | **Keep** |
| `gpg` | ✅ (default) | ✅ (default) | ✅ (default) | **Keep** |

**Notes:**
- Security features used by all hosts via defaults
- Removed: `firewall` (never used)

---

## Special Features (Jupiter Only)

### Media Management
- ✅ Complete media server stack (Jellyfin, *arr apps, qBittorrent)
- ✅ Used extensively by Jupiter
- ❌ Not applicable to macOS hosts

### AI Tools
- ✅ Ollama with CUDA acceleration
- ✅ Used by Jupiter for local LLMs
- ❌ Not applicable to macOS hosts

### Containers Supplemental
- ✅ Various Docker containers (Homarr, Wizarr, Jellystat, etc.)
- ✅ Used by Jupiter for supplemental services
- ❌ Not applicable to macOS hosts

### Restic
- ✅ Jupiter: REST server enabled
- ✅ Lewiss-MacBook-Pro: Backup client enabled
- ❌ Mercury: Not enabled
- **Status:** Keep (2/3 hosts use)

---

## Summary Statistics

### Overall Usage
- **Total active features:** ~50
- **Unused options removed:** 18
- **Features used by all hosts:** ~15 (security, desktop basics, etc.)
- **Features used by 1 host:** ~30 (Jupiter-specific server features)

### Host Profiles
**Jupiter (NixOS - Heavy):**
- Primary workstation + home server
- Uses: Gaming, Media, AI, Virtualisation, Containers
- Config complexity: HIGH (~240 lines of features)

**Mercury (macOS - Minimal):**
- macOS laptop
- Uses: Productivity (notes, resume)
- Config complexity: LOW (~6 lines of features)

**Lewiss-MacBook-Pro (macOS - Minimal):**
- macOS laptop with backups
- Uses: Productivity (notes, resume), Restic
- Config complexity: LOW (~9 lines of features)

---

## Cleanup History

### 2025-11-22 - TASK-004 Cleanup
**Removed 18 unused options:**
- development: kubernetes, buildTools, debugTools, vscode, helix, neovim
- gaming: lutris, emulators
- virtualisation: qemu, virtualbox
- homeServer: homeAssistant, mediaServer, backups
- productivity: office
- media: audio.streaming, video.*, streaming.*
- security: firewall

**Impact:**
- Line reduction: 29 lines (~11.6%)
- Option reduction: 18 options
- No breaking changes (options never used)

---

## Maintenance Guidelines

### Quarterly Review (Every 3 months)
1. Run feature usage audit
2. Identify options with 0% usage for 2+ quarters
3. Evaluate for removal

### Before Adding New Options
Ask these questions:
1. **Will 2+ hosts use this?** → If no, add to specific host instead
2. **Is it complex configuration?** → If no (just packages), add directly
3. **Does it require ordering/dependencies?** → If yes, consider option
4. **Can it be inferred from other config?** → If yes, don't add

### Usage Thresholds
- ✅ **2-3 hosts:** Definitely keep
- ⚠️ **1 host:** Monitor for potential removal
- ❌ **0 hosts:** Remove after 1 quarter unused

---

## Legend

- ✅ Enabled/Used
- ❌ Disabled/Not used
- **Keep** - Actively used, maintain
- **Monitor** - Low usage, review periodically
- (default) - Set via hosts/_common/features.nix
- (devShell) - Moved to development shell instead

---

## Related Documentation

- `docs/tasks/TASK-004-feature-audit-results.md` - Detailed audit results
- `modules/shared/host-options/features.nix` - Feature option definitions
- `hosts/_common/features.nix` - Default feature values
- `scripts/verify-no-removed-features.sh` - Verification script
