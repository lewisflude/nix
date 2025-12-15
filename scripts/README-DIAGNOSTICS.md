# Diagnostic Scripts Index

All scripts are in `/Users/lewisflude/.config/nix/scripts/`

## Quick Start

```bash
# Best script to run first - shows complete picture
./scripts/zed-summary.sh
```

## Available Scripts

### 1. `zed-summary.sh` ⭐ START HERE
**Purpose:** Quick overview of why Zed isn't cached  
**Run when:** You want a fast explanation  
**Shows:**
- Version differences
- Hash comparison
- Why no cache
- Recommendations

```bash
./scripts/zed-summary.sh
```

---

### 2. `test-cachix-simple.sh`
**Purpose:** Quick test if a package is in caches  
**Run when:** Testing if ANY package is cached  
**Shows:**
- Cache availability for specific package
- Which caches have it (if any)

```bash
./scripts/test-cachix-simple.sh
./scripts/test-cachix-simple.sh /nix/store/xxx-some-package-1.0
```

---

### 3. `test-zed-cachix.sh`
**Purpose:** Comprehensive Zed-specific diagnostics  
**Run when:** After `darwin-rebuild` to verify setup  
**Shows:**
- Store path
- Cache configuration status
- doCheck setting
- Dry-run preview

```bash
./scripts/test-zed-cachix.sh
```

---

### 4. `check-nix-config.sh`
**Purpose:** Verify system Nix configuration  
**Run when:** Checking if caches are configured  
**Shows:**
- All 20 substituters
- Trusted users
- Daemon status
- Config file locations

```bash
./scripts/check-nix-config.sh
```

---

### 5. `check-available-zed.sh`
**Purpose:** Compare your Zed vs nixpkgs Zed  
**Run when:** Understanding version differences  
**Shows:**
- Your flake version
- Nixpkgs version
- Whether either is cached
- Nixpkgs commit info

```bash
./scripts/check-available-zed.sh
```

---

### 6. `check-cachix-contents.sh`
**Purpose:** Verify caches are online  
**Run when:** Debugging cache connectivity  
**Shows:**
- Cache reachability
- Cache info
- Why versions might not be cached

```bash
./scripts/check-cachix-contents.sh
```

---

### 7. `compare-zed-versions.sh`
**Purpose:** Detailed version and hash comparison  
**Run when:** Deep dive into differences  
**Shows:**
- Hash comparison
- Cache tests for both versions
- Latest GitHub releases

```bash
./scripts/compare-zed-versions.sh
```

## Typical Workflow

### First Time Setup
```bash
# 1. Check configuration is correct
./scripts/check-nix-config.sh

# 2. Understand the situation
./scripts/zed-summary.sh

# 3. Read the full explanation
cat scripts/README-WHY-NO-CACHE.md
```

### After System Rebuild
```bash
# 1. Verify config applied
./scripts/check-nix-config.sh

# 2. Check if Zed is cached now
./scripts/test-cachix-simple.sh

# 3. Full diagnostic if needed
./scripts/test-zed-cachix.sh
```

### Periodic Checks (Weekly/Monthly)
```bash
# Quick test if newer versions are cached
./scripts/test-cachix-simple.sh
```

## Documentation

- **`README-WHY-NO-CACHE.md`** - Complete explanation of cache behavior
- **`README-TESTING-CACHIX.md`** - Full testing guide
- **`QUICK-TEST.md`** - Quick reference commands

## One-Liner Tests

### Check if zed.cachix.org is configured:
```bash
nix config show | grep "zed.cachix.org" && echo "Configured" || echo "Not configured"
```

### Check if specific package is cached:
```bash
ZED=$(nix eval --raw '.#darwinConfigurations.mercury.pkgs.zed-editor.outPath' 2>/dev/null)
curl -sI "https://zed.cachix.org${ZED}.narinfo" | grep "^HTTP"
```

### List all substituters:
```bash
nix config show | grep "^substituters = " | tr ' ' '\n' | nl
```

### Verify doCheck is false:
```bash
nix eval --json '.#darwinConfigurations.mercury.pkgs.zed-editor.drvAttrs' 2>/dev/null | grep -q '"doCheck":false' && echo "Tests disabled" || echo "Tests enabled"
```

## Troubleshooting

### "ignoring untrusted substituter" warnings
**Normal!** These warnings appear when YOU run nix commands. The Nix daemon (running as root) WILL use the substituters.

### Script shows "Not available" but I think it should be
1. Check nixpkgs version: `nix eval --raw 'nixpkgs#zed-editor.version'`
2. Wait a few days - caches lag behind releases
3. Your overlay creates unique hash - won't match cache

### Want to test without overlay?
```bash
# Temporarily test the nixpkgs version
nix build 'nixpkgs#zed-editor' --dry-run
```

## Quick Decisions

**"Should I keep the overlay?"**
```bash
./scripts/zed-summary.sh  # See recommendations at bottom
```

**"Is the base version cached?"**
```bash
./scripts/check-available-zed.sh  # Section 3 shows cache tests
```

**"Are my caches working?"**
```bash
./scripts/check-nix-config.sh  # Should show 20 substituters
```

## Summary

**Most useful script:** `./scripts/zed-summary.sh`  
**Most complete:** `./scripts/test-zed-cachix.sh`  
**Fastest check:** `./scripts/test-cachix-simple.sh`  
**Best explanation:** `./scripts/README-WHY-NO-CACHE.md`

All scripts are designed to be run safely anytime - they only READ, never modify.
