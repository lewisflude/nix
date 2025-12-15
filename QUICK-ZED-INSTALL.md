# Quick Zed Installation Guide

## TL;DR - Fastest Options

### ⚡ FASTEST: Official Binary (~2 minutes)

```bash
# Download and install official macOS build
curl -L https://zed.dev/api/releases/stable/latest/Zed-aarch64.dmg -o /tmp/Zed.dmg
open /tmp/Zed.dmg
# Drag Zed.app to Applications folder
```

### 🍺 FAST: Homebrew (~3 minutes)

```bash
brew install --cask zed
```

### 🐚 FAST: Try without installing

```bash
# Run directly without installing
nix run 'github:zed-industries/zed'
```

## Detailed Options

### Option 1: Official Binary (Recommended for Speed)

**Time:** ~2 minutes  
**Method:** Download pre-built .dmg

**Pros:**
- ⚡ Instant (just download & drag)
- ✅ Official from Zed team
- 🔄 Built-in auto-updates
- 📦 Zero compilation

**Cons:**
- Not managed by Nix
- Won't appear in your Nix config
- Manual PATH setup if needed

**Steps:**
```bash
# Download
curl -L https://zed.dev/api/releases/stable/latest/Zed-aarch64.dmg -o /tmp/Zed.dmg

# Open and install
open /tmp/Zed.dmg
# Drag Zed.app to /Applications in the finder window
```

**Adding to PATH (optional):**
```bash
# Add Zed CLI to your path
ln -s /Applications/Zed.app/Contents/MacOS/cli /usr/local/bin/zed
```

---

### Option 2: Homebrew

**Time:** ~3-5 minutes  
**Method:** Homebrew cask

**Pros:**
- Fast (pre-built)
- Easy updates: `brew upgrade`
- Familiar tool

**Cons:**
- Requires Homebrew
- Not in Nix config
- Another package manager

**Steps:**
```bash
# Install
brew install --cask zed

# Update later
brew upgrade zed
```

---

### Option 3: Hybrid Approach (Best of Both)

**Time:** 2 min now + 15-25 min later  
**Method:** Use fast install now, switch to Nix later

**The Strategy:**

1. **Get working editor NOW** (2 minutes):
   ```bash
   brew install --cask zed
   # or download .dmg
   ```

2. **Start Nix build in background** (let it run):
   ```bash
   darwin-rebuild switch --flake ~/.config/nix &
   # This runs in background, takes 15-25 minutes
   ```

3. **Use Homebrew version while waiting**
   - Work normally
   - Editor is immediately usable
   - Nix build completes in background

4. **Switch to Nix version when ready:**
   ```bash
   # Remove Homebrew version
   brew uninstall --cask zed
   
   # Nix version now in PATH automatically
   which zed  # Should point to /nix/store/...
   ```

**Benefits:**
- ✅ No downtime waiting for build
- ✅ Eventually Nix-managed
- ✅ Can work immediately

---

### Option 4: Try Zed Flake Directly

**Time:** Unknown (might be faster than nixpkgs)  
**Method:** Use Zed's official flake

**Test it:**
```bash
# Try running without installing
nix run 'github:zed-industries/zed'

# If it works well, install it
nix profile install 'github:zed-industries/zed'
```

**Why this might be better:**
- Zed's CI might have pre-built artifacts
- Could have better caching
- More frequent updates

**Note:** Your config has this disabled due to past build issues. Try testing if it works now!

---

### Option 5: Use Temporary Older Version

**Time:** ~30 seconds (if cached)  
**Method:** Use older nixpkgs commit

```bash
# Try older stable release (might be cached)
nix shell 'github:NixOS/nixpkgs/nixos-24.05#zed-editor'

# Or use it temporarily
nix run 'github:NixOS/nixpkgs/nixos-24.05#zed-editor'
```

**Pros:**
- Might find cached version
- Pure Nix approach
- No manual installation

**Cons:**
- Older version
- May not be cached either
- Still might need building

---

## Comparison Table

| Method | Time | Nix-Managed | Auto-Updates | Effort |
|--------|------|-------------|--------------|--------|
| **Official .dmg** | 2 min | ❌ | ✅ | Low |
| **Homebrew** | 3 min | ❌ | ✅ | Low |
| **Hybrid** | 2 + 25 min | ✅ (later) | ❌ | Medium |
| **Zed flake** | ? | ✅ | ❌ | Medium |
| **Your nixpkgs** | 15-25 min | ✅ | ❌ | High |

## Recommendations by Use Case

### "I need Zed RIGHT NOW"
→ **Official .dmg** or **Homebrew**

### "I want Nix eventually but need it today"
→ **Hybrid approach**

### "I'm willing to wait for pure Nix"
→ Keep current setup, wait 15-25 min

### "I want to experiment"
→ Try **Zed flake** (`nix run github:zed-industries/zed`)

## After Quick Install

### If using Homebrew/DMG temporarily:

```bash
# 1. Start Nix build in background
cd ~/.config/nix
darwin-rebuild switch --flake . &

# 2. Note the job number (e.g., [1])
# 3. Continue working with Homebrew/DMG version

# 4. Check build status later
jobs

# 5. When complete, remove temporary install
brew uninstall --cask zed  # if Homebrew
# or delete /Applications/Zed.app  # if DMG

# 6. Verify Nix version
which zed
zed --version
```

### Keeping configurations in sync:

If using manual install temporarily, your Nix config for Zed settings (in `home/common/apps/zed-editor.nix`) won't apply. You can:

1. **Wait for Nix version** - Settings apply automatically
2. **Manually configure** - Use Zed's UI settings temporarily
3. **Copy settings** - Export from `~/.config/zed/` to match your Nix config

## Testing Different Options

```bash
# Test Zed flake (doesn't install)
nix run 'github:zed-industries/zed'

# Test older nixpkgs (doesn't install)
nix shell 'github:NixOS/nixpkgs/nixos-24.05#zed-editor' -c zed

# Check if older version is cached
nix build 'github:NixOS/nixpkgs/nixos-24.05#zed-editor' --dry-run
```

## My Recommendation

**For you specifically:**

1. **Install via Homebrew NOW** (3 minutes):
   ```bash
   brew install --cask zed
   ```

2. **Keep your Nix config as-is** (with `doCheck = false`)

3. **Eventually rebuild with Nix** when you have time:
   ```bash
   darwin-rebuild switch --flake ~/.config/nix
   ```

4. **After Nix build completes**, remove Homebrew:
   ```bash
   brew uninstall --cask zed
   ```

**Why this approach:**
- ✅ Get working editor in 3 minutes
- ✅ No downtime
- ✅ Eventually Nix-managed
- ✅ Can wait for convenient time to rebuild

## Quick Command Reference

```bash
# Official DMG
curl -L https://zed.dev/api/releases/stable/latest/Zed-aarch64.dmg -o /tmp/Zed.dmg && open /tmp/Zed.dmg

# Homebrew
brew install --cask zed

# Try Zed flake
nix run 'github:zed-industries/zed'

# Your Nix build (background)
darwin-rebuild switch --flake ~/.config/nix &

# Check build status
jobs
fg  # Bring to foreground if needed

# Remove Homebrew when done
brew uninstall --cask zed
```

## Summary

**Fastest:** Official .dmg (2 min) or Homebrew (3 min)  
**Best compromise:** Hybrid approach  
**Most Nix-pure:** Wait for your build (15-25 min)  
**Most flexible:** Try Zed flake first

Choose based on your urgency and preferences! 🚀
