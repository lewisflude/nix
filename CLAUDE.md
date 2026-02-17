# AI Assistant Guidelines

This document provides guidelines for AI assistants working with this Nix
configuration repository.

## System Rebuilds

**CRITICAL**: Never rebuild NixOS or nix-darwin systems directly. Always ask the
user to build instead, as you do not have permissions to run commands like:

- `nh os switch`
- `sudo nixos-rebuild switch`
- `sudo darwin-rebuild switch`

Instead, suggest commands for the user to run manually.

## Creating Documentation and Scripts

**CRITICAL**: Do NOT create new documentation files or shell scripts without
explicit user permission. The repository was intentionally cleaned of excessive
documentation and scripts.

**Guidelines:**

- **Never proactively create** `.md` files or `.sh` files in `scripts/`
- **Ask permission first** if the user's request implies creating new docs or
  scripts
- **Use existing documentation** - update existing files rather than creating
  new ones
- **Prefer inline documentation** in code comments over separate doc files
- **Use POG scripts** (`pkgs/pog-scripts/`) for new CLI tools instead of shell
  scripts

**Exceptions** (still require user confirmation):

- User explicitly says "create a script to..." or "write documentation for..."
- Task absolutely requires a new file and no existing file can be updated

## Dendritic Pattern Architecture

This repository follows the **dendritic pattern** where every `.nix` file
(except `flake.nix`) is a flake-parts module. See `DENDRITIC_PATTERN.md` for the
complete pattern documentation.

### Key Concepts

1. **Every file is a top-level module** - All `.nix` files under `modules/` are
   flake-parts modules
2. **Two levels of configuration**:
   - **Top-level** (flake-parts): Where you define `flake.modules.*` and access
     `config.*`
   - **Platform-level** (NixOS/Darwin/home-manager): The actual system
     configurations stored as values
3. **Value sharing via top-level config** - No `specialArgs`, access values via
   `config.*`
4. **Hosts compose features** - All imports happen at host level, not in
   infrastructure

### Repository Structure

```
.
├── flake.nix                    # Entry point: uses import-tree ./modules
└── modules/
    ├── infrastructure/          # Declares options + transforms to flake outputs
    │   ├── flake-parts.nix      # Enables flake.modules.* option
    │   ├── nixos.nix            # configurations.nixos -> nixosConfigurations
    │   ├── darwin.nix           # configurations.darwin -> darwinConfigurations
    │   └── home-manager.nix     # Home-manager base configuration
    ├── hosts/                   # Host definitions (compose features)
    │   ├── jupiter/
    │   │   └── definition.nix   # NixOS desktop workstation
    │   └── mercury/
    │       └── definition.nix   # nix-darwin MacBook
    ├── core/                    # Core system modules
    ├── desktop/                 # Desktop environment modules
    ├── hardware/                # Hardware support modules
    ├── constants.nix            # Centralized constants (config.constants)
    ├── meta.nix                 # username, useremail options
    └── <feature>.nix            # Feature modules (flake.modules.*)
```

## Available Tools

### POG Apps (Interactive CLI Tools)

These are modern CLI tools built with pog library:

- `nix run .#new-module` - Create new modules interactively
- `nix run .#update-all` - Update flake inputs and ZSH plugins
- `nix run .#visualize-modules` - Generate module dependency graphs
- `nix run .#setup-cachix` - Configure Cachix binary cache

### Shell Scripts

Located in `scripts/`:

**qBittorrent & VPN:**

- `scripts/diagnose-qbittorrent-seeding.sh` - Comprehensive qBittorrent seeding
  diagnostics
- `scripts/test-qbittorrent-seeding-health.sh` - Full health check with API
  integration
- `scripts/test-qbittorrent-connectivity.sh` - Network connectivity verification
- `scripts/protonvpn-natpmp-portforward.sh` - Automated NAT-PMP port forwarding
- `scripts/monitor-protonvpn-portforward.sh` - Monitor VPN and port forwarding
  status
- `scripts/verify-qbittorrent-vpn.sh` - Complete verification following setup
  guide
- `scripts/test-vpn-port-forwarding.sh` - Quick port forwarding status check
- `scripts/monitor-hdd-storage.sh` - Monitor HDD storage usage and health

**SSH Performance:**

- `scripts/test-ssh-performance.sh` - Comprehensive SSH performance benchmarking
- `scripts/diagnose-ssh-slowness.sh` - SSH connection troubleshooting

**Network Testing:**

- `scripts/test-sped.sh` - Simple speed test wrapper

See `scripts/README.md` for detailed documentation of each script.

## Best Practices

1. **Always check existing patterns** before suggesting new code
2. **Use templates** when creating modules: `nix run .#new-module`
3. **Follow conventional commits** for git messages
4. **Format code** using `nix fmt` or `treefmt`
5. **Check for existing modules** before creating new ones
6. **Read `DENDRITIC_PATTERN.md`** for architecture guidance

## Common Tasks

### Adding a Package

1. Check if a relevant feature module exists in `modules/`
2. Add to appropriate `flake.modules.nixos.*` or `flake.modules.homeManager.*`
3. Import the module in the host definition
   (`modules/hosts/<hostname>/definition.nix`)

### Creating a Module

Follow the dendritic pattern:

```nix
# modules/my-feature.nix
{ config, ... }:
let
  constants = config.constants;  # Access top-level constants
in
{
  # NixOS system configuration
  flake.modules.nixos.myFeature = { pkgs, lib, ... }: {
    # Platform-level NixOS config here
    services.myService.enable = true;
  };

  # Home-manager user configuration (optional)
  flake.modules.homeManager.myFeature = { pkgs, ... }: {
    # Platform-level home-manager config here
    home.packages = [ pkgs.myApp ];
  };
}
```

### Updating Dependencies

- Use `nix run .#update-all` to update everything
- Or manually: `nix flake update`

## Module Guidelines (Dendritic Pattern)

### Understanding the Two Scopes

The canonical pattern uses a named parameter (like `nixosArgs`) to avoid
shadowing:

```nix
# modules/shell.nix (canonical pattern)
{ config, lib, ... }:         # ← Top-level (flake-parts) config
{
  flake.modules.nixos.shell = nixosArgs: {
    #                         ^^^^^^^^^
    #                         Named parameter for platform-level args
    programs.fish.enable = true;
    users.users.${config.username}.shell = nixosArgs.config.programs.fish.package;
    #              ^^^^^^^^^^^^^^              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    #              Top-level config            Platform config (NixOS)
    #              (from outer scope)          (via named parameter)
  };
}
```

**Key insight**: Use `nixosArgs` (or similar) as the parameter name to access
platform config while keeping `config` from outer scope available.

**Alternative** - omit platform config if not needed:

```nix
{ config, ... }:              # ← Top-level config (outer scope)
{
  flake.modules.nixos.shell = { pkgs, ... }: {
    users.users.${config.username}.shell = pkgs.fish;  # ✅ Uses outer config
  };
}
```

**Anti-pattern** - shadowing config:

```nix
{ config, ... }:
{
  flake.modules.nixos.shell = { config, pkgs, ... }: {
    #                           ^^^^^^ SHADOWS outer config!
    users.users.${config.username}.shell = pkgs.fish;  # ❌ config is NixOS here
  };
}
```

### System vs Home-Manager Configuration

**System-level** (`flake.modules.nixos.*` or `flake.modules.darwin.*`):

- System services (systemd, launchd)
- Kernel modules and drivers
- Hardware configuration
- System daemons (running as root)
- Container runtimes
- Graphics drivers
- Network configuration (system-wide)
- Boot configuration

**Home-manager** (`flake.modules.homeManager.*`):

- User applications and CLI tools
- User services (systemd --user)
- Dotfiles and user configuration
- Development tools (LSPs, formatters, linters)
- Desktop applications
- User tray applets
- Shell configuration
- Editor configurations

### Example: Cross-Platform Feature Module

```nix
# modules/audio.nix - Single file with both NixOS and home-manager config
{ config, ... }:
let
  constants = config.constants;
in
{
  # NixOS system audio
  flake.modules.nixos.audio = { pkgs, lib, ... }: {
    services.pipewire.enable = true;
    security.rtkit.enable = true;
  };

  # Home-manager audio tools
  flake.modules.homeManager.audio = { pkgs, ... }: {
    home.packages = [ pkgs.pwvucontrol pkgs.pavucontrol ];
  };
}
```

### Accessing Constants

Constants are defined as a top-level option in `modules/constants.nix`:

```nix
# ✅ CORRECT - Access via top-level config
{ config, ... }:
let
  constants = config.constants;
in
{
  flake.modules.nixos.jellyfin = { ... }: {
    services.jellyfin.port = constants.ports.services.jellyfin;
  };
}
```

```nix
# ❌ WRONG - Don't import directly
let
  constants = import ../lib/constants.nix;  # Anti-pattern!
in
```

### Common Antipatterns to Avoid

#### ❌ Using `with pkgs;`

```nix
# ❌ WRONG
home.packages = with pkgs; [ curl wget tree ];

# ✅ CORRECT
home.packages = [ pkgs.curl pkgs.wget pkgs.tree ];
```

#### ❌ Using specialArgs

```nix
# ❌ WRONG - Anti-pattern in dendritic
lib.nixosSystem {
  specialArgs = { inherit inputs; };
}

# ✅ CORRECT - Access via top-level config
{ config, inputs, ... }:
{
  flake.modules.nixos.myFeature = { ... }: {
    # inputs available from outer scope
  };
}
```

#### ❌ Importing modules in infrastructure

```nix
# ❌ WRONG - Infrastructure should only transform
config.flake.nixosConfigurations = lib.mapAttrs
  (name: { module }: lib.nixosSystem {
    modules = [
      module
      config.flake.modules.nixos.admin  # NO!
    ];
  })
  config.configurations.nixos;

# ✅ CORRECT - Hosts import features
# modules/hosts/jupiter/definition.nix
configurations.nixos.jupiter.module = {
  imports = [ nixos.admin nixos.shell ];  # YES!
};
```

### Decision Checklist

When adding a package or service:

1. **Does it require root/system privileges?** → `flake.modules.nixos.*`
2. **Does it run as a system service?** → `flake.modules.nixos.*`
3. **Is it hardware configuration?** → `flake.modules.nixos.*`
4. **Is it a user application?** → `flake.modules.homeManager.*`
5. **Does it configure dotfiles?** → `flake.modules.homeManager.*`
6. **Is it a tray applet?** → `flake.modules.homeManager.*`

## MCP (Model Context Protocol) Servers

This configuration includes built-in MCP server support for AI coding tools
(Claude Code, Cursor, etc.) using the home-manager `programs.mcp` option.

### Available MCP Servers

**Enabled by default (no secrets required):**

- **memory** - Knowledge graph-based persistent memory
- **git** - Git repository operations
- **time** - Timezone and datetime utilities
- **sqlite** - SQLite database access at `~/.local/share/mcp/data.db`
- **everything** - MCP reference/test server

**Disabled by default (require secrets or dependencies):**

- **docs** - Documentation indexing and search (requires `OPENAI_API_KEY`)
- **openai** - OpenAI integration with Rust docs support (requires
  `OPENAI_API_KEY`)
- **rustdocs** - Bevy crate documentation (requires `OPENAI_API_KEY`)
- **github** - GitHub API integration (requires `GITHUB_TOKEN`)
- **kagi** - Kagi search and summarization (requires `KAGI_API_KEY` and `uv`)
- **brave** - Brave Search (requires `BRAVE_API_KEY`)
- **filesystem** - File operations (disabled for security)
- **sequentialthinking** - Dynamic problem-solving
- **fetch** - Web content fetching (community alternative)
- **nixos** - NixOS package search (requires `uv`)

### Configuration

MCP servers are configured in feature modules and automatically deployed to
`~/.config/mcp/mcp.json`. AI tools like Claude Code and Cursor can read this
configuration.

### Enabling Servers with Secrets

To enable servers that require API keys:

1. **Add secret to SOPS**: Edit `secrets/secrets.yaml` with your secret
2. **Configure secret**: In the relevant module, add SOPS configuration
3. **Rebuild system**: The secret will be available at
   `/run/secrets-for-users/MY_SECRET`

## Documentation

### Primary Documentation

- **`DENDRITIC_PATTERN.md`** - Complete dendritic pattern documentation
  (canonical source)
- **`CLAUDE.md`** - This file (AI assistant guidelines)
- **`scripts/README.md`** - Shell script documentation

### Reference

- [Dendritic Pattern (canonical)](https://github.com/mightyiam/dendritic)
- [Flake Parts Documentation](https://flake.parts)

## Important Notes

- Never run system rebuild commands
- Always suggest commands for the user to run
- Read `DENDRITIC_PATTERN.md` before making architectural decisions
- Use existing patterns and conventions
- Format code before suggesting changes
- Every `.nix` file is a flake-parts module (dendritic pattern)
