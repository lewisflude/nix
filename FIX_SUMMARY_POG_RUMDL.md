# Fix Summary: Resolved `rumdl` Evaluation Error

## Problem

Development shells and flake evaluation were failing with this error:

```
error: evaluation aborted with the following error message:
'lib.customisation.callPackageWith: Function called without required argument "rumdl"
at /nix/store/.../nix/tools.nix:74, did you mean "mdl", "rml" or "rund"?'
```

## Root Cause

The `pre-commit-hooks` flake input was using its own independent `nixpkgs` input, which pulled in a newer version that contained a breaking change in the `pog` dependency. The `pog` package's internal `tools.nix` file now requires a `rumdl` parameter that wasn't being provided.

## Solution

Made the `pre-commit-hooks` input follow our main `nixpkgs` input by adding:

```nix
pre-commit-hooks = {
  url = "github:cachix/pre-commit-hooks.nix";
  inputs.nixpkgs.follows = "nixpkgs";  # ← Added this line
};
```

This ensures all flake inputs use a consistent `nixpkgs` version, avoiding transitive dependency conflicts.

## Changes Made

1. **`flake.nix`**: Added `inputs.nixpkgs.follows = "nixpkgs"` to `pre-commit-hooks` input
2. **`flake.lock`**: Updated to use consistent `nixpkgs` across all inputs

## Verification

After the fix:

- ✅ `nix develop '.#default'` works successfully
- ✅ `nix flake check --no-build` passes without errors
- ✅ All development shells evaluate correctly
- ✅ POG apps are available (`nix run .#update-all`, etc.)

## Technical Details

### What Happened

1. Recent `pre-commit-hooks` update pulled in `nixpkgs` from `2025-10-02`
2. This `nixpkgs` snapshot contained a `pog` version with breaking API changes
3. The `pog` package's `tools.nix` file added a new required parameter `rumdl`
4. Our flake wasn't expecting this parameter, causing evaluation to fail

### Why Following nixpkgs Works

By making `pre-commit-hooks` follow our `nixpkgs`:

- All packages are built from the same `nixpkgs` snapshot
- No version mismatches between transitive dependencies
- Consistent behavior across the entire flake
- Binary cache hits are maximized (same package versions)

## Best Practice

**Always make flake inputs follow your main `nixpkgs` input** to avoid transitive dependency conflicts:

```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  some-input = {
    url = "github:example/input";
    inputs.nixpkgs.follows = "nixpkgs";  # ← Important!
  };
};
```

## Related Documentation

- See `CONVENTIONS.md` for flake input conventions
- See `docs/reference/architecture.md` for dependency management patterns
