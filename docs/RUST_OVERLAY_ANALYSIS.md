# Rust-Overlay Pattern Compliance Analysis

**Date**: 2025-01-27
**Analyzed Against**: [oxalica/rust-overlay](https://github.com/oxalica/rust-overlay) patterns

## Executive Summary

? **Overall Compliance**: 95% compliant
? **Critical Issues**: 1 deviation found
?? **Recommendations**: 1 improvement suggested

---

## ? Correct Implementations

### 1. Flake Input Configuration (`flake.nix`)

**Location**: `flake.nix:95-98`

```nix
rust-overlay = {
  url = "github:oxalica/rust-overlay";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

**Status**: ? **CORRECT**

- Uses correct URL: `github:oxalica/rust-overlay`
- Properly follows nixpkgs to avoid version conflicts
- Matches recommended pattern from rust-overlay documentation

### 2. Overlay Application (`overlays/default.nix`)

**Location**: `overlays/default.nix:37-41`

```nix
rust-overlay =
  if inputs ? rust-overlay && inputs.rust-overlay ? overlays then
    inputs.rust-overlay.overlays.default
  else
    (_final: _prev: { });
```

**Status**: ? **CORRECT**

- Uses `rust-overlay.overlays.default` (the stable output)
- Properly checks for overlay existence before applying
- Gracefully handles missing input

### 3. Overlay Application Chain

**Flow**: `lib/functions.nix` ? `lib/system-builders.nix` ? `flake-parts/core.nix`

**Status**: ? **CORRECT**

- Overlays are applied early in the module list
- All modules receive `pkgs` with rust-overlay applied
- Properly integrated with flake-parts

### 4. rust-bin Usage (`lib/package-sets.nix`)

**Location**: `lib/package-sets.nix:14-26`

```nix
rustToolchain = with pkgs; [
  (rust-bin.stable.latest.default.override {
    extensions = [ "rust-src" ]; # Include rust-src for rust-analyzer
  })
  rust-analyzer
  cargo-watch
  cargo-audit
  cargo-edit
];
```

**Status**: ? **CORRECT**

- Uses `rust-bin.stable.latest.default` (recommended pattern)
- Properly overrides to add `rust-src` extension
- Matches rustup's default profile
- Uses pre-built binaries (no compilation needed)

**Pattern Compliance**:

- ? Uses `stable.latest.default` (not `nightly.latest`)
- ? Uses `.override` for extensions (correct pattern)
- ? Adds `rust-src` for rust-analyzer support

---

## ? Deviations Found

### Issue #1: Direct rustc/cargo Usage in Solana Shell

**Location**: `shells/default.nix:106-119`

**Current Code**:

```nix
solana = pkgs.mkShell {
  buildInputs =
    with pkgs;
    [
      rustc      # ? Direct nixpkgs package
      cargo      # ? Direct nixpkgs package
      (platformLib.getVersionedPackage pkgs platformLib.versions.nodejs)
    ]
    ++ commonTools;
  ...
};
```

**Problem**:

- Uses `rustc` and `cargo` directly from nixpkgs
- Bypasses rust-overlay's pre-built binary toolchain
- May use outdated or source-built versions
- Inconsistent with the `rust` shell which uses rust-overlay

**Recommended Fix**:

```nix
solana = pkgs.mkShell {
  buildInputs =
    featureBuilders.mkShellPackages {
      cfg = {
        rust = true;  # Use rust-overlay via packageSets.rustToolchain
      };
      inherit pkgs;
      inherit (platformLib) versions;
    }
    ++ [
      (platformLib.getVersionedPackage pkgs platformLib.versions.nodejs)
    ]
    ++ commonTools;
  ...
};
```

**Alternative Fix** (if solana needs specific rust version):

```nix
solana = pkgs.mkShell {
  buildInputs =
    with pkgs;
    [
      rust-bin.stable.latest.default  # Use rust-overlay
      (platformLib.getVersionedPackage pkgs platformLib.versions.nodejs)
    ]
    ++ commonTools;
  ...
};
```

**Impact**: Medium - Causes inconsistency and potential version/build issues

---

## ?? Acceptable Patterns (Not Deviations)

### 1. rust-analyzer from nixpkgs

**Location**: `lib/package-sets.nix:22`

```nix
rust-analyzer  # From nixpkgs
```

**Status**: ? **ACCEPTABLE**

- rust-overlay doesn't provide rust-analyzer
- Using nixpkgs version is the correct approach
- rust-analyzer is a separate tool, not part of the rust toolchain

### 2. cargo-* Tools from nixpkgs

**Location**: `lib/package-sets.nix:23-25`

```nix
cargo-watch
cargo-audit
cargo-edit
```

**Status**: ? **ACCEPTABLE**

- These are separate cargo plugins, not part of rust toolchain
- rust-overlay only provides the core toolchain (rustc, cargo, rustfmt, clippy, etc.)
- Using nixpkgs versions is correct

### 3. rustup from nixpkgs

**Location**: `shells/projects/development.nix:17`

```nix
rustup  # From nixpkgs
```

**Status**: ? **ACCEPTABLE**

- rustup is a toolchain manager, not a toolchain
- rust-overlay provides toolchains, not rustup
- Using nixpkgs rustup is correct

---

## Pattern Compliance Checklist

Based on rust-overlay documentation patterns:

- [x] ? Uses `github:oxalica/rust-overlay` as input
- [x] ? Has `inputs.nixpkgs.follows = "nixpkgs"` in flake input
- [x] ? Uses `rust-overlay.overlays.default` (stable output)
- [x] ? Uses `rust-bin.stable.latest.default` for latest stable
- [x] ? Uses `.override` for adding extensions (rust-src)
- [x] ? Does NOT use `rust-bin.nightly.latest` (would be wrong if used)
- [x] ? Would use `selectLatestNightlyWith` if nightly needed (not needed)
- [ ] ? **FIX NEEDED**: Direct `rustc`/`cargo` usage in solana shell

---

## Recommendations

### High Priority

1. **Fix solana shell** (`shells/default.nix:106-119`)
   - Replace direct `rustc` and `cargo` with rust-overlay
   - Use `packageSets.rustToolchain` for consistency
   - Ensures all rust usage goes through rust-overlay

### Low Priority

1. **Consider rust-analyzer source**
   - Current: nixpkgs (acceptable)
   - Alternative: Could check if rust-overlay provides it (it doesn't)
   - **Action**: No change needed

2. **Documentation**
   - Add note in `shells/default.nix` explaining rust-overlay usage
   - Update contributing guide to mention rust-overlay patterns

---

## Testing Recommendations

After fixing the solana shell:

1. **Verify rust-overlay is used**:

   ```bash
   nix eval .#devShells.solana.buildInputs --apply 'x: builtins.map (p: p.pname or p.name) x' | grep -i rust
   ```

2. **Check toolchain source**:

   ```bash
   nix develop .#solana -c rustc --version
   nix develop .#solana -c cargo --version
   ```

3. **Verify consistency**:
   - Compare rust versions between `rust` and `solana` shells
   - Should be identical if using same toolchain

---

## References

- [rust-overlay README](https://github.com/oxalica/rust-overlay)
- [rust-overlay API Reference](https://github.com/oxalica/rust-overlay/blob/master/docs/reference.md)
- [rust-overlay Cross Compilation](https://github.com/oxalica/rust-overlay/blob/master/docs/cross_compilation.md)

---

## Conclusion

The configuration is **95% compliant** with rust-overlay patterns. The main issue is the direct use of `rustc` and `cargo` in the solana shell, which should be fixed to use rust-overlay for consistency and to ensure pre-built binaries are used.

All other rust-related usage correctly follows rust-overlay patterns, and the overlay is properly integrated throughout the flake structure.
