# Community Overlays

This configuration includes three community-maintained overlays that extend nixpkgs with additional packages.

## nixpkgs-xr - VR/AR/XR Tools

**Source:** https://github.com/nix-community/nixpkgs-xr  
**Maintainer:** [@Scrumplex](https://github.com/Scrumplex)  
**Binary Cache:** https://nix-community.cachix.org (automatically configured)

Provides bleeding-edge and automated builds of VR/AR/XR packages for NixOS.

### Available Packages

- `wivrn` - OpenXR streaming for Quest headsets (includes embedded Monado)
- `monado` - Standalone OpenXR runtime (not needed when using WiVRn)
- `xrizer` - OpenVR → OpenXR translation (modern replacement for OpenComposite)
- `wayvr` - Wayland VR compositor
- Many more - see [nixpkgs-xr packages](https://github.com/nix-community/nixpkgs-xr#packages)

### Usage

```nix
# In system configuration or home-manager
environment.systemPackages = [
  pkgs.wivrn
  pkgs.monado
];
```

### Integration

The overlay is applied via the NixOS module `nixpkgs-xr.nixosModules.nixpkgs-xr`, which automatically:
- Adds the overlay to nixpkgs
- Configures the nix-community binary cache
- Keeps packages updated regularly

**Implementation:** See `lib/system-builders.nix` for module integration.

---

## NUR - Nix User Repository

**Source:** https://github.com/nix-community/NUR  
**Maintainer:** [@Pandapip1](https://github.com/Pandapip1)  
**Binary Cache:** None (packages built from source)

Community-driven meta repository with 1700+ stars. Provides access to hundreds of user-maintained package repositories.

### Available Repositories

NUR includes repos from 300+ contributors. Notable examples:
- `mic92` - Various packages and tools
- `colinsane` - Mobile Linux packages
- `rycee` - Home Manager creator's packages
- And many more...

Browse all repos: https://nur.nix-community.org/

### Usage

```nix
# Access packages via: pkgs.nur.repos.<author>.<package>

# In system configuration or home-manager
environment.systemPackages = [
  pkgs.nur.repos.mic92.hello-nur
  pkgs.nur.repos.colinsane.calls
];
```

### Important Notes

- ⚠️ **No binary cache** - Packages are built from source
- ⚠️ **Not reviewed** - Packages are maintained by individual contributors
- ✅ **Evaluated regularly** - NUR checks repositories daily for evaluation errors

**Security:** Review package expressions before installing. NUR does not review content.

---

## nixpkgs-wayland - Bleeding-Edge Wayland

**Source:** https://github.com/nix-community/nixpkgs-wayland  
**Maintainers:** [@colemickens](https://github.com/colemickens), [@Artturin](https://github.com/Artturin)  
**Binary Cache:** https://nixpkgs-wayland.cachix.org (automatically configured)

Automated, pre-built packages for Wayland compositors and tools built from **unreleased** upstream versions.

### Available Packages

- `sway-unwrapped` - i3-compatible Wayland compositor
- `wlroots` - Compositor library
- `wev` - Wayland event viewer
- `wl-clipboard` - Clipboard utilities
- `kanshi` - Dynamic display configuration
- `mako` - Notification daemon
- `slurp` - Region selector
- `grim` - Screenshot tool
- Many more - see [nixpkgs-wayland packages](https://github.com/nix-community/nixpkgs-wayland#packages)

### Usage

```nix
# Packages are available directly (overlay applied automatically)
environment.systemPackages = [
  pkgs.wev
  pkgs.kanshi
  pkgs.foot
];
```

### CI/CD Pipeline

nixpkgs-wayland has automated builds:
1. **Update** - Advances nixpkgs and upgrades packages
2. **Advance** - Tests against latest nixos-unstable
3. **Build** - Verifies master builds correctly

Packages are updated daily and pushed to Cachix.

### Relevant to This Config

Your Niri compositor setup benefits from:
- Latest Wayland protocols
- Bleeding-edge compositor features
- Modern Wayland tooling

---

## Testing Package Availability

```bash
# Test nixpkgs-xr
nix eval .#nixosConfigurations.jupiter.pkgs.wivrn.name

# Test nixpkgs-wayland
nix eval .#nixosConfigurations.jupiter.pkgs.wev.name

# Test NUR (list all repos)
nix eval --json .#nixosConfigurations.jupiter.pkgs.nur.repos --apply 'builtins.attrNames'

# Search NUR for specific packages
# Visit: https://nur.nix-community.org/
```

---

## Implementation Details

### Flake Inputs

See `flake.nix`:
```nix
nixpkgs-xr.url = "github:nix-community/nixpkgs-xr";
nur.url = "github:nix-community/NUR";
nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
```

### Overlay Configuration

See `overlays/default.nix`:
- `nur` - Applied via `inputs.nur.overlays.default`
- `nixpkgs-wayland` - Applied via `inputs.nixpkgs-wayland.overlay` (singular!)
- `nixpkgs-xr` - Applied via NixOS module (not directly in overlays)

### Binary Caches

See `lib/constants.nix`:
```nix
binaryCaches = {
  substituters = [
    "https://nix-community.cachix.org"
    "https://nixpkgs-wayland.cachix.org"
  ];
  trustedPublicKeys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
  ];
};
```

---

## Troubleshooting

### Package Not Found

If a package isn't available:

1. **Check overlay is applied:**
   ```bash
   nix eval .#nixosConfigurations.jupiter.pkgs.nur --apply 'p: builtins.attrNames p' | grep repos
   ```

2. **Verify flake.lock is updated:**
   ```bash
   nix flake lock --update-input nixpkgs-xr
   ```

3. **Check source repository:**
   - nixpkgs-xr: https://github.com/nix-community/nixpkgs-xr
   - NUR: https://nur.nix-community.org/
   - nixpkgs-wayland: https://github.com/nix-community/nixpkgs-wayland

### Build Failures

**For NUR packages:**
- No binary cache - build from source
- Check package maintainer's repo for issues

**For nixpkgs-xr and nixpkgs-wayland:**
- Binary cache should be used automatically
- If building from source, check Cachix status

### Evaluation Errors

```bash
# Check flake evaluation
nix flake check --no-build

# Test specific package
nix build .#nixosConfigurations.jupiter.config.environment.systemPackages --dry-run
```

---

## References

- **nixpkgs-xr:** https://github.com/nix-community/nixpkgs-xr
- **NUR:** https://github.com/nix-community/NUR
- **nixpkgs-wayland:** https://github.com/nix-community/nixpkgs-wayland
- **NUR Search:** https://nur.nix-community.org/
- **Matrix Chat (nixpkgs-xr):** [#nixpkgs-xr:matrix.org](https://matrix.to/#/#nixpkgs-xr:matrix.org)
- **Matrix Chat (nixpkgs-wayland):** [#nixpkgs-wayland:matrix.org](https://matrix.to/#/#nixpkgs-wayland:matrix.org)
