# Python Package Cache Analysis

## Current Status

? **Following Best Practices:**

- Using `python.withPackages` (recommended pattern from wiki)
- Using standard nixpkgs Python packages (pip, virtualenv, black, pytest, etc.)
- Packages cached in `nix-community.cachix.org` (priority=1)

? **Current Approach:**

- Standard nixpkgs Python packages (well-cached in nix-community cache)
- `nixpkgs-python` input has been removed (compatibility issues)

## Cache Configuration

1. `nix-community.cachix.org` (priority=1) - ? Active - Has standard nixpkgs packages

**Status:** Using nix-community cache for all Python packages

## Why nixpkgs-python Was Removed

The `nixpkgs-python` input was removed because:

1. Its packages had a different structure missing the `dependencies` attribute
2. This caused evaluation errors in some nixpkgs code
3. Standard nixpkgs Python packages are well-cached in nix-community already

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
- `nixpkgs-python` input removed (not needed)

This is the recommended approach from the NixOS wiki and provides good cache coverage for all Python packages.
