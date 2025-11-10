# Top 5 Ways to Reduce NixOS Build Size (32GB ? Lower)

## 1. **Disable 32-bit Support** (~4-6GB savings)

**Impact**: High | **Risk**: Medium | **Effort**: Low

### What it does

Removes system-wide 32-bit libraries (glibc, Mesa, Vulkan, OpenGL, NVIDIA drivers).

### How to do it

Edit `modules/nixos/features/gaming.nix`:

```nix
hardware.graphics = mkIf cfg.enable {
  enable = true;
  enable32Bit = false;  # Change from true to false
};
```

### Test it

1. Rebuild: `nh os switch`
2. Test your Steam games
3. If games work ? **Save 4-6GB** ?
4. If games break ? Revert to `true`

### What breaks

- Older 32-bit native Linux games
- Some 32-bit Windows games via Proton
- Wine 32-bit applications

### What still works

- Modern 64-bit games (most games since ~2015)
- Steam client (64-bit)
- Most Proton games (64-bit Windows games)

---

## 2. **Disable Unused Large Features** (~10-15GB total savings)

**Impact**: Very High | **Risk**: Low | **Effort**: Low

### Review and disable in `hosts/jupiter/default.nix`

#### A. Gaming (~5-10GB if disabled)

```nix
gaming = {
  enable = false;  # Disable if you don't game
  # OR keep enabled but remove 32-bit (see #1)
};
```

#### B. Media Management Stack (~3-5GB if disabled)

```nix
mediaManagement = {
  enable = false;  # Disable if not using Jellyfin/*arr services
  # OR disable individual services you don't use:
  # unpackerr.enable = false;
  # navidrome.enable = false;
};
```

#### C. AI Tools (~2-3GB if disabled)

```nix
aiTools = {
  enable = false;  # Disable if not using Ollama
  # OR use CPU-only (saves ~1GB):
  # ollama.acceleration = null;  # Instead of "cuda"
};
```

#### D. Home Assistant (~2-4GB if disabled)

Check if it's enabled in your services. If not actively used:

- Remove from `modules/nixos/services/home-assistant.nix` or disable the service

#### E. LibreOffice (~1.3GB if disabled)

```nix
productivity = {
  office = false;  # Disable if you don't use LibreOffice
};
```

### Total Potential Savings

10-15GB

---

## 3. **Run Cleanup Script for Duplicates** (~2-5GB savings)

**Impact**: Medium | **Risk**: Very Low | **Effort**: Very Low

### What it does

Removes old package versions while keeping the latest.

### How to do it

```bash
# Preview what will be deleted
nix run .#cleanup-duplicates -- --dry-run

# Actually clean up
nix run .#cleanup-duplicates
```

### What gets cleaned

- Old LibreOffice versions
- Old Ollama versions
- Old Zoom versions
- Old LLVM/Clang versions
- Old NVIDIA drivers (for old kernels)
- Old Rust versions
- Old VSCode/Zed versions
- Debug packages (cmake-debug, etc.)

### Estimated Savings

2-5GB

---

## 4. **Move Dev Toolchains to DevShells** (~2-4GB savings)

**Impact**: Medium | **Risk**: Low | **Effort**: Medium

### Current problem

Global toolchains (Rust, Python, Node) are always in your system closure.

### Solution

Use devShells instead - only load when needed.

### How to do it

#### Step 1: Disable global toolchains

Edit `hosts/jupiter/default.nix`:

```nix
development = {
  enable = true;
  rust = false;   # Use devShell instead
  python = false; # Use devShell instead
  node = false;   # Use devShell instead
  # Keep only what you use daily
};
```

#### Step 2: Create devShells (if not already)

Use `nix develop .#rust-dev` or `direnv` with `.envrc` files.

### What you lose

- Global access to `rustc`, `python`, `node` commands
- Need to enter devShell or use direnv

### What you gain

- **Save 2-4GB** (Rust ~1-2GB, Python ~500MB-1GB, Node ~300MB)
- Cleaner system
- Better isolation

---

## 5. **Optimize Home Assistant Components** (~1-2GB savings)

**Impact**: Low-Medium | **Risk**: Low | **Effort**: Low

### Current problem

Home Assistant has 71+ components enabled, many unused.

### How to do it

Edit `modules/nixos/services/home-assistant.nix`:

```nix
extraComponents = [
  # Only include what you actually use
  "default_config"
  "mqtt"           # If you use MQTT
  "hue"            # If you have Philips Hue
  # Remove unused components like:
  # "unifi"         # If you don't have UniFi
  # "tado"          # If you don't have Tado
  # "denonavr"      # If you don't have Denon
  # etc.
];
```

### How to identify what you use

1. Check your Home Assistant config at `/var/lib/hass/configuration.yaml`
2. Only enable components you actually have devices for
3. Remove components you don't use

**Estimated savings: 1-2GB** (depends on how many you remove)

---

## Quick Win: Combined Approach

### Minimal changes for maximum impact

1. **Disable 32-bit** (if you only play modern games): **-4-6GB**
2. **Run cleanup script**: **-2-5GB**
3. **Disable unused features** (pick 1-2 you don't use): **-3-8GB**

**Total: 9-19GB reduction** ? System size: **13-23GB** (down from 32GB)

### Conservative approach (keep everything, just optimize)

1. **Run cleanup script**: **-2-5GB**
2. **Disable 32-bit** (test first): **-4-6GB**
3. **Move dev toolchains to devShells**: **-2-4GB**

**Total: 8-15GB reduction** ? System size: **17-24GB**

---

## Verification

After making changes, check your system size:

```bash
# Check current system closure size
nix path-info -rS /run/current-system | awk '{sum+=$1} END {print sum/1024/1024/1024 " GB"}'

# Or use your analyze script
nix run .#analyze-services
```

---

## Priority Order (Easiest First)

1. ? **Run cleanup script** (5 minutes, zero risk)
2. ? **Disable unused features** (10 minutes, low risk)
3. ? **Test without 32-bit** (15 minutes, medium risk)
4. ? **Move dev toolchains** (30 minutes, low risk)
5. ? **Optimize Home Assistant** (15 minutes, low risk)

Start with #1 and #2 for quick wins, then test #3.
