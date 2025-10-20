# Shared feature defaults for all hosts
# Hosts can import this set and override only host-specific toggles
{
  development = {
    enable = true;
    rust = true;
    python = true;
    go = true;
    node = true;
    lua = false;
    docker = false;
  };

  gaming = {
    enable = false;
    steam = false;
    lutris = false;
    emulators = false;
    performance = false;
  };

  virtualisation = {
    enable = false;
    docker = false;
    podman = false;
    qemu = false;
    virtualbox = false;
  };

  homeServer = {
    enable = false;
    homeAssistant = false;
    mediaServer = false;
    fileSharing = false;
    backups = false;
  };

  # Legacy container services (deprecated - use native modules instead)
  containers = {
    enable = false;
    mediaManagement = {
      enable = false;
      dataPath = "/mnt/storage";
      configPath = "/var/lib/containers/media-management";
    };
    productivity = {
      enable = false;
      configPath = "/var/lib/containers/productivity";
    };
  };

  # Native media management services (preferred)
  mediaManagement = {
    enable = false;
    dataPath = "/mnt/storage";
    timezone = "Europe/London";
    # Individual service toggles - all default to true when mediaManagement.enable = true
    prowlarr = {enable = true;};
    radarr = {enable = true;};
    sonarr = {enable = true;};
    lidarr = {enable = true;};
    readarr = {enable = true;};
    whisparr = {enable = false;};
    qbittorrent = {enable = true;};
    sabnzbd = {enable = true;};
    jellyfin = {enable = true;};
    jellyseerr = {enable = true;};
    flaresolverr = {enable = true;};
    unpackerr = {enable = true;};
  };

  # Native AI tools services (Ollama, Open WebUI)
  aiTools = {
    enable = false;
    ollama = {
      enable = true;
      acceleration = null; # null, "cuda", or "rocm"
      models = []; # e.g. ["llama2" "mistral"]
    };
    openWebui = {
      enable = true;
      port = 7000;
    };
  };

  # Supplemental container services (no native modules available)
  containersSupplemental = {
    enable = false;
    homarr = {enable = true;};
    wizarr = {enable = true;};
    doplarr = {enable = false;};
    comfyui = {enable = false;};
    calcom = {enable = false;};
  };

  desktop = {
    enable = true;
    niri = false;
    hyprland = false;
    theming = true;
    utilities = false;
  };

  restic = {
    enable = false;
    backups = {};
    restServer = {
      enable = false;
      port = 8000;
      extraFlags = [];
      htpasswdFile = null;
    };
  };

  productivity = {
    enable = false;
    office = false;
    notes = false;
    email = false;
    calendar = false;
  };

  audio = {
    enable = false;
    production = false;
    realtime = false;
    streaming = false;
    # Audio.nix packages (polygon/audio.nix)
    audioNix = {
      enable = false;
      bitwig = true; # Bitwig Studio (latest beta)
      plugins = true; # Install all available plugins
    };
  };

  security = {
    enable = true;
    yubikey = true;
    gpg = true;
    vpn = false;
    firewall = false;
  };
}
