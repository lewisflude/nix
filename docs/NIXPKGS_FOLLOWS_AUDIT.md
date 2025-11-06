# nixpkgs Follows Audit Results

## Inputs Missing `follows = "nixpkgs"`

Based on analysis of your `flake.nix` and usage patterns, these inputs **should** have `follows = "nixpkgs"`:

### 1. `mac-app-util` ⚠️ **MISSING**

**Current:**

```nix
mac-app-util.url = "github:hraban/mac-app-util";
```

**Should be:**

```nix
mac-app-util = {
  url = "github:hraban/mac-app-util";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

**Reason:** Provides `darwinModules.default` and `homeManagerModules.default` (see `lib/system-builders.nix:122,159`)

---

### 2. `nix-homebrew` ⚠️ **MISSING**

**Current:**

```nix
nix-homebrew.url = "github:zhaofengli/nix-homebrew";
```

**Should be:**

```nix
nix-homebrew = {
  url = "github:zhaofengli/nix-homebrew";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

**Reason:** Provides `darwinModules.nix-homebrew` (see `lib/system-builders.nix:123`)

---

### 3. `nur` (Nix User Repository) ⚠️ **MISSING**

**Current:**

```nix
nur.url = "github:nix-community/NUR";
```

**Should be:**

```nix
nur = {
  url = "github:nix-community/NUR";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

**Reason:** Provides `modules.nixos.default` (see `lib/system-builders.nix:233`)

---

### 4. `vpn-confinement` ⚠️ **MISSING**

**Current:**

```nix
vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
```

**Should be:**

```nix
vpn-confinement = {
  url = "github:Maroka-chan/VPN-Confinement";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

**Reason:** Provides `nixosModules.default` (see `lib/system-builders.nix:228`)

---

### 5. `nixos-hardware` ❓ **NEEDS VERIFICATION**

**Current:**

```nix
nixos-hardware = {
  url = "github:NixOS/nixos-hardware";
};
```

**Status:** Check if it provides modules that need nixpkgs compatibility. Hardware modules typically do need version alignment.

**Recommendation:** Add `follows` if it provides hardware-specific modules:

```nix
nixos-hardware = {
  url = "github:NixOS/nixos-hardware";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

---

## Inputs Correctly Configured ✅

These inputs already have `follows = "nixpkgs"` set correctly:

- ✅ `darwin` - Provides modules
- ✅ `home-manager` - Provides modules
- ✅ `sops-nix` - Provides modules
- ✅ `niri` - Provides modules
- ✅ `musnix` - Provides modules
- ✅ `catppuccin` - Provides modules
- ✅ `determinate` - Provides modules
- ✅ `nix-topology` - Provides modules
- ✅ `rust-overlay` - Provides overlays
- ✅ `pre-commit-hooks` - Build tool
- ✅ All other overlay/package providers

---

## Inputs Correctly NOT Following ✅

- ✅ `chaotic` - Explicitly documented not to follow (cache reasons)
- ✅ `homebrew-j178` - Data-only flake (`flake = false`)
- ✅ `flake-parts` - Framework, doesn't need follows

---

## How to Apply Fixes

1. Edit `flake.nix` and add `follows = "nixpkgs"` to the inputs listed above
2. Run `nix flake update` to regenerate `flake.lock`
3. Verify with: `nix flake check`
4. Test a rebuild: `nixos-rebuild build` (or `darwin-rebuild build`)

## Expected Impact

After adding the missing `follows`:

- ✅ Reduced `nixpkgs` entries in `flake.lock` (from ~106 to ~45-50)
- ✅ Faster evaluation (fewer nixpkgs to process)
- ✅ Better binary cache hit rates
- ✅ Reduced build time and disk usage
- ✅ Improved compatibility between modules

## Verification

After making changes, verify the improvement:

```bash
# Count nixpkgs entries (should decrease)
jq '.nodes | to_entries | map(select(.value.inputs.nixpkgs != null)) | length' flake.lock

# Check for any inputs still missing follows
./scripts/utils/check-nixpkgs-follows.sh
```
