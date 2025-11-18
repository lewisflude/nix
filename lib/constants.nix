# Constants and magic numbers used throughout the configuration
# This file centralizes hardcoded values for better maintainability
{
  # MCP (Model Context Protocol) Server Ports
  # Port range: 6200-6299 reserved for MCP servers
  ports = {
    mcp = {
      # Core MCP servers
      github = 6230;
      git = 6233;
      kagi = 6240;
      openai = 6250;
      docs = 6280;
      rustdocs = 6270;
      fetch = 6260;
      nixos = 6265;

      # Platform-specific ports (avoid conflicts between Darwin and NixOS)
      time-nixos = 6262;
      time-darwin = 6263;
      sequential-thinking-nixos = 6281;
      sequential-thinking-darwin = 6282;
      filesystem = 6220;
      memory = 6221;
      everything = 6222;
    };

    # System services
    services = {
      restic = 8000;
      ollama = 11434;
      openWebui = 7000;
      cockpit = 9090;
      dante = 1080; # SOCKS proxy

      # Media management services
      jellyfin = 8096;
      jellyseerr = 5055;
      sonarr = 8989;
      radarr = 7878;
      lidarr = 8686;
      readarr = 8787;
      prowlarr = 9696;
      qbittorrent = 8080;
      sabnzbd = 8082;
      navidrome = 4533;
      flaresolverr = 8191;

      # Container supplemental services
      homarr = 7575;
      wizarr = 5690;
      jellystat = 3000; # Note: Conflicts with calcom, use host-specific override
      termix = 8083;
      doplarr = 3142;
      comfyui = 8188;
      janitorr = 8485;
      profilarr = 3001;
      cleanuparr = 11011;

      # Productivity
      calcom = 3000; # Note: Conflicts with jellystat
    };
  };

  # Timeouts (in milliseconds as strings for shell scripts)
  timeouts = {
    mcp = {
      registration = "60000"; # 60 seconds
      warmup = "900"; # 15 minutes
      default = "60000";
    };

    service = {
      start = "300"; # 5 minutes
      stop = "90"; # 90 seconds
      restart = "30"; # 30 seconds
    };
  };

  # Common paths
  paths = {
    # Data directories (platform-agnostic, use with platformLib)
    sopsKeyDir = {
      linux = "/var/lib/sops-nix";
      darwin = "sops-nix"; # Relative to Application Support
    };

    # Common storage paths
    mediaStorage = "/mnt/storage";
    backupStorage = "/mnt/backups";
  };

  # Resource limits
  resources = {
    # Container defaults
    container = {
      memoryLimit = "512m";
      cpuShares = 1024;
    };

    # Service-specific limits
    ollama = {
      gpuLayers = 35; # Number of layers to offload to GPU
    };
  };

  # Network configuration
  network = {
    # Subnet ranges for various purposes
    docker = "172.17.0.0/16";
    podman = "10.88.0.0/16";

    # DNS servers
    dns = {
      cloudflare = [
        "1.1.1.1"
        "1.0.0.1"
      ];
      google = [
        "8.8.8.8"
        "8.8.4.4"
      ];
    };
  };

  # Feature flag defaults
  defaults = {
    timezone = "Europe/London";
    locale = "en_GB.UTF-8";
    stateVersion = "25.05"; # NixOS state version
    darwinStateVersion = 6; # nix-darwin state version
  };

  # User/Group IDs for services
  ids = {
    media = {
      uid = 985;
      gid = 976;
    };
    containers = {
      uid = 985;
      gid = 976;
    };
  };
}
