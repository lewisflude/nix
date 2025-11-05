# Python Package Cache Analysis

## Current Status

? **Following Best Practices:**

- Using `python.withPackages` (recommended pattern from wiki)
- Using standard nixpkgs Python packages (pip, virtualenv, black, pytest, etc.)
- Packages cached in `nix-community.cachix.org` (priority=1)

? **Current Approach:**

- Standard nixpkgs Python packages (well-cached in nix-community cache)
- nixpkgs-python overlay disabled due to compatibility issues

## Cache Configuration

1. `nix-community.cachix.org` (priority=1) - ? Active - Has standard nixpkgs packages
2. `nixpkgs-python.cachix.org` (priority=2) - ?? Not used (overlay disabled)

**Status:** Using nix-community cache for all Python packages

## Why nixpkgs-python Overlay is Disabled

The overlay was disabled because nixpkgs-python packages have a different structure - they're missing the `dependencies` attribute that some nixpkgs code expects. This causes evaluation errors.

## Verification

To check if packages are being cached:

```bash
# Check cache hit rate for Python packages
nix path-info -r /nix/store/*python3.13* | grep substituter

# Build Home Assistant and watch for cache hits
nix build --verbose .#home-assistant 2>&1 | grep -E "substituting|copying"
```

## Conclusion

? **Current setup:**

- Using standard nixpkgs Python packages (following wiki best practices)
- Packages cached in nix-community cache (priority=1)
- nixpkgs-python overlay disabled due to compatibility issues

This is the recommended approach from the NixOS wiki and should provide good cache coverage for most Python packages.
