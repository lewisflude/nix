# Guide: When Should Flake Inputs Follow nixpkgs?

This guide helps you determine whether a flake input should have `inputs.nixpkgs.follows = "nixpkgs"` set.

## Quick Decision Tree

```
Does the input provide:
├─ NixOS/Darwin/Home Manager modules? → ✅ SHOULD follow
├─ Overlays or packages? → ✅ SHOULD follow
├─ Libraries/tools that use nixpkgs? → ✅ SHOULD follow
├─ Just data/source (flake = false)? → ❌ NO follows needed
└─ Explicitly says "don't follow"? → ❌ NO follows (e.g., chaotic-nyx)
```

## Detailed Rules

### ✅ Inputs That SHOULD Follow nixpkgs

1. **Module Providers**
   - Any input that provides `nixosModules`, `darwinModules`, or `homeManagerModules`
   - Examples: `home-manager`, `darwin`, `sops-nix`, `niri`, `musnix`, `catppuccin`
   - **Why**: Modules need to be compatible with your nixpkgs version

2. **Overlay Providers**
   - Any input that provides `overlays` that modify packages
   - Examples: `rust-overlay`, `nur` (Nix User Repository)
   - **Why**: Overlays operate on nixpkgs packages and need version compatibility

3. **Package Providers**
   - Any input that provides `packages` or `legacyPackages`
   - Examples: `ghostty`, `helix` (when used as package source)
   - **Why**: Packages are built against nixpkgs

4. **Build Tools**
   - Tools that integrate with nixpkgs during evaluation
   - Examples: `pre-commit-hooks`, `flake-parts` (if it uses nixpkgs internally)
   - **Why**: Need consistent nixpkgs version for builds

### ❌ Inputs That Should NOT Follow nixpkgs

1. **Explicitly Documented Exceptions**
   - Inputs that explicitly say not to follow (usually for cache/performance reasons)
   - Example: `chaotic-nyx` - uses its own nixpkgs for binary cache compatibility
   - **Why**: The input maintainer has specific reasons (usually documented in their README)

2. **Data-Only Flakes**
   - Flakes marked with `flake = false`
   - Examples: `homebrew-j178` (Homebrew tap formulas)
   - **Why**: These are just data sources, not Nix code

3. **Standalone Tools**
   - Tools that don't interact with nixpkgs at all
   - Rare, but possible for pure data/config flakes

## How to Check an Input

### Method 1: Check the Input's Repository

1. Visit the input's GitHub/GitLab repository
2. Look at its `flake.nix`:

   ```nix
   inputs = {
     nixpkgs.url = "github:nixos/nixpkgs/...";  # Has nixpkgs input
   };
   ```

3. Check its README for any notes about `follows`

### Method 2: Check Your Usage

Look at how you use the input in your code:

```nix
# If you see patterns like this, it likely needs follows:
inputs.some-input.nixosModules.default
inputs.some-input.overlays.default
inputs.some-input.packages.${system}.some-package
```

### Method 3: Check flake.lock

```bash
# Count how many nixpkgs entries exist
jq '.nodes | to_entries | map(select(.value.inputs.nixpkgs != null)) | length' flake.lock

# If this number is much higher than your input count, some inputs may be missing follows
```

## Common Patterns in Your Config

### ✅ Currently Following (Correct)

```nix
darwin = {
  url = "github:nix-darwin/nix-darwin/master";
  inputs.nixpkgs.follows = "nixpkgs";  # ✅ Provides modules
};

home-manager = {
  url = "github:nix-community/home-manager";
  inputs.nixpkgs.follows = "nixpkgs";  # ✅ Provides modules
};

rust-overlay = {
  url = "github:oxalica/rust-overlay";
  inputs.nixpkgs.follows = "nixpkgs";  # ✅ Provides overlays
};
```

### ❌ Explicitly Not Following (Correct)

```nix
chaotic = {
  url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
  # Do NOT follow nixpkgs - this breaks their cache
  # ✅ Correctly documented exception
};
```

### ❓ Needs Review

Check these inputs manually:

1. **mac-app-util** - Check if it provides modules that need nixpkgs compatibility
2. **nix-homebrew** - Check if it needs nixpkgs for Homebrew integration
3. **nixos-hardware** - Check if hardware modules need specific nixpkgs version
4. **vpn-confinement** - Check if it provides modules
5. **nix-topology** - Already has follows, verify it's correct

## Impact of Missing Follows

If an input should follow nixpkgs but doesn't:

- ❌ **Build bloat**: Multiple nixpkgs versions get downloaded/built
- ❌ **Incompatibility**: Modules may not work with your nixpkgs version
- ❌ **Cache misses**: Binary caches may not match
- ❌ **Evaluation slowdown**: More nixpkgs to evaluate

## Verification Script

Use the provided script to check your configuration:

```bash
./scripts/utils/check-nixpkgs-follows.sh
```

This will:

- Analyze your `flake.nix` inputs
- Check which ones have `follows` set
- Suggest which ones might need it based on usage patterns
- Flag potential issues

## Best Practices

1. **When in doubt, check the input's documentation**
2. **If an input provides modules/overlays, it should follow**
3. **If explicitly documented not to follow, respect that**
4. **Run the verification script after adding new inputs**
5. **Review `flake.lock` periodically for unexpected nixpkgs entries**

## References

- [Nix Flakes Manual - Input follows](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake#flake-input-follows)
- [Flake Follows RFC](https://github.com/tweag/rfcs/blob/flakes/rfcs/0049-flakes.md#follows)
