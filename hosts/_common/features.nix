{
  development = {
    enable = true;
    git = true;
    neovim = false;
    rust = true;
    python = true;
    go = false;
    node = true;
    lua = false;
    docker = false;
    java = false;
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

  mediaManagement = {
    enable = false;
    dataPath = "/mnt/storage";
    timezone = "Europe/London";

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

  aiTools = {
    enable = false;
    ollama = {
      enable = true;
      acceleration = null;
      models = [ ];
    };
    openWebui = {
      enable = true;
      port = 7000;
    };
  };

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
    profilarr = {
      enable = true;
    };
  };

  desktop = {
    enable = true;
    niri = false;
    hyprland = false;
    theming = true;
    utilities = false;

    # Signal OKLCH color theme
    signalTheme = {
      enable = true;
      mode = "dark"; # Change to "light" if you prefer light mode
    };
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

  media = {
    enable = false;

    audio = {
      enable = false;
      realtime = false;
      production = false;

      audioNix = {
        enable = false;
        bitwig = true;
        plugins = true;
      };
    };
  };

  security = {
    enable = true;
    yubikey = true;
    gpg = true;

  };
}
