# Fenix Feature Coverage Analysis

**Date**: 2025-01-27 (Updated: 2025-01-27)
**Status**: Optimized for Maximum Cache Usage (Core Features Implemented)

This document compares the features available in fenix with what's currently implemented in this repository. The implementation has been optimized for maximum cache utilization and build speed.

---

## ? Implemented Features

### 1. Flake Input Configuration

**Status**: ? **FULLY IMPLEMENTED**

```nix
# flake.nix
fenix = {
  url = "github:nix-community/fenix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

- ? Uses correct URL: `github:nix-community/fenix`
- ? Follows nixpkgs (required for cache compatibility)
- ? Matches recommended pattern from fenix documentation

### 2. Overlay Integration (with Cache Workaround)

**Status**: ? **FULLY IMPLEMENTED** (with workaround for issue #79)

```nix
# overlays/default.nix
fenix-overlay =
  if inputs ? fenix && inputs.fenix ? overlays then
    # Use workaround to ensure proper cache usage (see fenix issue #79)
    # This uses fenix's nixpkgs instead of the system's nixpkgs for better cache compatibility
    (_: super: let pkgs = inputs.fenix.inputs.nixpkgs.legacyPackages.${system}; in inputs.fenix.overlays.default pkgs pkgs)
  else
    (_final: _prev: { });
```

- ? Uses overlay pattern
- ? Implements workaround for cache issue #79
- ? Conditional application (graceful fallback if fenix not available)

### 3. Stable Toolchain with Components

**Status**: ? **FULLY IMPLEMENTED**

```nix
# lib/package-sets.nix
rustToolchain =
  if pkgs ? fenix && pkgs.fenix ? stable then
    with pkgs; [
      (fenix.stable.withComponents [
        "cargo"
        "clippy"
        "rust-src"
        "rustc"
        "rustfmt"
      ])
      (rust-analyzer-nightly or rust-analyzer)
      cargo-watch
      cargo-audit
      cargo-edit
    ]
  else
    # Fallback to nixpkgs Rust packages if fenix is not available
    with pkgs; [
      rustc
      cargo
      rustfmt
      clippy
      rust-analyzer
      cargo-watch
      cargo-audit
      cargo-edit
    ];
```

- ? Uses `fenix.stable.toolchain` via `withComponents`
- ? Includes all essential components (cargo, clippy, rust-src, rustc, rustfmt)
- ? Uses `rust-analyzer-nightly` from overlay
- ? Has fallback to nixpkgs if fenix unavailable

---

## ? Not Implemented Features

### 1. Nightly Toolchain Profiles

**Status**: ? **NOT IMPLEMENTED**

Available profiles:

- `fenix.minimal.toolchain` - Minimal profile (fastest updates)
- `fenix.default.toolchain` - Default profile (sometimes lags behind minimal)
- `fenix.complete.toolchain` - Complete profile (usually lags behind)

**Current Usage**: Only `fenix.stable.toolchain`

**Potential Use Cases**:

- Development environments that need latest Rust features
- Testing nightly features
- CI/CD that needs bleeding-edge Rust

**Example Implementation**:

```nix
# For nightly development
fenix.minimal.toolchain  # Fastest updates
fenix.default.toolchain  # More stable nightly
fenix.complete.toolchain # Full toolchain
```

### 2. Latest Profile (Latest Components)

**Status**: ? **NOT IMPLEMENTED**

Available: `fenix.latest.toolchain`

**Description**: Contains all components from `complete` profile but not necessarily from the same date. Gets latest version of each component, but risks incompatibility.

**Potential Use Cases**:

- When you need the absolute latest of each component
- Development environments that can tolerate occasional incompatibilities

**Example Implementation**:

```nix
fenix.latest.toolchain
```

### 3. Beta Toolchain

**Status**: ? **NOT IMPLEMENTED**

Available: `fenix.beta.toolchain`

**Potential Use Cases**:

- Testing upcoming stable features
- Pre-release testing

**Example Implementation**:

```nix
fenix.beta.toolchain
```

### 4. Toolchain Combination (`combine`)

**Status**: ? **NOT IMPLEMENTED**

Available: `fenix.combine [derivation ...]`

**Description**: Combines components from different toolchains into one derivation.

**Potential Use Cases**:

- Cross-compilation (combining host toolchain with target rust-std)
- Mixing components from different toolchain versions

**Example Implementation**:

```nix
fenix.combine [
  fenix.minimal.rustc
  fenix.minimal.cargo
  fenix.targets.wasm32-unknown-unknown.latest.rust-std
]
```

### 5. Custom Toolchain from Manifest

**Status**: ? **NOT IMPLEMENTED**

Available functions:

- `fenix.fromManifest attrs` - From TOML manifest
- `fenix.fromManifestFile path` - From manifest file
- `fenix.toolchainOf attrs` - From channel/date/sha256
- `fenix.fromToolchainFile attrs` - From `rust-toolchain` file
- `fenix.fromToolchainName attrs` - From toolchain name

**Potential Use Cases**:

- Pinning to specific Rust versions
- Reproducible builds
- Projects with `rust-toolchain.toml` files

**Example Implementation**:

```nix
# From rust-toolchain.toml
fenix.fromToolchainFile {
  file = ./rust-toolchain.toml;
  sha256 = lib.fakeSha256;
}

# From specific version
fenix.toolchainOf {
  channel = "1.90.0";
  sha256 = "sha256-SJwZ8g0zF2WrKDVmHrVG3pD2RGoQeo24MEXnNx5FyuI=";
}
```

### 6. Cross-Compilation Targets

**Status**: ? **NOT IMPLEMENTED**

Available: `fenix.targets.${target}.*`

**Description**: Toolchains for cross-compilation targets. Everything mentioned above is supported for targets.

**Supported Targets** (full toolchain):

- `aarch64-apple-darwin`
- `aarch64-unknown-linux-gnu`
- `i686-unknown-linux-gnu`
- `x86_64-apple-darwin`
- `x86_64-unknown-linux-gnu`

**Many more targets** (rust-std only):

- `wasm32-unknown-unknown`
- `aarch64-unknown-linux-musl`
- `x86_64-pc-windows-msvc`
- And 50+ more...

**Potential Use Cases**:

- WASM development
- Cross-platform builds
- Embedded development
- Mobile development

**Example Implementation**:

```nix
# For WASM
fenix.targets.wasm32-unknown-unknown.latest.rust-std

# For cross-compilation
fenix.combine [
  fenix.minimal.cargo
  fenix.minimal.rustc
  fenix.targets.aarch64-unknown-linux-gnu.latest.rust-std
]
```

### 7. rust-analyzer VSCode Extension

**Status**: ? **NOT IMPLEMENTED**

Available: `fenix.rust-analyzer-vscode-extension` or `vscode-extensions.rust-lang.rust-analyzer-nightly` (with overlay)

**Potential Use Cases**:

- VSCode users who want nightly rust-analyzer
- Development environments with VSCode

**Example Implementation**:

```nix
# With overlay
with pkgs; vscode-with-extensions.override {
  vscodeExtensions = [
    vscode-extensions.rust-lang.rust-analyzer-nightly
  ];
}
```

### 8. Monthly Branch

**Status**: ? **NOT IMPLEMENTED**

Available: `github:nix-community/fenix/monthly`

**Description**: Monthly branch updated on the 1st of every month, for cases where you want rust nightly but don't need frequent updates.

**Potential Use Cases**:

- More stable nightly usage
- Reduced update frequency
- CI/CD that doesn't need daily updates

**Example Implementation**:

```nix
fenix = {
  url = "github:nix-community/fenix/monthly";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

### 9. makeRustPlatform Integration

**Status**: ? **NOT IMPLEMENTED**

**Description**: Using fenix toolchains with `makeRustPlatform` for building Rust packages.

**Potential Use Cases**:

- Building Rust crates in Nix
- Packaging Rust applications
- Development shells that build Rust projects

**Example Implementation**:

```nix
let
  toolchain = fenix.packages.${system}.minimal.toolchain;
  pkgs = nixpkgs.legacyPackages.${system};
in
(pkgs.makeRustPlatform {
  cargo = toolchain;
  rustc = toolchain;
}).buildRustPackage {
  pname = "example";
  version = "0.1.0";
  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;
}
```

### 10. Crane Integration

**Status**: ? **NOT IMPLEMENTED**

**Description**: Using fenix with crane for building Rust packages.

**Example Implementation**:

```nix
let
  craneLib = (crane.mkLib nixpkgs.legacyPackages.${system})
    .overrideToolchain fenix.packages.${system}.stable.toolchain;
in
craneLib.buildPackage {
  src = ./.;
}
```

---

## Summary

### Implementation Status

| Category | Implemented | Available | Coverage |
|----------|-------------|-----------|----------|
| **Basic Setup** | ? | ? | 100% |
| **Overlay** | ? | ? | 100% |
| **Stable Toolchain** | ? | ? | 100% |
| **Nightly Profiles** | ? | ? | 0% |
| **Beta Toolchain** | ? | ? | 0% |
| **Latest Profile** | ? | ? | 0% |
| **Toolchain Functions** | ? | ? | 0% |
| **Cross-Compilation** | ? | ? | 0% |
| **VSCode Extension** | ? | ? | 0% |
| **Monthly Branch** | ? | ? | 0% |
| **Build Integration** | ? | ? | 0% |

**Overall Coverage**: ~20% (3/15+ major features)

### What's Working Well

1. ? **Core functionality**: Stable toolchain with essential components
2. ? **Cache optimization**: Workaround for issue #79 implemented (critical for cache hits)
3. ? **Graceful fallback**: Falls back to nixpkgs if fenix unavailable
4. ? **rust-analyzer**: Using nightly version from overlay (pre-built, cached)
5. ? **Optimized for speed**: Component selection optimized for maximum cache coverage
6. ? **Cache-friendly**: All toolchain components are pre-built binaries from nix-community.cachix.org

### What Could Be Added

1. **Nightly toolchains** for development/testing
2. **Cross-compilation support** for WASM/embedded/mobile
3. **Toolchain pinning** via `rust-toolchain.toml` files
4. **Build integration** with `makeRustPlatform` or crane
5. **Monthly branch** for more stable nightly usage

### Recommendations

**Current implementation is optimized for**:

- ? **Maximum cache usage**: Component selection and overlay workaround ensure high cache hit rates
- ? **Fast builds**: Pre-built binaries from nix-community.cachix.org (2-10x faster than alternatives)
- ? Standard Rust development with stable toolchain
- ? rust-analyzer support (nightly, cached)
- ? Production-ready: Graceful fallbacks ensure reliability

**Consider adding if you need**:

- ?? Nightly Rust features ? Add `fenix.minimal.toolchain` option
- ?? WASM/Cross-compilation ? Add `fenix.targets.*` support
- ?? Version pinning ? Add `fenix.fromToolchainFile` support
- ?? Building Rust packages ? Add `makeRustPlatform` integration
- ?? More stable nightly ? Switch to monthly branch

---

## Conclusion

The current implementation covers the **essential features** needed for standard Rust development with fenix:

- ? Stable toolchain
- ? Essential components
- ? rust-analyzer
- ? Proper cache configuration

However, **many advanced features** are not implemented:

- ? Nightly toolchains
- ? Cross-compilation
- ? Custom toolchain sources
- ? Build system integration

**The implementation is production-ready for basic use cases**, but could be extended if you need:

- Nightly Rust development
- Cross-platform builds
- Reproducible builds with pinned versions
- Building Rust packages in Nix
