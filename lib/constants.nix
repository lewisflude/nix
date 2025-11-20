# Constants for widely-used configuration values
# Only includes values used in multiple places across the configuration
{
  # Service ports - centralized to avoid conflicts
  # Port range: 6200-6299 reserved for MCP servers
  ports = {
    mcp = {
      github = 6230;
      git = 6233;
      kagi = 6240;
      openai = 6250;
      docs = 6280;
      rustdocs = 6270;
      fetch = 6260;
      nixos = 6265;
      time-nixos = 6262;
      time-darwin = 6263;
      sequential-thinking-nixos = 6281;
      sequential-thinking-darwin = 6282;
      filesystem = 6220;
      memory = 6221;
      everything = 6222;
    };

    services = {
      restic = 8000;
      ollama = 11434;
      openWebui = 7000;
      cockpit = 9090;
      dante = 1080;

      # Media management services
      jellyfin = 8096;
      jellyseerr = 5055;
      sonarr = 8989;
      radarr = 7878;
      lidarr = 8686;
      readarr = 8787;
      listenarr = 5000;
      prowlarr = 9696;
      qbittorrent = 8080;
      sabnzbd = 8082;
      navidrome = 4533;
      flaresolverr = 8191;

      # Container supplemental services
      homarr = 7575;
      wizarr = 5690;
      jellystat = 3000;
      termix = 8083;
      doplarr = 3142;
      comfyui = 8188;
      janitorr = 8485;
      profilarr = 3001;
      cleanuparr = 11011;
      calcom = 3000;
    };
  };

  # Timeouts for MCP and services (in seconds as strings for systemd)
  timeouts = {
    mcp = {
      registration = "60000"; # 60 seconds (milliseconds for compatibility)
      warmup = "900"; # 15 minutes
      default = "60000";
    };
    service = {
      start = "300"; # 5 minutes
      stop = "90"; # 90 seconds
      restart = "30"; # 30 seconds
    };
  };

  # Common default values
  defaults = {
    timezone = "Europe/London";
    locale = "en_GB.UTF-8";
    stateVersion = "25.05";
    darwinStateVersion = 6;
  };

  # Host IP addresses (for services that need explicit IPs)
  hosts = {
    jupiter = {
      ipv4 = "192.168.1.210";
    };
  };
}
