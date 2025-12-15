# Quick Nix-Native Zed Speed Improvements

## TL;DR

Your best Nix-native options:

1. **Test Zed flake** (might have CI cache) - 5 min test
2. **Remove overlay** (use potential cache) - config change
3. **Keep current** (already optimized) - no change

## 🧪 Test First (Recommended)

```bash
# Test if Zed flake is faster than your current setup
cd ~/.config/nix

# Current setup (with doCheck=false)
time nix build '.#darwinConfigurations.mercury.pkgs.zed-editor' --rebuild

# Zed flake (might have CI cache)
time nix build 'github:zed-industries/zed' --rebuild

# Compare times and decide
```

**If Zed flake is faster:** Implement Option A below  
**If times are similar:** Keep current setup

---

## Option A: Enable Zed Flake (Potentially Fastest)

Your config already has this code commented out! Just need to uncomment and test.

### Implementation:

<function_calls>
<invoke name="Read">
<parameter name="path">/Users/lewisflude/.config/nix/overlays/default.nix