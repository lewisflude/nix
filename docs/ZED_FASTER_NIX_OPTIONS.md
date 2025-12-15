# Faster Zed Installation - Nix-Native Options

## The Core Problem

Your `doCheck = false` overlay creates a unique derivation hash that will **never** match any binary cache. This forces a build every time.

## Nix-Native Faster Options

### Option 1: Remove the Overlay (Use Cache)

**Speed:** ~30 seconds (if cached) or 30-45 min (if not)  
**Trade-off:** Slower builds when not cached, but might get cache hits

#### Implementation:

```nix
# overlays/default.nix
# CHANGE THIS:
flake-editors = _final: prev: {
  zed-editor = prev.zed-editor.overrideAttrs (oldAttrs: {
    doCheck = false;  # ← Remove this
  });
};

# TO THIS:
flake-editors = _final: prev: {
  inherit (prev) zed-editor;  # Use base nixpkgs version
};
```

**Pros:**
- Can use binary cache when available
- Matches upstream exactly
- Future updates might be instant

**Cons:**
- Tests add 15-20 minutes to build time
- Still not cached RIGHT NOW (versions too recent)
- Net slower until cache catches up

**When cache helps:**
- Older/stable versions (2+ weeks old)
- Popular packages
- Official nixpkgs releases

---

### Option 2: Use Zed Flake Directly (Might Have CI Cache)

**Speed:** Unknown (potentially fast if Zed publishes to zed.cachix.org)  
**Currently:** Disabled in your config due to past build issues

#### Re-enable the Zed Flake:

```nix
# overlays/default.nix
# CHANGE FROM:
flake-editors = _final: prev: {
  zed-editor = prev.zed-editor.overrideAttrs (oldAttrs: {
    doCheck = false;
  });
};

# TO:
flake-editors = final: prev:
  if inputs ? zed && inputs.zed ? packages && inputs.zed.packages ? ${system} then
    {
      zed-editor = inputs.zed.packages.${system}.default;
    }
  else
    {
      inherit (prev) zed-editor;
    };
```

**Why this might be faster:**
- Zed's CI might publish pre-built binaries to zed.cachix.org
- More frequent updates than nixpkgs
- Direct from source

**Test first:**
```bash
# Test without modifying config
nix build 'github:zed-industries/zed' --print-build-logs

# If successful, check time:
time nix build 'github:zed-industries/zed'
```

---

### Option 3: Pin to Older Nixpkgs (Stable/Cached)

**Speed:** ~30 seconds (if cached)  
**Trade-off:** Older Zed version

#### Add an override for stable nixpkgs:

```nix
# flake.nix - Add to inputs:
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";  # ← Add this
  # ... other inputs
};

# overlays/default.nix
flake-editors = _final: prev: {
  # Try stable channel version (more likely to be cached)
  zed-editor = inputs.nixpkgs-stable.legacyPackages.${system}.zed-editor or prev.zed-editor;
};
```

**Pros:**
- Stable versions more likely cached
- Faster if cache hit
- Still Nix-managed

**Cons:**
- Older version (might be months behind)
- Need to update input pins
- May not have latest features

---

### Option 4: Conditional Overlay (Smart)

**Speed:** Varies (use cache when available, optimize when not)  
**Best of both worlds**

#### Smart overlay that checks cache first:

```nix
# overlays/default.nix
flake-editors = final: prev:
  let
    # Try the base version first
    baseZed = prev.zed-editor;
    
    # Create optimized version
    optimizedZed = prev.zed-editor.overrideAttrs (oldAttrs: {
      doCheck = false;
    });
  in
  {
    # Use base by default (can use cache)
    zed-editor = baseZed;
    
    # Provide optimized variant
    zed-editor-fast = optimizedZed;
  };
```

Then in your home-manager config:

```nix
# home/common/apps/zed-editor.nix
programs.zed-editor = {
  enable = true;
  # Use fast variant only when needed
  package = pkgs.zed-editor-fast;
};
```

**Or make it automatic:**

```nix
# home/common/apps/zed-editor.nix
let
  # Use fast build for very recent versions
  # Use cached build for older versions
  useOptimized = builtins.compareVersions pkgs.zed-editor.version "0.215.0" >= 0;
in
{
  programs.zed-editor = {
    enable = true;
    package = if useOptimized then pkgs.zed-editor-fast else pkgs.zed-editor;
  };
}
```

---

### Option 5: Enable Zed Cachix Substituter (Already Done)

You already have this! Check if it helps:

```bash
# Check if Zed publishes to their cache
nix build '.#darwinConfigurations.mercury.pkgs.zed-editor' --print-build-logs -v

# Watch for lines like:
# "querying https://zed.cachix.org"
# "copying path from 'https://zed.cachix.org'"
```

**If you see cache hits**, great! If not, the versions are too recent or not published.

---

## Recommended Approach: Try Zed Flake First

### Step 1: Test Zed Flake

```bash
cd ~/.config/nix

# Test build time
time nix build 'github:zed-industries/zed' --print-build-logs
```

**If it's fast (< 5 minutes):** The Zed flake has better caching!  
**If it fails:** Stick with current approach  
**If it's slow (15+ minutes):** No benefit

### Step 2: If Fast, Enable in Config

```nix
# overlays/default.nix
flake-editors = final: prev:
  if inputs ? zed && inputs.zed ? packages && inputs.zed.packages ? ${system} then
    {
      # Use Zed flake if available
      zed-editor = inputs.zed.packages.${system}.default;
    }
  else
    {
      # Fallback to optimized nixpkgs version
      zed-editor = prev.zed-editor.overrideAttrs (oldAttrs: {
        doCheck = false;
      });
    };
```

### Step 3: Rebuild

```bash
darwin-rebuild switch --flake ~/.config/nix
```

---

## Comparison of Nix-Native Options

| Option | Speed (if cached) | Speed (if not) | Nix-Managed | Latest Version |
|--------|-------------------|----------------|-------------|----------------|
| **Current (doCheck=false)** | Never cached | 15-25 min | ✅ | ✅ |
| **Remove overlay** | 30 sec | 30-45 min | ✅ | ✅ |
| **Zed flake** | ? (test it) | ? | ✅ | ✅ |
| **Stable nixpkgs** | 30 sec | 30-45 min | ✅ | ❌ |
| **Conditional** | 30 sec | 15-25 min | ✅ | ✅ |

---

## My Recommendation

### Quick Test (5 minutes):

```bash
# Test if Zed flake is faster
time nix build 'github:zed-industries/zed' --print-build-logs
```

**Outcome A: Fast (< 5 min)** → Re-enable Zed flake in overlays  
**Outcome B: Slow (> 15 min)** → Keep current setup  
**Outcome C: Fails** → Keep current setup

### If Zed Flake Works:

Update your config to use it:

```nix
# flake.nix - Add to inputs (if not already there)
inputs = {
  # ... existing inputs ...
  zed.url = "github:zed-industries/zed";
};

# overlays/default.nix - Re-enable the commented code:
flake-editors =
  final: prev:
  if inputs ? zed && inputs.zed ? packages && inputs.zed.packages ? ${system} then
    {
      zed-editor = inputs.zed.packages.${system}.default;
    }
  else
    {
      inherit (prev) zed-editor;
    };
```

---

## Testing Commands

```bash
# Test current setup (your overlay)
time nix build '.#darwinConfigurations.mercury.pkgs.zed-editor'

# Test without overlay (base nixpkgs)
time nix build 'nixpkgs#zed-editor'

# Test Zed flake
time nix build 'github:zed-industries/zed'

# Test stable channel
time nix build 'github:NixOS/nixpkgs/nixos-24.05#zed-editor'

# Compare all
hyperfine \
  'nix build github:zed-industries/zed --rebuild' \
  'nix build nixpkgs#zed-editor --rebuild'
```

---

## Implementation Guide

### To Remove Overlay (Use Cache):

1. Edit `overlays/default.nix`:
   ```nix
   flake-editors = _final: prev: {
     inherit (prev) zed-editor;
   };
   ```

2. Rebuild:
   ```bash
   darwin-rebuild switch --flake ~/.config/nix
   ```

### To Enable Zed Flake:

1. Check `flake.nix` has zed input (it does)

2. Edit `overlays/default.nix`:
   ```nix
   # Uncomment the existing commented code
   flake-editors =
     final: prev:
     if inputs ? zed && inputs.zed ? packages && inputs.zed.packages ? ${system} then
       {
         zed-editor = inputs.zed.packages.${system}.default;
       }
     else
       {
         inherit (prev) zed-editor;
       };
   ```

3. Rebuild:
   ```bash
   darwin-rebuild switch --flake ~/.config/nix
   ```

---

## Bottom Line for Nix-Native Speed

**There is no magic faster Nix build** for the exact version you want (0.215.3 with your overlay). Your options within Nix are:

1. ✅ **Keep current setup** - Fastest build when no cache available (15-25 min)
2. 🔄 **Try Zed flake** - Might be faster if they publish binaries (TEST THIS!)
3. 📦 **Remove overlay** - Use cache when available, slower when not (0-45 min)
4. ⏰ **Use older version** - Fast if cached, but outdated (30 sec for old version)

**My advice:** Test the Zed flake (5 min test) and use it if faster. Otherwise, keep your current setup - it's already optimized!
