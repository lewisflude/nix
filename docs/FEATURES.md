# Feature Module System Guide

This document explains the feature-based configuration system used in this Nix configuration. Features provide a declarative, composable way to enable optional functionality across the system.

## Overview

The feature system allows you to enable/disable groups of related functionality through a unified interface in your host configuration. Features abstract away the complexity of configuring individual services, packages, and system settings.

### Key Concepts

- **Features**: High-level functionality groups (e.g., `gaming`, `development`, `virtualisation`)
- **Feature Options**: Fine-grained control within features (e.g., `gaming.steam`, `development.rust`)
- **Host Configuration**: Features are configured in `hosts/<hostname>/default.nix` via `host.features.*`
- **Feature Modules**: Implementation modules in `modules/nixos/features/` that translate feature flags into actual configuration

## Feature System Architecture

```
Host Configuration (hosts/jupiter/default.nix)
    ↓
    host.features.gaming.enable = true
    ↓
Feature Module (modules/nixos/features/gaming.nix)
    ↓
    Translates to: programs.steam.enable, services.sunshine.enable, etc.
    ↓
NixOS Configuration
```

## Security and Networking Patterns

This configuration follows modern NixOS security and networking best practices:

### Firewall Management

**Separation of Concerns**: Service modules declare their own firewall ports instead of centralized configuration.

```nix
# Service modules declare their own ports
networking.firewall.allowedTCPPorts = [ 8080 ]; # WebUI
networking.firewall.allowedTCPPorts = [ 6881 ]; # Torrenting
```

**Core Networking**: Only essential system ports are managed centrally:

- SSH (22) - System access
- NTP (123) - Time synchronization

### Secrets Management

**SOPS Integration**: Sensitive credentials are encrypted using SOPS:

```nix
# Service configuration
qbittorrent = {
  webUI = {
    useSops = true; # Enable SOPS for credentials
  };
};

# Secrets stored encrypted in secrets/secrets.yaml
qbittorrent:
  webui:
    username: ENC[...]
    password: ENC[...]
```

**Migration Path**: Services support both plain credentials and SOPS secrets during transition.

### VPN Routing

**Declarative Routing**: WireGuard VPN routing uses NixOS abstractions:

```nix
# Instead of manual ip rule commands
networking.routingPolicyRules = [
  {
    from = userId;
    table = routeTable;
    priority = 30001;
  }
];
```

## Available Features

### Development (`host.features.development`)

Provides development tools and language environments.

**Options**:

- `enable`: Enable development tools
- `rust`: Rust toolchain and tools
- `python`: Python development environment
- `go`: Go development environment
- `node`: Node.js/TypeScript development
- `lua`: Lua development environment
- `docker`: Docker and containerization tools
- `java`: Java development environment

**Example**:

```nix
host.features.development = {
  enable = true;
  rust = true;
  python = true;
  docker = true;
};
```

### Gaming (`host.features.gaming`)

Gaming platforms, emulators, and performance optimizations.

**Options**:

- `enable`: Enable gaming features
- `steam`: Steam gaming platform
- `lutris`: Lutris game manager
- `emulators`: Game console emulators
- `performance`: Gaming performance optimizations

**Example**:

```nix
host.features.gaming = {
  enable = true;
  steam = true;
  performance = true;
};
```

**What's Included**:

- **Steam** with Proton-GE for Windows game compatibility
- **GameMode** for automatic performance boosts
- **Ananicy-cpp** with CachyOS rules for process prioritization
- **Gamescope** for HDR, FSR, and frame limiting
- **Multi-core shader pre-compilation** (uses all CPU cores)
- **Enhanced security**: uinput restricted to steam group
- **Performance CPU governor** for minimal latency
- **vm.max_map_count** optimized for modern games

**Documentation**: See `docs/STEAM_GAMING_GUIDE.md` for comprehensive usage guide including:
- Launch options and examples
- Steam Input configuration
- Proton troubleshooting
- Performance optimization tips
- VR gaming setup

### Virtualisation (`host.features.virtualisation`)

Virtual machines and container platforms.

**Options**:

- `enable`: Enable virtualisation features
- `docker`: Docker containers
- `podman`: Podman containers
- `qemu`: QEMU virtual machines
- `virtualbox`: VirtualBox VMs

**Example**:

```nix
host.features.virtualisation = {
  enable = true;
  docker = true;
  qemu = true;
};
```

### Desktop (`host.features.desktop`)

Desktop environment and window manager configuration.

**Options**:

- `enable`: Enable desktop environment
- `niri`: Niri Wayland compositor
- `hyprland`: Hyprland Wayland compositor
- `theming`: System-wide theming
- `utilities`: Desktop utilities

**Example**:

```nix
host.features.desktop = {
  enable = true;
  niri = true;
  theming = true;
};
```

### Media Management (`host.features.mediaManagement`)

Media server and automation services (Plex, Jellyfin, *arr services, etc.).

**Options**:

- `enable`: Enable media management services
- `dataPath`: Path to media storage (default: `/mnt/storage`)
- `timezone`: Timezone for services (default: `Europe/London`)
- Individual service enables: `prowlarr`, `radarr`, `sonarr`, `lidarr`, `readarr`, `sabnzbd`, `qbittorrent`, `jellyfin`, `jellyseerr`, `flaresolverr`, `unpackerr`, `navidrome`

**Example**:

```nix
host.features.mediaManagement = {
  enable = true;
  dataPath = "/mnt/storage";
  qbittorrent = {
    enable = true;
    vpn.enable = true;
  };
};
```

### AI Tools (`host.features.aiTools`)

AI and LLM services (Ollama, Open WebUI, etc.).

**Options**:

- `enable`: Enable AI tools
- `ollama.enable`: Ollama LLM backend
- `ollama.acceleration`: GPU acceleration (`rocm`, `cuda`, or `null`)
- `ollama.models`: List of models to pre-download
- `openWebui.enable`: Open WebUI interface
- `openWebui.port`: Port for Open WebUI (default: 7000)

**Example**:

```nix
host.features.aiTools = {
  enable = true;
  ollama = {
    enable = true;
    acceleration = "cuda";
    models = [ "llama2" "mistral" ];
  };
  openWebui = {
    enable = true;
    port = 7000;
  };
};
```

### Security (`host.features.security`)

Security and privacy tools.

**Options**:

- `enable`: Enable security features
- `yubikey`: YubiKey hardware support
- `gpg`: GPG/PGP encryption
- `firewall`: Advanced firewall configuration

**Example**:

```nix
host.features.security = {
  enable = true;
  yubikey = true;
  gpg = true;
};
```

### Audio (`host.features.audio`)

Audio production and music tools.

**Options**:

- `enable`: Enable audio features
- `production`: DAW and audio tools
- `realtime`: Real-time audio optimizations
- `streaming`: Audio streaming
- `audioNix.enable`: Enable audio.nix flake packages
- `audioNix.bitwig`: Install Bitwig Studio
- `audioNix.plugins`: Install audio plugins

**Example**:

```nix
host.features.audio = {
  enable = true;
  production = true;
  realtime = true;
  audioNix = {
    enable = true;
    bitwig = true;
  };
};
```

### Home Server (`host.features.homeServer`)

Home server and self-hosting services.

**Options**:

- `enable`: Enable home server features
- `homeAssistant`: Home Assistant smart home
- `mediaServer`: Plex/Jellyfin media server
- `fileSharing`: Samba/NFS file sharing
- `backups`: Automated backup systems

**Example**:

```nix
host.features.homeServer = {
  enable = true;
  homeAssistant = true;
  mediaServer = true;
};
```

### Restic (`host.features.restic`)

Restic backup integration with systemd timers.

**Options**:

- `enable`: Enable Restic backup
- `backups`: Per-backup job configuration
- `restServer.enable`: Restic REST server
- `restServer.port`: Port for REST server (default: 8000)

**Example**:

```nix
host.features.restic = {
  enable = true;
  backups = {
    home = {
      enable = true;
      path = "/home";
      repository = "s3:s3.amazonaws.com/my-bucket";
      passwordFile = "/etc/secrets/restic-password";
      timer = "daily";
    };
  };
};
```

## Home Manager User Configurations

While system features are configured at the NixOS level, user-level applications and settings are managed through Home Manager in `home/nixos/` and `home/common/`.

### Browser Configuration (`home/nixos/browser.nix`)

Chrome/Chromium performance optimizations with hardware acceleration and Wayland support.

**Key Features**:

- **Hardware Video Acceleration**: GPU-accelerated video decode/encode via VA-API
- **NVIDIA Support**: RTX 4090-optimized with `VaapiOnNvidiaGPUs` feature
- **Wayland Native**: Auto-detection with fallback to X11
- **High Refresh Rate**: Proper support for gaming displays (144Hz+)
- **Performance**: Parallel downloads, tmpfs cache, GPU rasterization
- **Password Store**: Consistent GNOME Keyring integration

**Configuration Location**: `home/nixos/browser.nix`

**Flags File**: `~/.config/chrome-flags.conf`

**Example Usage**:

```nix
# Automatically applied via home/nixos/browser.nix
# Flags are written to ~/.config/chrome-flags.conf
# Chrome reads these on startup
```

**Verification**:

```bash
# Check active flags
chrome://version/

# Check GPU acceleration
chrome://gpu/

# Test video acceleration
nvidia-smi dmon -s u  # While playing 1080p video
```

**Documentation**: See `docs/CHROME_OPTIMIZATION_GUIDE.md` for:
- Detailed flag explanations
- Testing procedures
- Troubleshooting guide
- NVIDIA-specific configuration

**Benefits for Gaming**:
- Reduced CPU usage during video playback (frees CPU for games)
- Faster downloads for game content
- Better multi-monitor support with mixed refresh rates
- Memory-efficient tmpfs caching

### MIME Type Associations

Default applications for file types are configured in `home/nixos/browser.nix`:

- Web content: Google Chrome
- Videos: MPV
- Images: swayimg
- PDFs: Chrome with fallback to file-roller
- Terminal: Ghostty
- Editor: Helix with Cursor as alternative

**Configuration**: `xdg.mimeApps` in `home/nixos/browser.nix`

## Creating a New Feature Module

### Step 1: Define Feature Options

Add feature options to `modules/shared/host-options.nix`:

```nix
host.features.myFeature = {
  enable = mkEnableOption "my feature description";

  option1 = mkOption {
    type = types.bool;
    default = true;
    description = "First option";
  };

  option2 = mkOption {
    type = types.str;
    default = "default-value";
    description = "Second option";
  };
};
```

### Step 2: Create Feature Module

Create `modules/nixos/features/my-feature.nix`:

```nix
# My feature module for NixOS
# Controlled by host.features.myFeature.*
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.host.features.myFeature;
in {
  config = mkIf cfg.enable {
    # Assertions to validate configuration
    assertions = [
      {
        assertion = cfg.option1 -> (config.host.features.requiredFeature.enable or false);
        message = "myFeature.option1 requires requiredFeature to be enabled";
      }
    ];

    # Platform-specific package installation
    environment.systemPackages = with pkgs;
      optionals pkgs.stdenv.isLinux [
        # Linux-specific packages
        linux-package
      ]
      ++ optionals pkgs.stdenv.isDarwin [
        # macOS-specific packages
        darwin-package
      ]
      ++ optionals cfg.option1 [
        # Conditionally installed packages
        optional-package
      ];

    # System services (NixOS/Linux only)
    systemd.services = mkIf pkgs.stdenv.isLinux {
      my-service = {
        description = "My service description";
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.my-service}/bin/my-service";
          Restart = "on-failure";
        };
      };
    };

    # User groups
    users.users.${config.host.username}.extraGroups =
      optional cfg.enable "my-group";

    # Home Manager integration
    home-manager.users.${config.host.username} = {
      # User-level configuration
      programs.my-program = {
        enable = true;
        # Additional config...
      };

      # User packages (installed in user profile)
      home.packages = with pkgs; [
        # User-specific tools
      ];
    };

    # Additional system configuration
    # networking.firewall.allowedTCPPorts = [ 8080 ];
    # environment.sessionVariables.MY_VAR = "value";
  };
}
```

### Step 3: Import Feature Module

Add the feature module to `modules/nixos/default.nix`:

```nix
imports = [
  # ... other imports
  ./features/my-feature.nix
];
```

### Step 4: Use in Host Configuration

Enable the feature in `hosts/<hostname>/default.nix`:

```nix
host.features.myFeature = {
  enable = true;
  option1 = true;
  option2 = "custom-value";
};
```

## Feature Module Best Practices

### 1. Use `mkIf` for Conditional Configuration

Always wrap feature configuration in `mkIf cfg.enable`:

```nix
config = mkIf cfg.enable {
  # Feature configuration here
};
```

### 2. Use `optionals` for Conditional Packages

For conditional package installation:

```nix
environment.systemPackages = with pkgs;
  optionals cfg.steam [
    steam
    steamcmd
  ];
```

### 3. Add Validation Assertions

Validate dependencies and configuration:

```nix
assertions = [
  {
    assertion = cfg.docker -> (config.host.features.virtualisation.enable or false);
    message = "docker requires virtualisation feature to be enabled";
  }
];
```

### 4. Platform-Specific Configuration

Use platform detection for platform-specific config:

```nix
systemd.services = mkIf pkgs.stdenv.isLinux {
  # Linux-only services
};
```

### 5. Document Feature Options

Add clear descriptions to all options in `host-options.nix`:

```nix
myOption = mkOption {
  type = types.bool;
  default = false;
  description = "Clear description of what this option does";
  example = true;
};
```

### 6. Bridge Modules

For complex features that map to service modules, use bridge modules:

```nix
# modules/nixos/features/media-management.nix
config = mkIf (cfg.enable or false) {
  host.services.mediaManagement = {
    enable = true;
    # Map feature options to service options
  };
};
```

## When to Use Features vs Direct Configuration

### Use Features When

✅ Grouping related functionality (gaming, development, etc.)
✅ Functionality is optional and can be enabled/disabled
✅ Multiple packages/services need to be configured together
✅ Configuration should be consistent across hosts

### Use Direct Configuration When

❌ Single package with no related dependencies
❌ Host-specific configuration that doesn't fit a feature pattern
❌ One-off service configuration
❌ Experimental configuration that may change frequently

## Migrating Existing Configuration to Features

### Example: Converting Docker Configuration

**Before** (direct configuration):

```nix
# In hosts/jupiter/configuration.nix
virtualisation.docker.enable = true;
environment.systemPackages = [ pkgs.docker-compose ];
users.users.lewis.extraGroups = [ "docker" ];
```

**After** (feature-based):

```nix
# In hosts/jupiter/default.nix
host.features.virtualisation = {
  enable = true;
  docker = true;
};

# Feature module handles all the configuration
```

### Migration Steps

1. Identify related configuration items
2. Create feature options in `host-options.nix`
3. Create feature module in `modules/nixos/features/`
4. Move configuration logic to feature module
5. Update host configuration to use feature flags
6. Test that feature works correctly
7. Remove old direct configuration

## Feature Dependencies

Features can depend on other features. Handle dependencies via assertions:

```nix
assertions = [
  {
    assertion = cfg.myFeature -> (config.host.features.requiredFeature.enable or false);
    message = "myFeature requires requiredFeature to be enabled";
  }
];
```

## Testing Features

Test features in isolation:

```nix
# Test that feature evaluates
nix eval .#nixosConfigurations.jupiter.config.host.features.gaming.enable

# Test feature with different options
nix eval --expr '
  let
    config = (import ./hosts/jupiter/configuration.nix).config;
  in
    config.host.features.gaming.steam
'
```

## Troubleshooting

### Feature Not Applying

1. Check feature is enabled in host config: `host.features.myFeature.enable = true`
2. Verify feature module is imported in `modules/nixos/default.nix`
3. Check for evaluation errors: `nix flake check`

### Feature Options Not Available

1. Ensure options are defined in `modules/shared/host-options.nix`
2. Verify option path matches feature module access (`cfg.optionName`)

### Feature Conflicts

1. Check assertions in feature modules
2. Verify feature dependencies are enabled
3. Review feature module imports for conflicts

## Examples

See the following feature modules for reference implementations:

- **Simple Feature**: `modules/nixos/features/security.nix` - Minimal feature with few options
- **Complex Feature**: `modules/nixos/features/gaming.nix` - Multiple services and packages
- **Bridge Feature**: `modules/nixos/features/media-management.nix` - Maps to service modules
- **Service Feature**: `modules/nixos/features/restic.nix` - Systemd timer-based service

## Further Reading

- [Module Templates](../templates/feature-module.nix) - Template for new features
- [Host Options](../modules/shared/host-options.nix) - All available feature options
- [Development Guide](./DX_GUIDE.md) - General development practices
