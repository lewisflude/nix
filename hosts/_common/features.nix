# Shared feature defaults for all hosts
# Hosts can import this set and override only host-specific toggles
{
  development = {
    enable = true;
    git = true; # Required for rust development
    neovim = false;
    rust = true;
    python = true;
    go = true;
    node = true;
    lua = false;
    docker = false;
    java = false; # Override to true if Java is needed
  };

  gaming = {
    enable = false;
    steam = false;
    performance = false;
  };

  virtualisation = {
    enable = false;
    docker = false;
    podman = false;
  };

  homeServer = {
    enable = false;
    fileSharing = false;
  };

  # Native media management services (preferred)
  mediaManagement = {
    enable = false;
    dataPath = "/mnt/storage";
    timezone = "Europe/London";
    # Individual service toggles - all default to true when mediaManagement.enable = true
    prowlarr = {
      enable = true;
    };
    radarr = {
      enable = true;
    };
    sonarr = {
      enable = true;
    };
    lidarr = {
      enable = true;
    };
    readarr = {
      enable = true;
    };
    sabnzbd = {
      enable = true;
    };
    qbittorrent = {
      enable = true;
    };
    jellyfin = {
      enable = true;
    };
    jellyseerr = {
      enable = true;
    };
    flaresolverr = {
      enable = true;
    };
    unpackerr = {
      enable = true;
    };
    navidrome = {
      enable = true;
    };
  };

  # Native AI tools services (Ollama, Open WebUI)
  aiTools = {
    enable = false;
    ollama = {
      enable = true;
      acceleration = null; # null, "cuda", or "rocm"
      models = [ ]; # e.g. ["llama2" "mistral"]
    };
    openWebui = {
      enable = true;
      port = 7000;
    };
  };

  # Supplemental container services (no native modules available)
  containersSupplemental = {
    enable = false;
    homarr = {
      enable = true;
    };
    wizarr = {
      enable = true;
    };
    janitorr = {
      enable = true;
    };
    doplarr = {
      enable = false;
    };
    comfyui = {
      enable = false;
    };
    calcom = {
      enable = false;
    };
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
    backups = { };
    restServer = {
      enable = false;
      port = 8000;
      extraFlags = [ ];
      htpasswdFile = null;
    };
  };

  productivity = {
    enable = false;
    notes = false;
    resume = false;
    office = false;
    email = false;
    calendar = false;
  };

  audio = {
    enable = false;
    realtime = false;
    production = false;
    # Audio.nix packages (polygon/audio.nix)
    audioNix = {
      enable = false;
      bitwig = true; # Bitwig Studio (latest beta) - only used if audioNix.enable = true
      plugins = true; # Install all available plugins - only used if audioNix.enable = true
    };
  };

  security = {
    enable = true;
    yubikey = true;
    gpg = true;
    # firewall defaults to false
  };
}
