# Using nix-update

`nix-update` is the community standard for updating package versions and hashes in Nix.

**We use this instead of our old `update-git-hash` script.** See `../WHY_NIX_UPDATE.md` for why.

## Quick Start

```bash
# Update a package to latest version
nix-update package-name --flake

# Update and commit
nix-update package-name --flake --commit

# Update to specific version
nix-update package-name --version=1.2.3 --flake
```

## Common Use Cases

### Update GitHub Package
```bash
# Our old way: update-git-hash romkatv zsh-defer
# New way:
nix-update zsh-defer --flake --commit
```

### Update to Latest Branch
```bash
nix-update package-name --version=branch --flake
nix-update package-name --version=branch=develop --flake
```

### Update and Test
```bash
nix-update package-name --flake --build
nix-update package-name --flake --test
```

## Supported Sources

- GitHub, GitLab, Codeberg, Sourcehut, BitBucket, Gitea
- PyPI, crates.io, RubyGems.org
- And more!

## Supported Hash Types

- `sha256`, `hash` - Regular source hashes
- `vendorHash` - Go modules
- `cargoHash`, `cargoSha256` - Rust packages
- `npmDepsHash` - Node packages
- `mvnHash` - Maven packages
- And more!

## Full Documentation

See: https://github.com/Mic92/nix-update

## Installation

Already in nixpkgs:
```bash
# Run without installing
nix-shell -p nix-update

# Or add to your packages
home.packages = [ pkgs.nix-update ];
```
