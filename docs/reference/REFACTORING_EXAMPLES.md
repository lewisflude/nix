# Module Over-Engineering: Concrete Refactoring Examples

This document shows specific over-engineered patterns with simplified alternatives.

## Example 1: Media Management - Three-Layer Abstraction

### CURRENT PATTERN (Over-Engineered)

**Step 1: Define Feature Options** (`host-options/features.nix`)

```nix
mediaManagement = {
  enable = mkEnableOption "native media management stack";
  dataPath = mkOption { type = types.str; default = "/mnt/storage"; };
  timezone = mkOption { type = types.str; default = "Europe/London"; };
  prowlarr = mkEnableOption "Prowlarr indexer manager";
  radarr = mkEnableOption "Radarr movie management";
  sonarr = mkEnableOption "Sonarr TV management";
  lidarr = mkEnableOption "Lidarr music management";
  readarr = mkEnableOption "Readarr book management";
  sabnzbd = mkEnableOption "SABnzbd usenet client";
  qbittorrent = mkOption { type = types.attrs; default = {}; };
  jellyfin = mkEnableOption "Jellyfin media server";
  jellyseerr = mkEnableOption "Jellyseerr requests";
  flaresolverr = mkEnableOption "FlareSolverr proxy";
  unpackerr = mkEnableOption "Unpackerr automation";
  navidrome = mkEnableOption "Navidrome music server";
};
```

**Step 2: Bridge Layer** (`features/media-management.nix`)

```nix
config = mkIf cfg.enable {
  host.services.mediaManagement = {
    enable = true;
    dataPath = cfg.dataPath or "/mnt/storage";
    timezone = cfg.timezone or "Europe/London";
    prowlarr = cfg.prowlarr or { };
    radarr = cfg.radarr or { };
    sonarr = cfg.sonarr or { };
    lidarr = cfg.lidarr or { };
    readarr = cfg.readarr or { };
    sabnzbd = cfg.sabnzbd or { };
    qbittorrent = cfg.qbittorrent or { };
    jellyfin = cfg.jellyfin or { };
    jellyseerr = cfg.jellyseerr or { };
    flaresolverr = cfg.flaresolverr or { };
    unpackerr = cfg.unpackerr or { };
    navidrome = cfg.navidrome or { };
  };
};
```

**Step 3: Service Implementation** (`services/media-management/default.nix`)

```nix
imports = [
  ./options.nix  # Redefines same options!
  ./common.nix
  ./prowlarr.nix
  ./radarr.nix
  ./sonarr.nix
  ./lidarr.nix
  ./readarr.nix
  ./sabnzbd.nix
  ./qbittorrent.nix
  ./jellyfin.nix
  ./jellyseerr.nix
  ./flaresolverr.nix
  ./unpackerr.nix
  ./navidrome.nix
];
```

**Step 4: Individual Service Module** (`services/media-management/prowlarr.nix`)

```nix
{
  options.host.services.mediaManagement.prowlarr = {
    enable = mkEnableOption "Prowlarr indexer manager" // { default = true; };
  };

  config = mkIf (config.host.services.mediaManagement.enable && cfg.enable) {
    services.prowlarr = {
      enable = true;
      openFirewall = true;
    };

    systemd.services.prowlarr = {
      environment.TZ = config.host.services.mediaManagement.timezone;
      serviceConfig.User = config.host.services.mediaManagement.user;
      serviceConfig.Group = config.host.services.mediaManagement.group;
    };
  };
}
```

**Problems:**

- 4 files to define one feature group
- Step 2 (bridge) is pure passthrough with no logic
- Options defined in TWO places (host-options + services)
- User must understand 3 abstraction layers

### SIMPLIFIED PATTERN

**Single Module** (`modules/nixos/features/media-management.nix`)

```nix
{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkOption types mkIf optionals;
  cfg = config.host.features.mediaManagement;

  serviceDefaults = {
    prowlarr = { enable = true; };
    radarr = { enable = true; };
    sonarr = { enable = true; };
    lidarr = { enable = true; };
    readarr = { enable = true; };
    sabnzbd = { enable = true; };
    jellyfin = { enable = true; };
    jellyseerr = { enable = true; };
    flaresolverr = { enable = true; };
    unpackerr = { enable = true; };
    navidrome = { enable = true; };
  };
in {
  options.host.features.mediaManagement = {
    enable = mkEnableOption "media management services";
    dataPath = mkOption {
      type = types.str;
      default = "/mnt/storage";
      description = "Path to media storage";
    };
    timezone = mkOption {
      type = types.str;
      default = "Europe/London";
      description = "Timezone for services";
    };

    # Service options as submodules
    services = mkOption {
      type = types.attrsOf (types.submodule {
        options.enable = mkEnableOption "Enable this service";
      });
      default = serviceDefaults;
    };
  };

  config = mkIf cfg.enable {
    # Create media user
    users.users.media = {
      isSystemUser = true;
      group = "media";
      description = "Media services user";
      home = "/var/lib/media";
      createHome = true;
    };
    users.groups.media = { };

    # Create directories
    systemd.tmpfiles.rules = [
      "d ${cfg.dataPath} 0775 media media -"
      "d ${cfg.dataPath}/media 0775 media media -"
      "d ${cfg.dataPath}/media/movies 0775 media media -"
      "d ${cfg.dataPath}/media/tv 0775 media media -"
      "d ${cfg.dataPath}/torrents 0775 media media -"
      "d ${cfg.dataPath}/usenet 0775 media media -"
    ];

    # Enable services based on config
    services.prowlarr.enable = mkIf cfg.services.prowlarr.enable true;
    systemd.services.prowlarr.serviceConfig = mkIf cfg.services.prowlarr.enable {
      User = "media";
      Group = "media";
    };
    systemd.services.prowlarr.environment = mkIf cfg.services.prowlarr.enable {
      TZ = cfg.timezone;
    };

    # ... repeat for each service, but now they're clearly visible here
    # This is much easier to modify or add to than finding files scattered
    # across services/media-management/
  };
}
```

**Benefits:**

- Single file: All logic in one place
- No bridge layer: Direct feature → implementation
- No repeated options: Defined once
- Clear service configuration: All visible
- Easier to modify: Change one file, not five

---

## Example 2: Micro-Modules → Single Module with attrSet

### CURRENT PATTERN (Over-Engineered)

**11 separate files:**

```
services/media-management/
├── prowlarr.nix    (34 lines)
├── radarr.nix      (35 lines)
├── sonarr.nix      (43 lines)
├── lidarr.nix      (33 lines)
├── readarr.nix     (30 lines)
├── sabnzbd.nix     (41 lines)
├── qbittorrent.nix (176 lines)
├── jellyfin.nix    (33 lines)
├── jellyseerr.nix  (32 lines)
├── flaresolverr.nix (20 lines)
└── unpackerr.nix   (59 lines)
```

Each follows same pattern (example prowlarr.nix):

```nix
{
  options.host.services.mediaManagement.prowlarr = {
    enable = mkEnableOption "Prowlarr indexer manager" // { default = true; };
  };

  config = mkIf (config.host.services.mediaManagement.enable && cfg.enable) {
    services.prowlarr = {
      enable = true;
      openFirewall = true;
    };

    systemd.services.prowlarr = {
      environment = { TZ = config.host.services.mediaManagement.timezone; };
      serviceConfig = {
        User = config.host.services.mediaManagement.user;
        Group = config.host.services.mediaManagement.group;
      };
    };
  };
}
```

**Problem:** Boilerplate repeated 11 times with only service name changing.

### SIMPLIFIED PATTERN

**Single file with attrsOf submodules:**

```nix
# modules/nixos/services/media-management.nix
{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkOption types mkIf;
  cfg = config.host.services.mediaManagement;

  # Service definitions
  serviceDefinitions = {
    prowlarr = {
      description = "Prowlarr indexer manager";
      nixosService = "services.prowlarr";
      ports = [ ];
    };
    radarr = {
      description = "Radarr movie management";
      nixosService = "services.radarr";
      ports = [ ];
    };
    # ... etc for all services
  };
in {
  options.host.services.mediaManagement = {
    enable = mkEnableOption "media management services";
    dataPath = mkOption { type = types.str; default = "/mnt/storage"; };
    timezone = mkOption { type = types.str; default = "Europe/London"; };
    user = mkOption { type = types.str; default = "media"; };
    group = mkOption { type = types.str; default = "media"; };

    # Single submodule type for all services
    services = mkOption {
      type = types.attrsOf (types.submodule {
        options.enable = mkEnableOption "Enable this service";
      });
      default = lib.mapAttrs (_: _: { enable = true; }) serviceDefinitions;
    };
  };

  config = mkIf cfg.enable {
    # Create user/group once
    users.users.${cfg.user} = {
      isSystemUser = true;
      inherit (cfg) group;
      home = "/var/lib/${cfg.user}";
      createHome = true;
    };
    users.groups.${cfg.group} = { };

    # Configure each service in one place
    services = lib.mkMerge (lib.mapAttrsToList (serviceName: serviceCfg:
      lib.mkIf serviceCfg.enable {
        # Dynamic service configuration
        "${serviceName}" = {
          enable = true;
          openFirewall = true;
          user = cfg.user;
          group = cfg.group;
        };
      }
    ) (lib.filterAttrs (_: s: s.enable) cfg.services));

    # Set timezone for all services at once
    systemd.services = lib.mkMerge (lib.mapAttrsToList (serviceName: serviceCfg:
      lib.mkIf serviceCfg.enable {
        "${serviceName}" = {
          environment.TZ = cfg.timezone;
          serviceConfig = {
            User = cfg.user;
            Group = cfg.group;
          };
        };
      }
    ) (lib.filterAttrs (_: s: s.enable) cfg.services));

    # Directories
    systemd.tmpfiles.rules = [
      "d ${cfg.dataPath} 0775 ${cfg.user} ${cfg.group} -"
      # ... paths
    ];
  };
}
```

**Benefits:**

- Single file: 250-300 lines vs. 548 lines across 13 files
- No boilerplate repetition
- Service configuration centralized and visible
- Adding new service: 5 lines in serviceDefinitions
- Easier to refactor common patterns

---

## Example 3: Trivial Utility Functions

### CURRENT PATTERN (Over-Engineered)

`containers-supplemental/lib.nix`:

```nix
_: let inherit (builtins) toString; in
{
  mkResourceOptions = defaults: {
    memory = mkOption {
      type = types.str;
      default = defaults.memory or "512m";
      description = "Memory limit for the container";
    };
    cpus = mkOption {
      type = types.str;
      default = defaults.cpus or "1";
      description = "CPU limit for the container";
    };
    memorySwap = mkOption {
      type = types.nullOr types.str;
      default = defaults.memorySwap or null;
      description = "Memory + swap limit";
    };
  };

  mkResourceFlags = resources: [
    "--memory=${resources.memory}"
    "--cpus=${resources.cpus}"
  ] ++ optional (resources.memorySwap != null) "--memory-swap=${resources.memorySwap}";

  mkHealthFlags = { cmd, interval ? "30s", timeout ? "10s", retries ? "3", startPeriod ? null }:
    [
      "--health-cmd=${cmd}"
      "--health-interval=${interval}"
      "--health-timeout=${timeout}"
      "--health-retries=${retries}"
    ]
    ++ optional (startPeriod != null) "--health-start-period=${startPeriod}";
}
```

Then imported in every service:

```nix
containersLib = import ../lib.nix { inherit lib; };
inherit (containersLib) mkResourceOptions mkResourceFlags mkHealthFlags;
```

**Problem:** Simple transformations wrapped in functions that add 0 logic.

### SIMPLIFIED PATTERN

Inline in homarr.nix:

```nix
options.host.services.containersSupplemental.homarr = {
  enable = mkEnableOption "Homarr dashboard" // { default = true; };

  memory = mkOption {
    type = types.str;
    default = "512m";
    description = "Memory limit";
  };

  cpus = mkOption {
    type = types.str;
    default = "0.5";
    description = "CPU limit";
  };
};

config = mkIf (cfg.enable && cfg.homarr.enable) {
  virtualisation.oci-containers.containers.homarr = {
    image = "ghcr.io/ajnart/homarr:0.15.3";
    environment.TZ = cfg.timezone;
    volumes = [...];
    ports = ["7575:7575"];
    extraOptions = [
      "--memory=${cfg.homarr.memory}"
      "--cpus=${cfg.homarr.cpus}"
      "--health-cmd=wget --no-verbose --tries=1 --spider http://localhost:7575/ || exit 1"
      "--health-interval=30s"
      "--health-timeout=10s"
      "--health-retries=3"
    ];
  };
};
```

**Benefits:**

- Removed 50 lines of utility functions
- Explicit, readable container configuration
- No abstract function names to remember
- Clear what each flag does

---

## Example 4: Repeated Option Definitions

### CURRENT PATTERN

**In `host-options/features.nix`:**

```nix
mediaManagement = {
  enable = mkEnableOption "...";
  dataPath = mkOption { type = types.str; default = "/mnt/storage"; };
  timezone = mkOption { type = types.str; default = "Europe/London"; };
};
```

**In `services/media-management/options.nix`:**

```nix
options.host.services.mediaManagement = {
  enable = mkEnableOption "...";
  dataPath = mkOption { type = types.str; default = "/mnt/storage"; };
  timezone = mkOption { type = types.str; default = "Europe/London"; };
};
```

**Problem:** Options defined twice! Changes must be made in two places.

### SIMPLIFIED PATTERN

Define once, import elsewhere:

```nix
# modules/shared/lib.nix
{
  mediaManagementOptions = {
    enable = mkEnableOption "native media management stack";
    dataPath = mkOption { type = types.str; default = "/mnt/storage"; };
    timezone = mkOption { type = types.str; default = "Europe/London"; };
  };
}
```

Then use in:

```nix
# modules/nixos/features/media-management.nix
options.host.features.mediaManagement = mediaLib.mediaManagementOptions;

# modules/nixos/services/media-management.nix (if needed as service too)
options.host.services.mediaManagement = mediaLib.mediaManagementOptions;
```

**Benefits:**

- Single source of truth
- Changes in one place
- No drift risk

---

## Example 5: Bridge Modules That Add No Value

### CURRENT PATTERN

`features/ai-tools.nix`:

```nix
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.host.features.aiTools;
in
{
  config = mkIf cfg.enable {

    host.services.aiTools = {
      enable = true;
      ollama = cfg.ollama or { };
      openWebui = cfg.openWebui or { };
    };
  };
}
```

**Problem:** This entire file is just passing options through to services layer.

### SIMPLIFIED PATTERN

Delete bridge module, implement feature directly or use service layer.

#### Option A: Feature implements directly (no service layer)

```nix
# modules/nixos/features/ai-tools.nix
{
  config, lib, pkgs, ...
}:
let
  inherit (lib) mkIf mkEnableOption mkOption types;
  cfg = config.host.features.aiTools;
in {
  options.host.features.aiTools = {
    enable = mkEnableOption "AI tools and LLMs";

    ollama = {
      enable = mkEnableOption "Ollama LLM backend";
      acceleration = mkOption {
        type = types.nullOr (types.enum ["cuda" "rocm"]);
        default = null;
      };
    };

    openWebui = {
      enable = mkEnableOption "Open WebUI";
      port = mkOption { type = types.int; default = 7000; };
    };
  };

  config = mkIf cfg.enable {
    services.ollama = mkIf cfg.ollama.enable {
      enable = true;
      acceleration = cfg.ollama.acceleration;
    };

    # ... open-webui config
  };
}
```

#### Option B: Service layer is primary (no feature bridge)

```nix
# modules/nixos/services/ai-tools.nix directly includes all logic
# Users configure host.services.aiTools directly (not via features)
```

**Benefits:**

- No pointless indirection
- Fewer files
- Clearer data flow

---

## Summary

These examples show how over-engineering complicates the system:

| Aspect | Over-Engineered | Simplified | Improvement |
|--------|---|---|---|
| Media Management Files | 13 | 1 | 92% fewer files |
| Total Lines | 548 | 300 | 45% less code |
| Abstraction Layers | 3 | 1 | 2x simpler |
| Option Definitions | 2 locations | 1 location | Single source of truth |
| Bridge Modules | 4+ | 0 | Eliminated overhead |

The core functionality is identical, but simplified version is far easier to understand and maintain.
