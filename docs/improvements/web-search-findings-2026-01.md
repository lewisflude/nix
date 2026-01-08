# Web Search Findings - NixOS Configuration Improvements

**Date:** January 2026
**Searches Conducted:** 40 queries across all priority areas
**Status:** Actionable recommendations based on 2025-2026 best practices

---

## Table of Contents

1. [Critical Priority - Fix Immediately](#-critical-priority---fix-immediately)
2. [High Priority - Performance & Best Practices](#-high-priority---performance--best-practices)
3. [Medium Priority - Use Case Specific](#-medium-priority---use-case-specific)
4. [Nice to Have - Future Improvements](#-nice-to-have---future-improvements)
5. [Quick Action Checklist](#-quick-action-checklist)
6. [Key Resources](#-key-resources)

---

## 🔴 CRITICAL PRIORITY - Fix Immediately

### 1. Replace Theme System with Stylix

**Current Issue:** Custom theme abstraction has 4+ layers (lib.nix, helpers.nix, context.nix, palette.nix) with unused validation functions and unnecessary complexity.

**Recommended Solution: [Stylix](https://github.com/nix-community/stylix)**

**Why Stylix:**

- **"It just works" philosophy** - automatic theming for 50+ applications
- Uses Base16 color schemes (only 16 colors needed)
- Per-target enable/disable: `stylix.targets.<target>.enable`
- Set `stylix.autoEnable = false` for manual control
- **Hybrid approach:** Use Stylix for most apps, disable for custom-themed apps

**Implementation:**

```nix
# Add to flake inputs
inputs.stylix.url = "github:danth/stylix";

# Basic configuration
stylix = {
  enable = true;
  base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
  image = ./wallpaper.png;  # Auto-generates colors if no scheme

  fonts = {
    monospace = {
      package = pkgs.nerdfonts;
      name = "JetBrainsMono Nerd Font";
    };
  };

  # Disable specific targets for custom theming
  targets.gtk.enable = false;  # If you want custom GTK theme
};
```

**Migration Strategy:**

1. Add Stylix to flake inputs
2. Enable with basic config
3. Disable custom theme modules one by one
4. Remove custom theme abstraction layers

**Sources:**

- [Stylix GitHub](https://github.com/nix-community/stylix)
- [Ricing Linux with Stylix](https://journix.dev/posts/ricing-linux-has-never-been-easier-nixos-and-stylix/)
- [Stylix Documentation](https://nix-community.github.io/stylix/)
- Alternative: [nix-colors](https://github.com/Misterio77/nix-colors) for more manual control

---

### 2. Fix `with pkgs;` Antipattern

**Location:** `shells/utils/shell-selector.nix:3`

**Issue:** Using deprecated `with pkgs;` pattern. Static analysis can't reason about code with `with`, and it's not clear where names come from.

**Fix:**

```nix
# ❌ Current (WRONG)
buildInputs = with pkgs; [ fzf bat fd ];

# ✅ Fixed (CORRECT)
buildInputs = [ pkgs.fzf pkgs.bat pkgs.fd ];
```

**Why This Matters:**

- Enables static analysis tools
- Makes code more explicit and readable
- Prevents shadowing issues with multiple `with` statements
- Aligns with Nixpkgs contributing guidelines

**Sources:**

- [with considered harmful](https://toraritte.github.io/posts/2020-08-15-with-considered-harmful.html)
- [NixOS Best Practices](https://nix.dev/guides/best-practices.html)
- [Nixpkgs Contributing Guide](https://github.com/NixOS/nix.dev/pull/307)

---

### 3. Enable Statix Linter

**Purpose:** Automated detection of antipatterns, code quality issues, and bad practices.

**Implementation:**

```nix
# Add to treefmt configuration
programs.statix = {
  enable = true;
};

# Or run manually
statix check    # Find issues
statix fix      # Auto-fix issues
```

**Features:**

- Automatically detects `with pkgs;`, `rec` usage, and 20+ other antipatterns
- Can auto-fix many issues
- Integrates with treefmt-nix
- JSON/errfmt output formats for CI/CD
- Respects `.gitignore`

**Configuration (.statix.toml):**

```toml
# Disable specific lints if needed
[lint]
disabled = []

# Ignore specific files/dirs
ignore = [
  "result",
  ".direnv"
]
```

**CI Integration:**

```nix
# Add to flake checks
checks.${system}.statix = pkgs.runCommand "statix-check" {} ''
  ${pkgs.statix}/bin/statix check ${self}
  touch $out
'';
```

**Sources:**

- [Statix Announcement](https://discourse.nixos.org/t/statix-lints-and-suggestions-for-the-nix-programming-language/15714)
- [GitHub: statix](https://github.com/oppiliappan/statix)
- [Statix GitHub Action](https://github.com/jocelynthode/statix-action)

---

## 🟡 HIGH PRIORITY - Performance & Best Practices

### 4. Optimize Build Performance

#### A. Use nix-fast-build for Parallel Evaluation

**What:** Combines nix-eval-jobs with nix-output-monitor for concurrent evaluation and building.

**Benefits:**

- Speedups of 3-4x typical
- Parallel evaluation of derivations
- Better progress reporting

**Usage:**

```bash
# Run once
nix run github:Mic92/nix-fast-build

# Or alias it
alias nfb="nix run github:Mic92/nix-fast-build"
```

**Integration with Cachix:**

```bash
# Set environment variables
export CACHIX_SIGNING_KEY="..."
export CACHIX_AUTH_TOKEN="..."

# nix-fast-build will automatically use them
```

**Sources:**

- [nix-fast-build GitHub](https://github.com/Mic92/nix-fast-build)

---

#### B. Configure Parallel Builds in nix.conf

**Implementation:**

```nix
nix.settings = {
  # Use all available CPU cores for max-jobs
  max-jobs = "auto";

  # Each build uses all available cores
  # 0 = use all available cores
  cores = 0;

  # Parallel substitution (binary cache downloads)
  max-substitution-jobs = 16;

  # Parallel HTTP connections for downloads
  http-connections = 25;

  # Enable experimental features
  experimental-features = [ "nix-command" "flakes" ];
};
```

**Performance Impact:**

- `max-jobs = "auto"` uses number of CPUs (vs default 1)
- `cores = 0` allows builds to use all cores (vs default 1)
- Significantly reduces rebuild times on multi-core systems

**Sources:**

- [nix.conf Reference](https://nix.dev/manual/nix/2.24/command-ref/conf-file.html)
- [Parallel builds discussion](https://discourse.nixos.org/t/rfc-make-stdenv-to-build-in-parallel-by-default/15684)

---

#### C. Optimize Flake Evaluation

**NEW in Nix 2.33 (December 2025):**

```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  # NEW: Use shallow clones for faster fetching
  some-input.url = "github:owner/repo";
  some-input.shallow = true;  # 200x fewer syscalls!

  # Deduplicate nixpkgs across inputs
  home-manager.url = "github:nix-community/home-manager";
  home-manager.inputs.nixpkgs.follows = "nixpkgs";
};
```

**Benefits:**

- Shallow clones: 200x fewer system calls on Linux
- `follows` prevents multiple nixpkgs versions
- Reduces evaluation time
- Smaller flake.lock file

**Disable revCount if not needed:**

```nix
# Only if you don't use revCount
inputs.some-input.url = "github:...";
inputs.some-input.flake = false;  # Skip unnecessary metadata
```

**Sources:**

- [Nix 2.33 Release Notes](https://nix.dev/manual/nix/2.33/release-notes/rl-2.33)
- [Parallel Nix evaluation](https://determinate.systems/blog/parallel-nix-eval/)
- [Flake optimization guide](https://nixos-and-flakes.thiscute.world/nixos-with-flakes/update-the-system)

---

### 5. Adopt Modern Formatter - Transition to nixfmt

**Current State (2025/2026):**

- **nixfmt-rfc-style** is being adopted as official Nixpkgs formatter (RFC 166 near FCP)
- Alejandra is faster (Rust) but won't be the standard
- nixfmt will be enforced for nixpkgs contributions

**Recommendation:**

```nix
# In treefmt-nix config
programs.nixfmt = {
  enable = true;
  # Uses nixfmt-rfc-style package
};

programs.alejandra.enable = false;  # Disable if currently using
```

**Why nixfmt:**

- Will become required for nixpkgs contributions
- Favors readability over compactness
- Better git diffing
- Official NixOS project backing

**Migration:**

```bash
# Format entire project
treefmt

# Or run nixfmt directly
nixfmt **/*.nix
```

**Sources:**

- [Overview of Nix Formatters](https://drakerossman.com/blog/overview-of-nix-formatters-ecosystem)
- [nixfmt RFC](https://github.com/NixOS/nixfmt)
- [nixfmt announcement](https://discourse.nixos.org/t/call-for-testing-nix-formatter/39179)

---

### 6. Use `follows` for Flake Input Deduplication

**Problem:** Multiple nixpkgs versions increase evaluation time and disk usage.

**Solution:**

```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  home-manager.url = "github:nix-community/home-manager";
  home-manager.inputs.nixpkgs.follows = "nixpkgs";  # ← Deduplicates

  nix-darwin.url = "github:lnl7/nix-darwin";
  nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

  stylix.url = "github:danth/stylix";
  stylix.inputs.nixpkgs.follows = "nixpkgs";

  # Apply to ALL inputs that depend on nixpkgs
};
```

**Benefits:**

- Single nixpkgs evaluation instead of multiple
- Smaller disk usage
- Faster evaluation
- Consistent package versions across tools

**Check current inputs:**

```bash
nix flake metadata --json | jq '.locks.nodes | keys'
```

**Sources:**

- [Flakes best practices](https://nixos-and-flakes.thiscute.world/nixos-with-flakes/nixos-with-flakes-enabled)
- [Nix flakes explained](https://determinate.systems/blog/nix-flakes-explained/)

---

## 🟢 MEDIUM PRIORITY - Use Case Specific

### 7. Gaming/Streaming Optimizations

#### A. Low-latency Audio for Sunshine Streaming

**Current:** You have PipeWire enabled but not optimized for low latency.

#### Solution 1: Use nix-gaming module (RECOMMENDED)

```nix
# Add to flake inputs
inputs.nix-gaming.url = "github:fufexan/nix-gaming";

# In configuration
imports = [ inputs.nix-gaming.nixosModules.pipewireLowLatency ];

# Automatically configures optimal settings
```

#### Solution 2: Manual PipeWire Configuration

```nix
services.pipewire = {
  enable = true;

  extraConfig.pipewire."92-low-latency" = {
    "context.properties" = {
      "default.clock.rate" = 48000;
      "default.clock.quantum" = 32;        # Lower = less latency (0.667ms)
      "default.clock.min-quantum" = 32;
      "default.clock.max-quantum" = 32;
    };
  };

  extraConfig.pipewire-pulse."92-low-latency" = {
    "pulse.properties" = {
      "pulse.min.req" = "32/48000";
      "pulse.default.req" = "32/48000";
      "pulse.max.req" = "32/48000";
      "pulse.min.quantum" = "32/48000";
      "pulse.max.quantum" = "32/48000";
    };
  };
};

# Enable rtkit for realtime scheduling
security.rtkit.enable = true;
```

**Benefits:**

- Reduced audio crackling during streaming
- Lower latency for rhythm games
- Better sync with video

**Sources:**

- [nix-gaming repository](https://github.com/fufexan/nix-gaming)
- [PipeWire Wiki](https://wiki.nixos.org/wiki/PipeWire)
- [Audio latency optimization](https://discourse.nixos.org/t/pipewire-input-latency-updating-pipewire/59897)

---

#### B. Gamescope for HDR and VRR

**Current:** Sunshine works but may not have HDR/VRR enabled.

**Implementation:**

```nix
programs.gamescope = {
  enable = true;
  capSysNice = true;  # Allow realtime scheduling
};

# Example: Launch games with HDR and VRR
programs.steam.gamescopeSession = {
  enable = true;
  args = [
    "--adaptive-sync"      # VRR/FreeSync/G-Sync support
    "--hdr-enabled"        # HDR support
    "--hdr-itm-enable"     # Inverse tone mapping
    "--fullscreen"
    "-W 2560"              # Your resolution
    "-H 1440"
  ];
};
```

**Alternative: Use with Sunshine:**

```bash
# Launch game through Sunshine with gamescope
gamescope --adaptive-sync --hdr-enabled -- %command%
```

**Sources:**

- [Sunshine Wiki](https://wiki.nixos.org/wiki/Sunshine)
- [HDR on NixOS status](https://discourse.nixos.org/t/hdr-on-nixos-status/32351)
- [VRR configuration](https://discourse.nixos.org/t/enable-variable-refresh-rate-vrr-freesync/35011)

---

#### C. Additional Gaming Tools

```nix
# Gamemode for performance optimization
programs.gamemode = {
  enable = true;
  settings = {
    general = {
      renice = 10;
    };
    gpu = {
      apply_gpu_optimisations = "accept-responsibility";
      gpu_device = 0;
      amd_performance_level = "high";  # For AMD GPUs
    };
  };
};

# MangoHud for performance overlay
programs.mangohud = {
  enable = true;
  enableSessionWide = true;  # Enable for all games
};
```

**Sources:**

- [Gaming on NixOS](https://journix.dev/posts/gaming-on-nixos/)
- [NixOS Gaming Wiki](https://wiki.nixos.org/wiki/Category:Gaming)

---

### 8. VR Improvements (WiVRn + OpenComposite)

**Current:** You have WiVRn configured.

**Best Practices Configuration:**

```nix
services.wivrn = {
  enable = true;
  openFirewall = true;
  defaultRuntime = true;  # Auto-configure OpenXR runtime
  autoStart = true;

  # For NVIDIA GPU with CUDA encoding
  package = pkgs.wivrn.override { cudaSupport = true; };
};

# Install OpenComposite for SteamVR compatibility
home.packages = with pkgs; [
  opencomposite  # Or xrizer
  wlx-overlay-s  # Wayland overlay for VR
];

# NVIDIA-specific: Install Monado Vulkan Layers
# Required for drivers < 565
hardware.graphics.extraPackages = with pkgs; [
  monado-vulkan-layers
];
```

**OpenVR Configuration (Home Manager):**

```nix
# Configure OpenVR to use OpenComposite
xdg.configFile."openvr/openvrpaths.vrpath".text = ''
  {
    "runtime": ["${pkgs.opencomposite}/lib/opencomposite"]
  }
'';
```

**Steam Configuration:**

```nix
# Enable OpenXR runtime for Proton games
programs.steam = {
  enable = true;
  extraCompatPackages = [ pkgs.proton-ge-bin ];

  # Set environment variable for OpenXR
  gamescopeSession.env = {
    PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = "1";
  };
};
```

**What NOT to do:**

- ❌ Don't use Envision on NixOS - frequently breaks
- ❌ Don't manually manage monado.service - use services.wivrn

**Sources:**

- [VR on NixOS Wiki](https://wiki.nixos.org/wiki/VR)
- [Linux VR Adventures - WiVRn](https://lvra.gitlab.io/docs/fossvr/wivrn/)
- [VR on NixOS work](https://kugodd.net/2025/08/13/vr-nixos-work)

---

### 9. qBittorrent + ProtonVPN Port Forwarding Automation

**Current:** You have manual NAT-PMP scripts. This can be automated.

#### Solution 1: VPN-Confinement Module (RECOMMENDED)

```nix
# Add to flake inputs
inputs.vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";

# Import the module
imports = [ inputs.vpn-confinement.nixosModules.default ];

# Create VPN namespace
vpnNamespaces.wg-protonvpn = {
  enable = true;
  wireguardConfigFile = "/path/to/protonvpn.conf";

  # Forward ports from namespace to host
  portMappings = [
    { from = 8080; to = 8080; }  # qBittorrent web UI
    { from = 6881; to = 6881; }  # qBittorrent incoming
  ];

  # Allow access from LAN
  accessibleFrom = [ "192.168.1.0/24" ];
};

# Confine qBittorrent to VPN namespace
systemd.services.qbittorrent.vpnConfinement = {
  enable = true;
  vpnNamespace = "wg-protonvpn";
};
```

**Benefits:**

- Prevents DNS leaks
- Automatic kill switch (qBittorrent can't bypass VPN)
- Works with any systemd service
- Declarative configuration

#### Solution 2: Automated NAT-PMP Script

```nix
# Systemd service to keep port in sync
systemd.services.qbittorrent-natpmp = {
  description = "Update qBittorrent port from ProtonVPN NAT-PMP";
  after = [ "network-online.target" "qbittorrent.service" ];
  wants = [ "network-online.target" ];
  wantedBy = [ "multi-user.target" ];

  serviceConfig = {
    Type = "simple";
    Restart = "always";
    RestartSec = 60;
  };

  script = ''
    #!/usr/bin/env bash
    # Based on: github.com/Simon-CR/qbittorrent-wireguard-pmp

    while true; do
      # Get NAT-PMP port
      PORT=$(${pkgs.natpmpc}/bin/natpmpc -g 0.0.0.0 | grep -oP 'public port \K\d+')

      if [ -n "$PORT" ]; then
        # Update qBittorrent via API
        ${pkgs.curl}/bin/curl -s "http://localhost:8080/api/v2/app/setPreferences" \
          --data "json={\"listen_port\":$PORT}"
      fi

      sleep 45  # Refresh before 60s lease expires
    done
  '';
};
```

**Sources:**

- [VPN-Confinement](https://github.com/Maroka-chan/VPN-Confinement)
- [qbittorrent-wireguard-pmp](https://github.com/Simon-CR/qbittorrent-wireguard-pmp)
- [ProtonVPN auto NAT-PMP](https://github.com/giu176/ProtonVPN-auto-NATPMP)

---

### 10. Syncthing Hardening

**Current:** Syncthing is configured but could use security hardening.

**Implementation:**

```nix
services.syncthing = {
  enable = true;
  user = "username";
  dataDir = "/home/username/Sync";

  # Protect Web GUI
  settings.gui = {
    user = "admin";
    password = "hunter2";  # Use SOPS for this!
  };

  # Use SOPS for device keys
  key = config.sops.secrets.syncthing-key.path;
  cert = config.sops.secrets.syncthing-cert.path;

  # Firewall configuration
  openDefaultPorts = true;  # 22000 TCP/UDP, 21027 UDP

  # Don't open GUI port (use SSH tunnel instead)
  # settings.gui.address = "127.0.0.1:8384";
};

# Add systemd hardening
systemd.services.syncthing.serviceConfig = {
  # Sandboxing
  PrivateTmp = true;
  PrivateDevices = true;
  ProtectHome = "read-only";
  ProtectSystem = "strict";

  # Allow writing to sync directory
  ReadWritePaths = [ "/home/username/Sync" ];

  # Security
  ProtectKernelTunables = true;
  ProtectKernelModules = true;
  ProtectControlGroups = true;
  RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
  RestrictNamespaces = true;
  LockPersonality = true;
  MemoryDenyWriteExecute = true;
  RestrictRealtime = true;
  RestrictSUIDSGID = true;
  NoNewPrivileges = true;

  # System call filtering
  SystemCallFilter = [ "@system-service" "~@privileged @resources" ];
  SystemCallArchitectures = "native";
};

# Use SOPS for secrets
sops.secrets.syncthing-key = {
  owner = "username";
  mode = "0400";
};
sops.secrets.syncthing-cert = {
  owner = "username";
  mode = "0400";
};
```

**Verify Hardening:**

```bash
systemd-analyze security syncthing
```

**SSH Tunnel for Remote GUI Access:**

```bash
# On client machine
ssh -L 8384:localhost:8384 your-server
# Access GUI at http://localhost:8384
```

**Sources:**

- [Syncthing on NixOS](https://wiki.nixos.org/wiki/Syncthing)
- [Systemd Hardening](https://wiki.nixos.org/wiki/Systemd/Hardening)
- [NixOS Security Guide](https://notashelf.dev/posts/insecurities-remedies-i)
- [Reproducible Syncthing Deployments](https://wrycode.com/reproducible-syncthing-deployments/)

---

## 🔵 NICE TO HAVE - Future Improvements

### 11. Switch to devenv for Development Environments

**Current:** Using basic `nix develop` or `nix-shell`.

**Why devenv:**

- Activates in <100ms (cached evaluation)
- Built-in service management (Postgres, Redis, etc.)
- Pre-commit hooks integration
- Language-specific helpers
- Works seamlessly with direnv

**Implementation:**

```nix
# devenv.nix
{ pkgs, ... }: {
  # Languages
  languages.rust.enable = true;
  languages.python = {
    enable = true;
    version = "3.11";
    venv.enable = true;
  };
  languages.typescript.enable = true;

  # Services (automatically managed)
  services.postgres = {
    enable = true;
    initialDatabases = [{ name = "myapp"; }];
  };
  services.redis.enable = true;

  # Packages
  packages = with pkgs; [
    git
    jq
  ];

  # Scripts
  scripts.hello.exec = "echo Welcome to $DEVENV_ROOT";

  # Pre-commit hooks
  pre-commit.hooks = {
    treefmt.enable = true;
    statix.enable = true;
    deadnix.enable = true;
  };

  # Environment variables
  env.GREET = "devenv";

  # Processes (like Procfile)
  processes.backend.exec = "python manage.py runserver";
  processes.frontend.exec = "npm run dev";
}
```

**With direnv (.envrc):**

```bash
use devenv
```

**With flakes:**

```nix
{
  inputs.devenv.url = "github:cachix/devenv";

  outputs = { self, nixpkgs, devenv, ... }:
    devenv.lib.mkShell {
      inherit inputs pkgs;
      modules = [
        ./devenv.nix
      ];
    };
}
```

**Benefits:**

- No more "works on my machine" - truly reproducible
- Services start/stop automatically
- Instant activation (vs slow nix develop)
- Team collaboration (everyone has same env)

**Sources:**

- [devenv.sh](https://devenv.sh/)
- [Declarative Dev Environments](https://www.blog.brightcoding.dev/2025/09/28/declarative-development-environments-with-nix-and-devenv-zero-fuss-100-reproducible-set-ups/)
- [Using with Flakes](https://devenv.sh/guides/using-with-flakes/)

---

### 12. Add System Monitoring (Prometheus + Grafana)

**Why:** Visibility into system health, resource usage, and service status.

**Implementation:**

```nix
# Prometheus + Node Exporter
services.prometheus = {
  enable = true;
  port = 9090;

  exporters = {
    node = {
      enable = true;
      enabledCollectors = [
        "systemd"
        "processes"
        "cpu"
        "diskstats"
        "filesystem"
        "loadavg"
        "meminfo"
        "netdev"
      ];
      port = 9100;
    };
  };

  scrapeConfigs = [
    {
      job_name = "node";
      static_configs = [{
        targets = [ "localhost:9100" ];
      }];
    }
    {
      job_name = "prometheus";
      static_configs = [{
        targets = [ "localhost:9090" ];
      }];
    }
  ];
};

# Grafana
services.grafana = {
  enable = true;
  settings = {
    server = {
      http_addr = "127.0.0.1";
      http_port = 3000;
      domain = "localhost";
    };
    security = {
      admin_user = "admin";
      admin_password = "$__file{${config.sops.secrets.grafana-password.path}}";
    };
  };

  provision = {
    enable = true;
    datasources.settings.datasources = [
      {
        name = "Prometheus";
        type = "prometheus";
        url = "http://localhost:9090";
        isDefault = true;
      }
    ];

    dashboards.settings.providers = [
      {
        name = "Node Exporter";
        options.path = ./dashboards;
      }
    ];
  };
};

# Firewall (if accessing from network)
networking.firewall.allowedTCPPorts = [ 3000 ];  # Grafana

# Or use Nginx reverse proxy
services.nginx.virtualHosts."grafana.example.com" = {
  locations."/" = {
    proxyPass = "http://127.0.0.1:3000";
    proxyWebsockets = true;
  };
};
```

**Pre-built Dashboards:**

Download from [Grafana Dashboards](https://grafana.com/grafana/dashboards/):

- Node Exporter Full (ID: 1860)
- Prometheus 2.0 Stats (ID: 3662)

**Sources:**

- [Grafana Wiki](https://wiki.nixos.org/wiki/Grafana)
- [Prometheus Wiki](https://wiki.nixos.org/wiki/Prometheus)
- [Complete Example Gist](https://gist.github.com/rickhull/895b0cb38fdd537c1078a858cf15d63e)

---

### 13. Add Automated Backups (Restic)

**Why:** Protect against data loss, ransomware, hardware failure.

**Implementation:**

```nix
# Create SOPS secret for Restic password
sops.secrets.restic-password = {
  sopsFile = ./secrets/backup.yaml;
};

# Restic backup configuration
services.restic.backups = {
  daily = {
    initialize = true;
    passwordFile = config.sops.secrets.restic-password.path;

    # Repository (examples)
    repository = "s3:s3.amazonaws.com/my-bucket/nixos";
    # repository = "b2:bucketname:nixos";  # Backblaze B2
    # repository = "sftp:user@host:/backups";
    # repository = "/mnt/backup-drive/restic";

    # What to backup
    paths = [
      "/home"
      "/var/lib"
      "/etc/nixos"
      config.sops.secretsDir  # Don't forget secrets!
    ];

    # What to exclude
    exclude = [
      "/home/*/.cache"
      "/home/*/Downloads"
      "**/.direnv"
      "**/node_modules"
      "**/.git"
    ];

    # Scheduling
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;  # Run after boot if missed
      RandomizedDelaySec = "30min";
    };

    # Pruning (cleanup old backups)
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
      "--keep-yearly 2"
    ];

    # Backup check (verify integrity)
    checkOpts = [
      "--read-data-subset=5%"  # Check 5% of data
    ];

    # Run backup check monthly
    # (separate timer)
  };

  # Optional: System state backup
  system-state = {
    initialize = true;
    passwordFile = config.sops.secrets.restic-password.path;
    repository = "s3:s3.amazonaws.com/my-bucket/nixos-state";

    paths = [
      "/etc/nixos"
      "/var/lib/nixos"
    ];

    timerConfig.OnCalendar = "weekly";
    pruneOpts = [ "--keep-weekly 8" ];
  };
};

# For S3-compatible storage (AWS, Backblaze B2, etc.)
services.restic.backups.daily.s3CredentialsFile =
  config.sops.secrets.restic-s3-credentials.path;

# s3-credentials file format:
# AWS_ACCESS_KEY_ID=...
# AWS_SECRET_ACCESS_KEY=...
```

**Monitoring:**

```bash
# Check backup status
systemctl status restic-backups-daily.service

# Manual backup
systemctl start restic-backups-daily.service

# List snapshots
restic -r s3:... --password-file=... snapshots

# Restore
restic -r s3:... --password-file=... restore latest --target /restore
```

**Testing:**

```bash
# Initialize and test backup
systemd-run --unit=restic-test restic backup /etc/nixos

# Restore test
restic restore latest --target /tmp/restore-test
```

**Sources:**

- [Restic Wiki](https://wiki.nixos.org/wiki/Restic)
- [Restic with B2](https://www.arthurkoziel.com/restic-backups-b2-nixos/)
- [Automated Backups Guide](https://codewitchbella.com/blog/2024-nixos-automated-backup)
- [Optimized Backups with fd](https://felschr.com/blog/optimised-backups-on-nix-os-with-restic-and-fd/)

---

### 14. Improve LSP Configuration (Use nixd over nil)

**Current:** You may be using `nil` language server.

**Why nixd:**

- Compiles against official NixOS/nix library
- Analyzes entire codebase, not just current file
- Better NixOS options completion (knows about options)
- More accurate type information

**Implementation (Home Manager):**

```nix
programs.helix = {
  enable = true;

  languages = {
    language-server.nixd = {
      command = "nixd";
    };

    language = [{
      name = "nix";
      auto-format = true;
      language-servers = [ "nixd" ];
      formatter = {
        command = "${pkgs.nixfmt-rfc-style}/bin/nixfmt";
      };
    }];
  };
};

# Ensure nixd is installed
home.packages = [ pkgs.nixd ];
```

**nixd Configuration (~/.config/nixd/config.json):**

```json
{
  "nixpkgs": {
    "expr": "import <nixpkgs> { }"
  },
  "options": {
    "nixos": {
      "expr": "(builtins.getFlake \"/path/to/config\").nixosConfigurations.HOSTNAME.options"
    },
    "home-manager": {
      "expr": "(builtins.getFlake \"/path/to/config\").homeConfigurations.USER.options"
    }
  },
  "formatting": {
    "command": [ "nixfmt" ]
  }
}
```

**For VSCode/nix-ide:**

```nix
programs.vscode.extensions = [ pkgs.vscode-extensions.jnoortheen.nix-ide ];

# Configure to use nixd
programs.vscode.userSettings = {
  "nix.enableLanguageServer" = true;
  "nix.serverPath" = "nixd";
};
```

**Comparison:**

| Feature | nixd | nil |
|---------|------|-----|
| Speed | Moderate | Fast |
| Accuracy | High (uses nix lib) | Good |
| Options completion | Yes (NixOS/HM) | Limited |
| Whole-project analysis | Yes | No |
| Actively developed | Yes | Yes |

**Sources:**

- [Switching to nixd](https://sbulav.github.io/vim/neovim-setting-up-nixd/)
- [nixd Announcement](https://discourse.nixos.org/t/nixd-nix-language-server/28910)
- [Helix LSP Discussion](https://github.com/helix-editor/helix/discussions/8474)

---

## 📋 Quick Action Checklist

### This Week

- [ ] **Fix `with pkgs;` antipattern** in `shells/utils/shell-selector.nix`
  - File: `shells/utils/shell-selector.nix:3`
  - Change: `with pkgs;` → explicit `pkgs.package`

- [ ] **Enable statix linter** in treefmt config
  - Add `programs.statix.enable = true;`
  - Run `statix check` to find issues
  - Run `statix fix` to auto-fix

- [ ] **Add parallel build settings** to nix.conf
  - `nix.settings.max-jobs = "auto";`
  - `nix.settings.cores = 0;`

- [ ] **Add `follows` for all flake inputs**
  - Ensure all inputs follow main nixpkgs
  - Check with `nix flake metadata --json`

### This Month

- [ ] **Replace custom theme system with Stylix**
  - Add Stylix to flake inputs
  - Configure basic Stylix setup
  - Migrate one module at a time
  - Remove custom theme abstraction

- [ ] **Add PipeWire low-latency config** for streaming
  - Use nix-gaming module OR
  - Manual PipeWire configuration

- [ ] **Implement qBittorrent NAT-PMP automation**
  - Option A: VPN-Confinement module
  - Option B: Automated script with systemd

- [ ] **Add Syncthing systemd hardening**
  - Add security options to systemd service
  - Verify with `systemd-analyze security`

- [ ] **Switch formatter to nixfmt-rfc-style**
  - Update treefmt config
  - Run formatter on entire codebase
  - Update pre-commit hooks

### Next Quarter

- [ ] **Add Prometheus + Grafana monitoring**
  - Configure Prometheus + node_exporter
  - Set up Grafana with dashboards
  - Add alerting rules

- [ ] **Set up automated Restic backups**
  - Configure daily backups
  - Set up retention policy
  - Test restore procedure

- [ ] **Migrate to devenv** for dev environments
  - Convert one project as proof-of-concept
  - Document benefits for team
  - Roll out to other projects

- [ ] **Switch to nixd LSP**
  - Configure nixd for Helix
  - Set up project-specific options
  - Compare with nil performance

### Ongoing

- [ ] Run `statix check` before commits
- [ ] Monitor build performance improvements
- [ ] Review and prune unused modules
- [ ] Keep flake.lock updated weekly
- [ ] Test backups monthly

---

## 📚 Key Resources

### Official Documentation

- **[NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/)** - Comprehensive modern guide
- **[nix.dev](https://nix.dev/)** - Official Nix documentation
- **[NixOS Wiki](https://wiki.nixos.org/)** - Community wiki with examples
- **[Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/)** - Package collection reference
- **[Home Manager Manual](https://nix-community.github.io/home-manager/)** - User environment management

### Community

- **[NixOS Discourse](https://discourse.nixos.org/)** - Official forum
- **[r/NixOS](https://reddit.com/r/NixOS)** - Reddit community
- **[Awesome Nix](https://github.com/nix-community/awesome-nix)** - Curated resources
- **[NixOS Weekly](https://weekly.nixos.org/)** - Newsletter

### Config-Specific Tools

**Theme Management:**

- [Stylix](https://github.com/nix-community/stylix) - Automatic theming framework
- [nix-colors](https://github.com/Misterio77/nix-colors) - Base16 color schemes

**Gaming:**

- [nix-gaming](https://github.com/fufexan/nix-gaming) - Gaming optimizations
- [Sunshine Wiki](https://wiki.nixos.org/wiki/Sunshine) - Streaming setup
- [VR on NixOS](https://wiki.nixos.org/wiki/VR) - VR configuration guide

**Networking:**

- [VPN-Confinement](https://github.com/Maroka-chan/VPN-Confinement) - Per-app VPN routing
- [ProtonVPN Guide](https://discourse.nixos.org/t/how-to-configure-and-use-proton-vpn-on-nixos/65837)

**Development:**

- [devenv](https://devenv.sh/) - Modern development environments
- [direnv](https://direnv.net/) - Automatic environment loading
- [treefmt-nix](https://github.com/numtide/treefmt-nix) - Multi-formatter orchestration

**Code Quality:**

- [statix](https://github.com/oppiliappan/statix) - Nix linter
- [deadnix](https://github.com/astro/deadnix) - Dead code detection
- [nixfmt](https://github.com/NixOS/nixfmt) - Official formatter

**Monitoring:**

- [Grafana Dashboards](https://grafana.com/grafana/dashboards/) - Pre-built dashboards
- [Prometheus Exporters](https://prometheus.io/docs/instrumenting/exporters/) - Metrics collection

**Backups:**

- [Restic](https://restic.net/) - Modern backup tool
- [Borg](https://www.borgbackup.org/) - Deduplicating archiver

### Performance

- [nix-fast-build](https://github.com/Mic92/nix-fast-build) - Parallel evaluation
- [Nix parallel evaluation](https://determinate.systems/blog/parallel-nix-eval/) - Background info
- [Storage optimization](https://wiki.nixos.org/wiki/Storage_optimization) - Disk space tips

### Example Configurations

- [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs) - Templates
- [wimpysworld/nix-config](https://github.com/wimpysworld/nix-config) - Cross-platform setup
- [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config) - Simple practices

---

## Appendix: Search Query List

For reference, here are all 40 queries that were searched:

### Best Practices & Antipatterns

1. NixOS best practices 2025 flakes module system
2. NixOS antipatterns to avoid 2025 with pkgs
3. modern NixOS configuration patterns 2026
4. NixOS avoiding overengineering personal configuration
5. NixOS module abstraction when to use lib functions

### Theme System

6. NixOS theme management best practices stylix vs custom
7. stylix NixOS automatic theming all applications 2025
8. NixOS home-manager theming without overengineering
9. base16 theming NixOS modern approaches

### Performance

10. NixOS build performance optimization flakes eval time
11. NixOS evaluation performance lazy loading modules
12. nixos-rebuild switch speed improvements cachix
13. NixOS reducing closure size optimization techniques
14. NixOS parallel builds optimization nix.conf settings 2025

### Gaming/Streaming

15. NixOS gaming optimization 2025 Sunshine streaming
16. NixOS Sunshine HDR support VRR configuration
17. NixOS VR OpenComposite WiVRn best practices
18. NixOS Wayland gaming performance optimization NVIDIA AMD
19. NixOS audio latency optimization gaming streaming

### Media Server

20. NixOS arr services best practices 2025 podman systemd
21. NixOS qBittorrent ProtonVPN NAT-PMP automation improvements
22. NixOS Syncthing configuration best practices hardening
23. NixOS container management Podman vs Docker 2025

### VPN & Networking

24. NixOS ProtonVPN split tunneling configuration 2025
25. NixOS firewall nftables configuration containers
26. NixOS network namespaces per-application VPN

### Development Workflow

27. NixOS development workflow devenv vs direnv vs nix-shell 2025
28. NixOS treefmt nixfmt vs alejandra 2025

### Cross-Platform

29. nix-darwin NixOS shared configuration patterns 2025
30. NixOS Darwin cross-platform flake structure best practices

### Package Management

31. NixOS home-manager vs NixOS system packages when to use which
32. NixOS flake inputs optimization update strategies 2025
33. NixOS overlay vs packageOverrides vs overrideAttrs 2025

### Tools

34. NixOS helix editor LSP configuration 2025
35. NixOS nil vs nixd language server comparison
36. NixOS MCP servers best practices Claude Cursor integration
37. Statix linter Nix code quality automation 2025

### Infrastructure

38. NixOS system monitoring prometheus grafana home server
39. NixOS backup strategies restic borg configuration
40. NixOS module placement system vs home-manager antipatterns

---

**Document Generated:** January 8, 2026
**Based on:** 40 web searches covering NixOS best practices, tools, and community recommendations from 2025-2026
**Next Review:** Quarterly or when major NixOS releases occur
