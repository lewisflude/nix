# Technical Context - Memory Bank

## Technology Stack

### Core Technologies

**Nix Ecosystem:**
- **Nix** (2.x with flakes) - Functional package manager and build system
- **nixpkgs** - Tracking `unstable` channel for latest packages
- **NixOS** - Linux distribution (various hosts)
- **nix-darwin** - macOS configuration management
- **Home Manager** - User environment management (cross-platform)

**Development:**
- **Rust** - POG scripts implementation language
- **Bash** - Shell scripts and automation
- **Nix Language** - Configuration language

### Module System Architecture

#### Separation: System vs User Configuration

**System-Level** (`modules/nixos/` or `modules/darwin/`):
```nix
# When configuration requires:
- System services (systemd, launchd)
- Kernel modules, drivers
- Hardware configuration
- Root-level daemons
- Container runtimes (Podman, Docker daemons)
- Graphics drivers (Mesa, Vulkan loaders)
- Network configuration
- Boot loaders
```

**User-Level** (`home/common/apps/` or `home/{nixos,darwin}/`):
```nix
# When configuration is:
- User applications, CLI tools
- User systemd services (systemd --user)
- Dotfiles (.bashrc, .zshrc, .config/*)
- Development tools (LSPs, formatters, linters)
- Desktop applications
- Tray applets
- Shell configuration
- Editor configs (Neovim, Helix, etc.)
```

#### Module Pattern

Standard module structure:
```nix
{ config, lib, pkgs, ... }:

let
  cfg = config.features.myFeature;
  constants = import ../lib/constants.nix;
in
{
  options.features.myFeature = {
    enable = lib.mkEnableOption "my feature";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.myPackage;
      description = "Package to use";
    };
  };

  config = lib.mkIf cfg.enable {
    # Configuration here
  };
}
```

### Code Style Standards

#### Rule #1: No `with pkgs;`

```nix
# ❌ ANTIPATTERN - Never use this
home.packages = with pkgs; [ curl wget tree ];

# ✅ CORRECT - Always use explicit references
home.packages = [ pkgs.curl pkgs.wget pkgs.tree ];
```

**Rationale**: Explicit references improve clarity, make refactoring safer, and avoid namespace pollution.

#### Rule #2: Use Constants

```nix
# ❌ WRONG - Hardcoded magic values
services.jellyfin.port = 8096;
time.timeZone = "Europe/London";

# ✅ CORRECT - Use constants or per-host config
let
  constants = import ../lib/constants.nix;
in
{
  services.jellyfin.port = constants.ports.services.jellyfin;
  # timeZone configured in hosts/<hostname>/
}
```

**Rationale**: Constants file provides single source of truth, makes updates easier, prevents conflicts.

#### Rule #3: Validators for Assertions

```nix
let
  validators = import ../lib/validators.nix { inherit lib; };
in
{
  assertions = [
    (validators.assertValidPort cfg.port "service-name")
  ];
}
```

### Project Structure Details

#### Hosts (`hosts/`)

Each host directory contains:
```
hosts/<hostname>/
├── default.nix      # Host configuration (imports, features, etc.)
├── hardware.nix     # Hardware scan results (NixOS only)
└── README.md        # Host-specific notes (optional)
```

Host configuration example:
```nix
{ config, pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ../../modules/nixos/features/gaming.nix
  ];

  features.gaming.enable = true;
  features.audio.enable = true;

  # Host-specific overrides
  networking.hostName = "myhost";
  time.timeZone = "America/New_York";
}
```

#### Features (`modules/shared/features/` and `modules/nixos/features/`)

Feature modules are toggleable configuration bundles:
```nix
# Enable gaming features
features.gaming = {
  enable = true;
  steam.enable = true;
  emulation.enable = false;
};

# Enable audio production
features.audio = {
  enable = true;
  jackSupport = true;
  proAudio = true;
};
```

See `docs/FEATURES.md` for complete feature reference.

#### Home Manager (`home/`)

User configuration structure:
```
home/
├── common/           # Cross-platform config
│   ├── apps/         # Application configs
│   │   ├── git.nix
│   │   ├── zsh.nix
│   │   ├── helix.nix
│   │   └── ...
│   └── default.nix   # Main home config
├── nixos/            # Linux-specific
│   ├── apps/
│   └── default.nix
└── darwin/           # macOS-specific
    ├── apps/
    └── default.nix
```

### Build and Deployment

#### Building Configurations

**NixOS:**
```bash
# Build and switch (user must run this)
nh os switch

# Alternative
sudo nixos-rebuild switch --flake .#<hostname>

# Test without activation
sudo nixos-rebuild test --flake .#<hostname>
```

**nix-darwin:**
```bash
# Build and switch (user must run this)
darwin-rebuild switch --flake .#<hostname>
```

**Home Manager only:**
```bash
home-manager switch --flake .#<username>@<hostname>
```

#### Validation

```bash
# Check flake syntax and outputs
nix flake check

# Format all Nix files
nix fmt
# or
treefmt

# Lint check
./scripts/strict-lint-check.sh
```

### Dependencies and Updates

#### Flake Inputs

Managed in `flake.nix`:
```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  home-manager.url = "github:nix-community/home-manager";
  darwin.url = "github:lnl7/nix-darwin";
  # ... more inputs
};
```

#### Updating

```bash
# Update all inputs (POG script)
nix run .#update-all

# Or manually
nix flake update

# Update specific input
nix flake update nixpkgs
```

### Automation and Tooling

#### POG Scripts (`pkgs/pog-scripts/`)

Interactive Rust-based CLI tools:

**`new-module`**:
- Scaffolds new Nix modules
- Prompts for type (system/home), platform, name
- Creates file with correct structure
- Updates imports automatically

**`update-all`**:
- Updates flake inputs
- Updates ZSH plugins
- Commits changes with proper message

**`visualize-modules`**:
- Generates GraphViz dependency graphs
- Shows module relationships
- Helps understand architecture

**`setup-cachix`**:
- Configures Cachix binary cache
- Speeds up builds significantly

#### Shell Scripts (`scripts/`)

Organized by purpose:

**Diagnostics:**
- `diagnose-qbittorrent-seeding.sh` - Seeding issues
- `diagnose-ssh-slowness.sh` - SSH performance
- `test-ssh-performance.sh` - Benchmarking

**Monitoring:**
- `monitor-protonvpn-portforward.sh` - VPN port status
- `monitor-hdd-storage.sh` - Storage health

**Validation:**
- `validate-config.sh` - Config validation
- `strict-lint-check.sh` - Code quality
- `verify-no-removed-features.sh` - Feature integrity

**Automation:**
- `protonvpn-natpmp-portforward.sh` - Port forwarding
- `auto-format-nix.sh` - Format on save
- `load-context.sh` - Session context

### Git Workflow

#### Conventional Commits

Format: `<type>(<scope>): <description>`

**Types:**
- `feat:` - New features
- `fix:` - Bug fixes
- `refactor:` - Code restructuring
- `docs:` - Documentation
- `test:` - Tests
- `chore:` - Build/tooling

**Examples:**
```
feat(audio): add PipeWire low-latency configuration
fix(modules): correct module import paths in gaming feature
refactor(features): consolidate media server modules
docs(qbittorrent): update VPN setup instructions
```

See `docs/DX_GUIDE.md` for detailed guidelines.

#### Hooks and Automation

**Claude Code hooks** (`.claude/settings.json`):
- `SessionStart` - Load git context
- `PreToolUse` - Block dangerous commands
- `PostToolUse` - Auto-format and lint

**Pre-commit checks** (if configured):
- Format validation
- Lint checks
- Flake check

### Common Patterns

#### Conditional Configuration

```nix
# Enable feature only on NixOS
config = lib.mkIf pkgs.stdenv.isLinux {
  # Linux-specific config
};

# Enable feature only on macOS
config = lib.mkIf pkgs.stdenv.isDarwin {
  # macOS-specific config
};

# Enable based on feature flag
config = lib.mkIf cfg.enable {
  # Conditional config
};
```

#### Package Overlays

```nix
# Modify or add packages
nixpkgs.overlays = [
  (final: prev: {
    myPackage = prev.myPackage.overrideAttrs (old: {
      # Custom attributes
    });
  })
];
```

#### Sharing Configuration

```nix
# In modules/shared/features/common.nix
{ lib, ... }:
{
  # Shared options/config used by both NixOS and darwin
}
```

### Performance Considerations

**Flake Evaluation:**
- Keep imports minimal
- Use `inherit` for frequently accessed values
- Avoid expensive computations in module options

**Build Times:**
- Use Cachix for binary caching
- Minimize rebuilds with proper module organization
- Cache ZSH plugins and other downloads

**System Resources:**
- Nix daemon can use significant RAM during builds
- `/nix/store` grows over time (garbage collect with `nix-collect-garbage`)

### Security Patterns

**Secrets Management:**
- Never commit secrets to git
- Use `age` or `sops-nix` for encrypted secrets
- Keep `.env` files out of version control

**Permission Boundaries:**
- System services run as dedicated users
- User services run under user context
- Minimize `sudo` requirements

### Debugging

**Common Issues:**

1. **Syntax Errors**: Run `nix flake check`
2. **Import Errors**: Verify file paths are correct
3. **Build Failures**: Check nixpkgs version compatibility
4. **Option Conflicts**: Review `config` values for duplicates

**Useful Commands:**
```bash
# Show flake info
nix flake show

# Evaluate specific attribute
nix eval .#nixosConfigurations.<hostname>.config.system.build.toplevel

# Trace evaluation
nix-instantiate --eval --strict --trace-verbose

# Check specific module
nix-instantiate --parse module.nix
```

### Testing Strategy

**Pre-deployment:**
1. `nix flake check` - Syntax and structure
2. `nix fmt` - Format consistency
3. Build in VM or test system
4. Review `git diff` carefully

**Post-deployment:**
1. Verify services started: `systemctl status <service>`
2. Check logs: `journalctl -u <service>`
3. Test functionality manually

### Documentation Reference

**Critical Docs:**
- `docs/reference/architecture.md` - Architecture deep dive
- `docs/FEATURES.md` - Feature system guide
- `docs/DX_GUIDE.md` - Development workflow
- `docs/reference/REFACTORING_EXAMPLES.md` - Anti-patterns
- `CLAUDE.md` - AI assistant rules
- `CONVENTIONS.md` - Coding standards

**Specialized Guides:**
- `docs/QBITTORRENT_GUIDE.md` - Media server setup
- `docs/PROTONVPN_PORT_FORWARDING_SETUP.md` - VPN config
- `docs/PERFORMANCE_TUNING.md` - Optimization
- `docs/LINTING_CONFIGURATION.md` - Code quality

### External Resources

- **NixOS Manual**: https://nixos.org/manual/nixos/stable/
- **Nix Pills**: https://nixos.org/guides/nix-pills/
- **Home Manager Manual**: https://nix-community.github.io/home-manager/
- **nix-darwin Manual**: https://daiderd.com/nix-darwin/manual/
