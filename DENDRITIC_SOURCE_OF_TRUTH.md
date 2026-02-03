# Dendritic Pattern - Source of Truth

This document captures the canonical patterns from the dendritic architecture. Use this as the authoritative reference when implementing or refactoring modules.

**Canonical reference**: `/home/lewis/Code/dendritic` (README.md and example/)

## Core Principles

1. **Infrastructure declares options, hosts compose modules**
2. **All imports happen at host level** (external inputs AND feature modules)
3. **No extraSpecialArgs** - use top-level flake-parts options instead
4. **One file = one feature** - one file can define multiple related modules (e.g., `audio.nix` defines audio, noiseCancellation, echoCancellation)
5. **Auto-discovery** - all `.nix` files in `modules/` are automatically imported

## File Structure

```
.
├── flake.nix                              # Entry point - imports all modules via import-tree
└── modules/
    ├── infrastructure/
    │   ├── flake-parts.nix                # Enables flake-parts module system
    │   ├── nixos.nix                      # configurations.nixos option + transformation
    │   ├── darwin.nix                     # configurations.darwin option + transformation
    │   └── home-manager.nix               # homeManagerBase modules (structure only)
    ├── options/
    │   └── host.nix                       # Base modules with host.* options
    ├── hosts/
    │   ├── jupiter/
    │   │   └── definition.nix             # NixOS host - imports ALL modules
    │   └── mercury/
    │       └── definition.nix             # Darwin host - imports ALL modules
    ├── core/                              # Core system modules (boot, networking, security)
    ├── desktop/                           # Desktop environment modules
    ├── hardware/                          # Hardware support modules
    ├── services/                          # Service modules
    ├── per-system/                        # Flake-parts per-system outputs
    ├── outputs/                           # Library and overlay exports
    ├── systems.nix                        # Supported systems
    ├── meta.nix                           # Top-level options (username, useremail)
    ├── constants.nix                      # Top-level constants option
    └── <feature>.nix                      # Feature modules (shell, audio, gaming, etc.)
```

## Key Patterns

### 1. Entry Point (`flake.nix`)

```nix
{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # ... other inputs
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; }
      (inputs.import-tree ./modules);
}
```

### 2. Infrastructure Modules

Infrastructure modules ONLY declare options and transform them to flake outputs.

**NixOS Infrastructure** (`modules/infrastructure/nixos.nix`):
```nix
{ lib, config, inputs, ... }:
{
  options.configurations.nixos = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submodule {
        options.module = lib.mkOption {
          type = lib.types.deferredModule;
        };
      }
    );
    default = { };
  };

  config.flake = {
    nixosConfigurations = lib.flip lib.mapAttrs config.configurations.nixos (
      name: { module }: inputs.nixpkgs.lib.nixosSystem { modules = [ module ]; }
    );

    # Auto-generated checks
    checks =
      config.flake.nixosConfigurations
      |> lib.mapAttrsToList (name: nixos: {
        ${nixos.config.nixpkgs.hostPlatform.system} = {
          "configurations:nixos:${name}" = nixos.config.system.build.toplevel;
        };
      })
      |> lib.mkMerge;
  };
}
```

**Darwin Infrastructure** (`modules/infrastructure/darwin.nix`):
```nix
{ lib, config, inputs, ... }:
{
  options.configurations.darwin = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submodule {
        options.module = lib.mkOption {
          type = lib.types.deferredModule;
        };
      }
    );
    default = { };
  };

  config.flake = {
    darwinConfigurations = lib.flip lib.mapAttrs config.configurations.darwin (
      name: { module }: inputs.darwin.lib.darwinSystem { modules = [ module ]; }
    );

    checks =
      config.flake.darwinConfigurations
      |> lib.mapAttrsToList (name: darwin: {
        ${darwin.config.nixpkgs.hostPlatform.system} = {
          "configurations:darwin:${name}" = darwin.config.system.build.toplevel;
        };
      })
      |> lib.mkMerge;
  };
}
```

### 3. Home-Manager Infrastructure

Provides ONLY the structure, not module imports:

```nix
{ config, ... }:
let
  inherit (config) username useremail constants;
in
{
  flake.modules.nixos.homeManagerBase = { ... }: {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm-backup";

      users.${username} = { osConfig, ... }: {
        home.stateVersion = osConfig.system.stateVersion;
        home.username = username;
        home.homeDirectory = "/home/${username}";
        programs.home-manager.enable = true;
        programs.git.settings.user.email = useremail;
      };
    };
  };

  flake.modules.darwin.homeManagerBase = { ... }: {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm-backup";

      users.${username} = { ... }: {
        home.stateVersion = constants.defaults.stateVersion;
        home.username = username;
        home.homeDirectory = "/Users/${username}";
        programs.home-manager.enable = true;
        programs.git.settings.user.email = useremail;
      };
    };
  };
}
```

### 4. Shared Options (`modules/meta.nix`)

```nix
{ lib, ... }:
{
  options = {
    username = lib.mkOption {
      type = lib.types.singleLineStr;
      readOnly = true;
      default = "lewis";
    };

    useremail = lib.mkOption {
      type = lib.types.singleLineStr;
      readOnly = true;
      default = "lewis@lewisflude.com";
    };
  };
}
```

### 5. Constants (`modules/constants.nix`)

The constants module provides structured configuration data accessible throughout the flake:

```nix
{ lib, ... }:
{
  options.constants = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = {
      # Port assignments
      ports = {
        mcp = {
          memory = 3000;
          git = 3001;
          # ... other MCP server ports
        };
        services = {
          jellyfin = 8096;
          caddy = 443;
          qbittorrent = 8080;
          # ... 30+ service ports
        };
        vr = {
          wivrn = 9757;
          alvr = 9944;
        };
        gaming = {
          hytale = 25565;
        };
      };

      # Timeout configurations
      timeouts = {
        mcp = {
          server = 30000;
          connection = 5000;
        };
        service = {
          vpnConnection = 30;
          healthCheck = 10;
        };
      };

      # Default values
      defaults = {
        timezone = "Europe/London";
        locale = "en_GB.UTF-8";
        stateVersion = "25.05";
        darwinStateVersion = 6;
      };

      # Host configurations
      hosts = {
        jupiter = {
          hostname = "jupiter";
          system = "x86_64-linux";
        };
        mercury = {
          hostname = "mercury";
          system = "aarch64-darwin";
        };
      };

      # Network configurations
      networks = {
        lan = "192.168.1.0/24";
        vpn = "10.2.0.0/16";
        localhost = "127.0.0.1";
        all = "0.0.0.0";
      };

      # Audio configurations
      audio = {
        devices = {
          scarlett = "alsa_card.usb-Focusrite_Scarlett_Solo_USB";
          # ... other devices
        };
        virtualSinks = {
          gaming = "gaming-sink";
          music = "music-sink";
        };
        priorities = {
          realtime = 95;
          normal = 50;
        };
      };

      # Binary cache configurations
      binaryCaches = {
        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
        ];
        trustedPublicKeys = [ /* ... */ ];
      };
    };
  };
}
```

**Usage in modules**:
```nix
{ config, ... }:
let
  constants = config.constants;
in
{
  flake.modules.nixos.myService = { ... }: {
    services.myService = {
      port = constants.ports.services.myService;
      timeout = constants.timeouts.service.healthCheck;
    };
  };
}
```

### 6. Feature Modules

Feature modules define `flake.modules.<platform>.<name>` and can target multiple platforms. A single file can define multiple related modules.

**Simple Feature** (single platform):
```nix
# modules/comfyui.nix
{ config, ... }:
let
  constants = config.constants;
in
{
  flake.modules.nixos.comfyui = { lib, pkgs, ... }: {
    services.comfyui = {
      enable = true;
      port = constants.ports.services.comfyui;
    };
  };
}
```

**Multi-Platform Feature** (multiple platforms):
```nix
# modules/shell.nix
{ config, ... }:
let
  inherit (config) username;
in
{
  # NixOS system-level
  flake.modules.nixos.shell = { pkgs, ... }: {
    programs.zsh.enable = true;
    users.users.${username}.shell = pkgs.zsh;
  };

  # Darwin system-level
  flake.modules.darwin.shell = { pkgs, ... }: {
    programs.zsh.enable = true;
  };

  # Home-manager (works on both)
  flake.modules.homeManager.shell = { lib, pkgs, config, ... }: {
    programs.zsh = {
      enable = true;
      # ... configuration
    };
  };
}
```

**Multiple Related Modules** (single file):
```nix
# modules/audio.nix - defines multiple related modules in one file
{ config, ... }:
{
  flake.modules.nixos.audio = { pkgs, ... }: {
    # Main audio configuration
    sound.enable = true;
    services.pipewire.enable = true;
  };

  flake.modules.homeManager.audio = { pkgs, ... }: {
    # User audio packages
    home.packages = with pkgs; [ pavucontrol ];
  };

  flake.modules.homeManager.noiseCancellation = { pkgs, ... }: {
    # Noise cancellation feature
    services.noiseTorch.enable = true;
  };

  flake.modules.homeManager.echoCancellation = { lib, ... }: {
    # Echo cancellation feature
    services.pipewire.pulse.enable = true;
  };
}
```

**Using `osConfig` Parameter** (home-manager accessing system config):
```nix
# modules/gaming.nix
{ config, ... }:
{
  flake.modules.homeManager.gaming = { lib, pkgs, config, osConfig ? {}, ... }: {
    # Can read NixOS/Darwin configuration
    home.packages = lib.optionals osConfig.host.features.gaming.steam.enable [
      pkgs.steam
    ];

    # Can access SOPS secrets from system
    programs.mangohud.settings.api_key =
      lib.mkIf (osConfig ? sops.secrets.GAMING_API_KEY)
        config.sops.secrets.GAMING_API_KEY.path;
  };
}
```

### 7. Host Options (`modules/options/host.nix`)

The host options module defines a comprehensive `host.*` option tree for feature flags and host-specific configuration:

```nix
{ lib, config, ... }:
{
  options.host = lib.mkOption {
    type = lib.types.submoduleWith {
      modules = [{
        options = {
          username = lib.mkOption {
            type = lib.types.str;
            default = config.username;
          };

          hostname = lib.mkOption {
            type = lib.types.str;
          };

          system = lib.mkOption {
            type = lib.types.str;
          };

          hardware = lib.mkOption {
            type = lib.types.submodule {
              options = {
                renderDevice = lib.mkOption {
                  type = lib.types.str;
                  default = "/dev/dri/renderD128";
                };
              };
            };
          };

          features = lib.mkOption {
            type = lib.types.submodule {
              options = {
                desktop = {
                  enable = lib.mkEnableOption "desktop environment";
                  niri = lib.mkEnableOption "Niri compositor";
                  theming = lib.mkEnableOption "desktop theming";
                  utilities = lib.mkEnableOption "desktop utilities";
                  autoLogin = {
                    enable = lib.mkEnableOption "auto login";
                    user = lib.mkOption { type = lib.types.str; };
                  };
                  signalTheme = {
                    enable = lib.mkEnableOption "Signal theme";
                    mode = lib.mkOption {
                      type = lib.types.enum [ "light" "dark" "auto" ];
                      default = "dark";
                    };
                  };
                };

                gaming = {
                  enable = lib.mkEnableOption "gaming support";
                  steam = lib.mkEnableOption "Steam";
                  performance = lib.mkEnableOption "gaming performance optimizations";
                };

                vr = {
                  enable = lib.mkEnableOption "VR support";
                  wivrn = {
                    enable = lib.mkEnableOption "WiVRn";
                    autoStart = lib.mkEnableOption "auto-start WiVRn";
                    defaultRuntime = lib.mkEnableOption "default OpenXR runtime";
                  };
                  steamvr = lib.mkEnableOption "SteamVR";
                  immersed = {
                    enable = lib.mkEnableOption "Immersed VR";
                  };
                  performance = lib.mkEnableOption "VR performance optimizations";
                };

                security = {
                  fail2ban.enable = lib.mkEnableOption "fail2ban";
                  yubikey.enable = lib.mkEnableOption "YubiKey support";
                };

                development = {
                  enable = lib.mkEnableOption "development tools";
                  nix-ld.enable = lib.mkEnableOption "nix-ld for dynamic linking";
                };

                aiTools = {
                  enable = lib.mkEnableOption "AI development tools";
                  claudeCode.enable = lib.mkEnableOption "Claude Code";
                  cursor.enable = lib.mkEnableOption "Cursor";
                  comfyui.enable = lib.mkEnableOption "ComfyUI";
                };

                media = {
                  enable = lib.mkEnableOption "media management";
                  jellyfin.enable = lib.mkEnableOption "Jellyfin";
                  arr.enable = lib.mkEnableOption "arr stack";
                };

                virtualisation = {
                  enable = lib.mkEnableOption "virtualisation support";
                  podman.enable = lib.mkEnableOption "Podman";
                };

                productivity = {
                  enable = lib.mkEnableOption "productivity tools";
                };
              };
            };
          };

          services = {
            caddy = {
              enable = lib.mkEnableOption "Caddy web server";
              email = lib.mkOption { type = lib.types.str; };
            };
          };
        };
      }];
    };
  };

  # Export as flake module for use in host definitions
  config.flake.modules.nixos.base = { ... }: {
    # Makes host.* options available in NixOS config
  };

  config.flake.modules.darwin.base = { ... }: {
    # Makes host.* options available in Darwin config
  };
}
```

### 8. Host Definitions

Hosts import ALL modules - both external inputs and feature modules:

```nix
# modules/hosts/jupiter/definition.nix
{ config, inputs, ... }:
let
  constants = config.constants;
  inherit (config) username useremail;
  inherit (config.flake.modules) nixos homeManager;
in
{
  configurations.nixos.jupiter.module = { pkgs, ... }: {
    imports = [
      # External input modules
      inputs.nixpkgs.nixosModules.notDetected
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops
      # ... other external modules

      # Base modules
      nixos.base
      nixos.homeManagerBase

      # Feature modules
      nixos.boot
      nixos.networking
      nixos.desktop
      nixos.gaming
      # ... other feature modules
    ];

    nixpkgs.hostPlatform = "x86_64-linux";

    # Home-manager imports (at host level)
    home-manager.users.${username}.imports = [
      # External home-manager modules
      inputs.nix-index-database.homeModules.nix-index
      inputs.sops-nix.homeManagerModules.sops
      # ... other external modules

      # Feature home-manager modules
      homeManager.shell
      homeManager.git
      homeManager.ssh
      homeManager.gaming
      # ... other feature modules
    ];

    # Host-specific configuration using host.* options
    host = {
      username = username;
      hostname = "jupiter";
      system = "x86_64-linux";
      hardware.renderDevice = "/dev/dri/renderD128";

      features = {
        desktop = {
          enable = true;
          niri = true;
          theming = true;
          utilities = true;
          autoLogin = {
            enable = true;
            user = username;
          };
          signalTheme = {
            enable = true;
            mode = "dark";
          };
        };

        gaming = {
          enable = true;
          steam = true;
          performance = true;
        };

        vr = {
          enable = true;
          wivrn = {
            enable = true;
            autoStart = true;
            defaultRuntime = true;
          };
          steamvr = true;
          immersed.enable = true;
          performance = true;
        };

        security = {
          fail2ban.enable = true;
          yubikey.enable = true;
        };

        development = {
          enable = true;
          nix-ld.enable = true;
        };

        aiTools = {
          enable = true;
          claudeCode.enable = true;
          cursor.enable = true;
          comfyui.enable = true;
        };

        media = {
          enable = true;
          jellyfin.enable = true;
          arr.enable = true;
        };

        virtualisation = {
          enable = true;
          podman.enable = true;
        };

        productivity.enable = true;
      };

      services.caddy = {
        enable = true;
        email = useremail;
      };
    };

    networking.hostName = "jupiter";
    system.stateVersion = constants.defaults.stateVersion;
    # ... other host-specific config
  };
}
```

### 9. Per-System Modules

The `modules/per-system/` directory contains flake-parts per-system modules that define flake outputs for each system:

```nix
# modules/per-system/apps.nix
{ inputs, ... }:
{
  perSystem = { config, pkgs, ... }: {
    apps = {
      update-all = {
        type = "app";
        program = "${pkgs.pog-scripts.update-all}/bin/update-all";
      };
      new-module = {
        type = "app";
        program = "${pkgs.pog-scripts.new-module}/bin/new-module";
      };
    };
  };
}
```

```nix
# modules/per-system/formatters.nix
{ inputs, ... }:
{
  perSystem = { pkgs, ... }: {
    formatter = pkgs.treefmt;
  };
}
```

```nix
# modules/per-system/devShells.nix
{ inputs, ... }:
{
  perSystem = { pkgs, ... }: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        nixd
        nixfmt-rfc-style
        treefmt
      ];
    };
  };
}
```

## Module Types Summary

| Type | Location | Purpose |
|------|----------|---------|
| Infrastructure | `modules/infrastructure/*.nix` | Declares options, transforms to flake outputs |
| Meta | `modules/meta.nix` | Shared options (username, email) |
| Constants | `modules/constants.nix` | Structured configuration data (ports, timeouts, networks, etc.) |
| Options | `modules/options/*.nix` | Defines `host.*` options in base modules |
| Feature | `modules/<feature>.nix` | Reusable config via `flake.modules.*` |
| Host | `modules/hosts/<name>/definition.nix` | Composes features into a host |
| Core | `modules/core/*.nix` | Core system modules (boot, networking, security) |
| Desktop | `modules/desktop/*.nix` | Desktop environment modules |
| Hardware | `modules/hardware/*.nix` | Hardware support modules |
| Services | `modules/services/*.nix` | Service modules |
| Per-System | `modules/per-system/*.nix` | Flake-parts per-system outputs |
| Outputs | `modules/outputs/*.nix` | Library and overlay exports |

## Access Patterns

### From Feature Module (flake-parts level)
```nix
{ config, ... }:
{
  flake.modules.nixos.myFeature = {
    users.users.${config.username} = { ... };
  };
}
```

### From Feature Module (platform config)
```nix
{ config, ... }:
{
  flake.modules.nixos.myFeature = { pkgs, lib, config, ... }: {
    # 'config' here is NixOS config, not flake-parts config
    environment.systemPackages = [ pkgs.somePackage ];
  };
}
```

### From Home-Manager Module
```nix
{ config, ... }:
{
  flake.modules.homeManager.myFeature = { pkgs, config, osConfig ? {}, ... }: {
    # config = home-manager config
    # osConfig = NixOS/Darwin config (when available)
    home.packages = [ pkgs.somePackage ];

    # Can conditionally enable based on system config
    programs.myApp.enable = lib.mkIf osConfig.host.features.gaming.enable true;
  };
}
```

### Constants Access
```nix
{ config, ... }:
let
  constants = config.constants;
in
{
  flake.modules.nixos.myService = { ... }: {
    services.myService.port = constants.ports.services.myService;
    networking.firewall.allowedTCPPorts = [ constants.ports.services.myService ];
  };
}
```

### Host Options Access
```nix
{ config, ... }:
{
  flake.modules.nixos.myFeature = { lib, config, ... }: {
    # Feature is enabled via host.features
    services.myFeature = lib.mkIf config.host.features.myFeature.enable {
      enable = true;
      user = config.host.username;
    };
  };
}
```

## Module Organization Patterns

### Subdirectory Organization

**Purpose**: Group related modules by category for better organization:

- **`modules/core/`**: Fundamental system modules (boot, networking, nix, security, users)
- **`modules/desktop/`**: Desktop environment modules (compositor, fonts, theme, xdg)
- **`modules/hardware/`**: Hardware support (bluetooth, keyboard, yubikey)
- **`modules/services/`**: Service modules (ssh, caddy, ollama, podman)
- **`modules/per-system/`**: Flake-parts per-system outputs (apps, devShells, formatters)
- **`modules/outputs/`**: Library and overlay exports

**Rule**: Subdirectories are for organization only - each file still defines one or more `flake.modules.*` attributes.

### Wrapper Module Pattern

Wrapper modules provide a simple module that imports related functionality:

```nix
# modules/gaming-home.nix - wrapper that re-exports gaming module
{ config, ... }:
{
  flake.modules.homeManager.gamingHome = { lib, ... }: {
    imports = [ config.flake.modules.homeManager.gaming ];
  };
}
```

**When to use**:
- Creating platform-specific variants (e.g., `gaming` and `gamingHome`)
- Providing backwards compatibility
- Grouping related modules under a single import

**Anti-pattern**: Don't create wrappers that only import from old structure - migrate the full implementation instead.

## Benefits

1. **Single Source of Truth** - Options like `username` defined once, used everywhere
2. **Auto-Discovery** - Add a file to `modules/`, it's automatically imported
3. **Type Safety** - `deferredModule` and `lazyAttrsOf` provide proper typing
4. **Cross-Platform** - Same module can declare nixos, darwin, homeManager configs
5. **Composable** - Hosts explicitly choose which features to include
6. **Checkable** - Auto-generated checks validate all configurations
7. **Consistent** - Darwin and NixOS follow identical patterns
8. **Feature-Oriented** - Think in features, not platforms
9. **Rich Constants** - Centralized ports, timeouts, networks configuration
10. **Feature Flags** - Comprehensive `host.features` system for declarative configuration
11. **System Context Access** - Home-manager modules can read system config via `osConfig`

## Anti-Patterns to Avoid

1. **Don't use `with pkgs;`** - Always use explicit `pkgs.packageName`
2. **Don't hardcode values** - Use `meta.nix` options or `constants.nix`
3. **Don't mix concerns** - Feature modules shouldn't know about specific hosts
4. **Don't import features in infrastructure** - All imports happen at host level
5. **Don't use extraSpecialArgs** - Use top-level flake-parts options instead
6. **Don't create multiple files for a single module path** - One `flake.modules.*` path = one file
7. **Don't create wrapper modules that import old structure** - Migrate the full implementation
8. **Don't duplicate port/timeout values** - Add them to `constants.nix` instead
9. **Don't manually manage feature flags** - Use the `host.features` system
10. **Don't bypass `osConfig`** - When home-manager needs system config, use `osConfig` parameter

## Advanced Patterns

### Conditional Platform Behavior

Use `lib.mkMerge` with `pkgs.stdenv.isLinux` / `pkgs.stdenv.isDarwin` for platform-specific behavior:

```nix
{ config, ... }:
{
  flake.modules.homeManager.myApp = { lib, pkgs, ... }:
    lib.mkMerge [
      {
        # Common configuration for all platforms
        programs.myApp.enable = true;
      }
      (lib.mkIf pkgs.stdenv.isLinux {
        # Linux-specific configuration
        programs.myApp.linuxOption = true;
      })
      (lib.mkIf pkgs.stdenv.isDarwin {
        # macOS-specific configuration
        programs.myApp.darwinOption = true;
      })
    ];
}
```

### Feature-Gated Configuration

Use `host.features` to conditionally enable configuration:

```nix
{ config, ... }:
{
  flake.modules.nixos.myFeature = { lib, config, pkgs, ... }: {
    # Only enable if feature flag is set
    services.myService = lib.mkIf config.host.features.myFeature.enable {
      enable = true;
      package = pkgs.myService;
    };

    # Nested feature flags
    environment.systemPackages = lib.optionals config.host.features.myFeature.extraTools [
      pkgs.myTool
    ];
  };
}
```

### Secret Management with SOPS

Access SOPS secrets in home-manager modules via `osConfig`:

```nix
{ config, ... }:
{
  flake.modules.homeManager.myApp = { lib, config, osConfig ? {}, ... }: {
    programs.myApp = lib.mkIf (osConfig ? sops.secrets.MY_API_KEY) {
      apiKey = config.sops.secrets.MY_API_KEY.path;
    };
  };
}
```

## References

- [Dendritic Pattern (mightyiam)](https://github.com/mightyiam/dendritic) - Original pattern
- [Dendritic Design Guide (Doc-Steve)](https://github.com/Doc-Steve/dendritic-design-with-flake-parts) - Comprehensive guide
- [Flake Parts Documentation](https://flake.parts) - Flake-parts framework
- [Example: mightyiam/infra](https://github.com/mightyiam/infra) - Real-world example
- [Flipping the Configuration Matrix](https://not-a-number.io/2025/refactoring-my-infrastructure-as-code-configurations/#flipping-the-configuration-matrix) - Architecture explanation
