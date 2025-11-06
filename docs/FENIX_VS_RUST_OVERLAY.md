# Fenix vs rust-overlay: Binary Cache Performance Comparison

## Quick Answer

**Yes, fenix would be faster** because it has pre-built binaries cached in `nix-community.cachix.org`, which you already have configured with priority=1.

## Performance Comparison

### rust-overlay (Current)

| Aspect | Details |
|--------|---------|
| **Binary Cache** | ? Not fully cached (only wrappers) |
| **Source** | Downloads from `static.rust-lang.org` at build time |
| **First Build** | Downloads binaries from upstream (CDN, but still a download) |
| **Subsequent Builds** | Uses cached wrapper, but binaries still download |
| **Cache Hit** | Wrapper only, not the toolchain binaries |

### fenix (Alternative)

| Aspect | Details |
|--------|---------|
| **Binary Cache** | ? Fully cached in `nix-community.cachix.org` |
| **Source** | Pre-built packages in binary cache |
| **First Build** | Fast substitution from cache (if cache hit) |
| **Subsequent Builds** | Instant substitution from cache |
| **Cache Hit** | Full toolchain packages cached |

## Why Fenix Would Be Faster

1. **You already have the cache configured**:

   ```nix
   extra-substituters = [
     "https://nix-community.cachix.org?priority=1"  # ? fenix uses this!
   ];
   ```

2. **Pre-built packages**: fenix packages are built and pushed to the cache, so they're available immediately

3. **No upstream downloads**: Unlike rust-overlay, fenix doesn't need to download from `static.rust-lang.org`

4. **Better cache coverage**: The `nix-community` cache has good coverage for fenix packages

## Migration Considerations

### Similarities

Both provide:

- ? Stable, beta, and nightly toolchains
- ? Minimal, default, and complete profiles
- ? Component selection (withComponents)
- ? Cross-compilation support
- ? rust-toolchain file support

### Differences

| Feature | rust-overlay | fenix |
|---------|-------------|-------|
| **API Style** | `rust-bin.stable.latest.default` | `fenix.stable.toolchain` |
| **Binary Cache** | Limited (wrappers only) | Full (pre-built packages) |
| **Cache Location** | None (downloads from upstream) | `nix-community.cachix.org` |
| **Override Pattern** | `.override { extensions = [...] }` | `.withComponents [...]` |
| **Nightly Latest** | `selectLatestNightlyWith` | `latest.toolchain` |

### Migration Example

**Current (rust-overlay)**:

```nix
rustToolchain = with pkgs; [
  (rust-bin.stable.latest.default.override {
    extensions = [ "rust-src" ];
  })
  rust-analyzer
];
```

**With fenix**:

```nix
rustToolchain = with pkgs; [
  (fenix.stable.withComponents [
    "cargo"
    "clippy"
    "rust-src"
    "rustc"
    "rustfmt"
  ])
  fenix.rust-analyzer  # or rust-analyzer-nightly
];
```

## Implementation Changes Needed

### 1. Update `flake.nix`

```nix
inputs = {
  # Remove rust-overlay
  # rust-overlay = {
  #   url = "github:oxalica/rust-overlay";
  #   inputs.nixpkgs.follows = "nixpkgs";
  # };

  # Add fenix
  fenix = {
    url = "github:nix-community/fenix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

### 2. Update `overlays/default.nix`

```nix
fenix-overlay =
  if inputs ? fenix && inputs.fenix ? overlays then
    inputs.fenix.overlays.default
  else
    (_final: _prev: { });
```

### 3. Update `lib/package-sets.nix`

```nix
rustToolchain = with pkgs; [
  # Use fenix's stable toolchain with components
  (fenix.stable.withComponents [
    "cargo"
    "clippy"
    "rust-src"
    "rustc"
    "rustfmt"
  ])
  # rust-analyzer from fenix (nightly) or nixpkgs
  fenix.rust-analyzer  # or rust-analyzer-nightly with overlay
  cargo-watch
  cargo-audit
  cargo-edit
];
```

## Performance Impact Estimate

### rust-overlay (Current)

- **First build**: ~2-5 minutes (downloads from `static.rust-lang.org`)
- **Subsequent builds**: ~30 seconds (cached wrapper, but still downloads binaries)
- **Cache hit rate**: Low (only wrappers cached)

### fenix (Proposed)

- **First build**: ~10-30 seconds (substitution from `nix-community.cachix.org`)
- **Subsequent builds**: ~5-10 seconds (instant cache hit)
- **Cache hit rate**: High (full packages cached)

**Estimated speedup**: 2-10x faster, depending on network conditions

## Trade-offs

### Advantages of fenix

- ? Faster builds (pre-built in cache)
- ? Better cache coverage
- ? No upstream downloads needed
- ? More predictable build times

### Advantages of rust-overlay

- ? More mature/stable (older project)
- ? Simpler API (`rust-bin.stable.latest.default`)
- ? Direct from official Rust source
- ? Better documentation/examples

## Recommendation

**Switch to fenix if**:

- ? You want faster builds (cache hits)
- ? You're okay with a slightly different API
- ? You want better cache utilization

**Stay with rust-overlay if**:

- ? You prefer the simpler API
- ? You want direct downloads from official source
- ? Current performance is acceptable

## Cache Verification

To verify fenix cache availability:

```bash
# Check if fenix packages are in cache
nix path-info --json $(nix eval --raw '.#nixosConfigurations.jupiter.config.system.build.toplevel' --apply 'x: x.pkgs.fenix.stable.toolchain.outPath') | jq '.[] | .substitutable'
```

Expected: `true` (if using fenix and cache is available)

## Conclusion

**Yes, fenix would be faster** because:

1. Packages are pre-built and cached in `nix-community.cachix.org`
2. You already have this cache configured with high priority
3. No need to download from `static.rust-lang.org`
4. Better cache hit rates

The migration is straightforward, and the performance improvement would be significant, especially for repeated builds.
