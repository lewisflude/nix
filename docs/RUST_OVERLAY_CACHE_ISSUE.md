# Rust-Overlay Binary Cache Issue

## Problem

rust-overlay packages are not being substituted from binary caches, causing builds from source.

## Root Cause Analysis

### How rust-overlay Works

rust-overlay provides **pre-built binary toolchains** by:

1. Fetching official Rust toolchain binaries from `static.rust-lang.org`
2. Packaging them as Nix derivations with fixed-output hashes
3. These derivations download the binaries at build time

### Why They're Not Cached

**Key Issue**: rust-overlay packages are **fixed-output derivations** that download binaries from `static.rust-lang.org`, not from Nix binary caches.

The packages themselves are **not pre-built in binary caches** because:

1. They're fixed-output derivations (FODs) that fetch from upstream
2. The actual Rust binaries come from `static.rust-lang.org`, not Nix caches
3. Nix caches would only cache the **wrapper derivations**, not the toolchain binaries themselves

### What Gets Cached

- ? The **wrapper derivations** (symlinkJoin, etc.) - these can be cached
- ? The **actual Rust toolchain binaries** - these are downloaded from `static.rust-lang.org` at build time

## Solutions

### Option 1: Accept the Download (Recommended)

The first time you build a rust-overlay package, it will:

1. Download the Rust toolchain binaries from `static.rust-lang.org` (fast, CDN)
2. Create the Nix derivation
3. Cache the wrapper derivation locally

**Subsequent builds** will use the cached wrapper, but the initial download is unavoidable.

### Option 2: Pre-download Toolchains

You can pre-download specific toolchains:

```bash
# Pre-download the toolchain
nix build .#nixosConfigurations.jupiter.config.system.build.toplevel --no-link

# Or specifically:
nix build -f '<nixpkgs>' rust-bin.stable.latest.default --no-link
```

### Option 3: Use a Personal Cachix Cache

If you build rust-overlay packages, you can push them to your personal Cachix cache:

```bash
# After building
cachix push lewisflude <result-path>
```

This will cache the **wrapper derivations** for others, but they'll still need to download the actual binaries from `static.rust-lang.org` the first time.

## Why This is Actually Fine

1. **Fast Downloads**: `static.rust-lang.org` is a fast CDN
2. **One-Time Cost**: Each toolchain version is downloaded once
3. **Smaller Than Building**: Downloading binaries is much faster than building from source
4. **Standard Behavior**: This is how rust-overlay is designed to work

## Verification

To check if a rust-overlay package is substitutable:

```bash
# Get the outPath
RUST_PATH=$(nix eval --raw '.#nixosConfigurations.jupiter.config.system.build.toplevel' --apply 'x: x.pkgs.rust-bin.stable.latest.default.outPath')

# Check substitutability
nix path-info --json "$RUST_PATH" | jq '.[] | .substitutable'
```

**Expected Result**: `false` (because it's a fixed-output derivation that fetches from upstream)

## Comparison: rust-overlay vs nixpkgs rustc

| Aspect | rust-overlay | nixpkgs rustc |
|--------|-------------|---------------|
| Source | Pre-built binaries from `static.rust-lang.org` | Built from source |
| Cache | Wrapper cached, binaries downloaded | Fully cached if built |
| Build Time | Fast (download only) | Slow (compilation) |
| Binary Cache | Limited (wrapper only) | Full (if in cache) |

## Conclusion

**This is expected behavior**. rust-overlay packages are designed to download binaries from `static.rust-lang.org` rather than being fully cached in Nix binary caches. The download is fast (CDN) and happens once per toolchain version.

If you want fully cached Rust toolchains, you would need to:

1. Use nixpkgs `rustc` (but it's built from source, which is slower)
2. Build and push rust-overlay packages to your own Cachix cache (but binaries still download from upstream)

The current setup is optimal for most use cases.
