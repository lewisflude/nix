let
  defaultFeatures = import ../_common/features.nix;
in
{

  username = "lewis";
  useremail = "lewis@lewisflude.com";
  system = "x86_64-linux";
  hostname = "jupiter";

  features = defaultFeatures // {
    development = defaultFeatures.development // {
      docker = true;
      lua = true;
      # Moved to devShells to reduce system size (~2-4GB savings)
      # Use: nix develop .#rust or direnv with .envrc
      rust = false; # Use: nix develop .#rust
      python = false; # Use: nix develop .#python
      node = false; # Use: nix develop .#node
    };

    gaming = defaultFeatures.gaming // {
      enable = true;
      steam = true;
      performance = true;
    };

    virtualisation = defaultFeatures.virtualisation // {
      enable = true;
      docker = true;
      podman = true;
    };

    homeServer = defaultFeatures.homeServer // {
      enable = true;
      fileSharing = true;
    };

    desktop = defaultFeatures.desktop // {
      niri = true;
      utilities = true;
    };

    restic = defaultFeatures.restic // {
      enable = true;
      restServer = defaultFeatures.restic.restServer // {
        enable = true;
        port = 8000;
      };
    };

    media = defaultFeatures.media // {
      enable = true;

      audio = defaultFeatures.media.audio // {
        enable = true;
        realtime = true;
        production = false;
        audioNix = {
          enable = false;
          bitwig = true;
          plugins = true;
        };
      };
    };

    productivity = defaultFeatures.productivity // {
      enable = true;
      office = false; # Disabled: LibreOffice (~1.3GB) - not needed
      notes = true;
      email = true;
      calendar = true;
      resume = false;
    };

    mediaManagement = defaultFeatures.mediaManagement // {
      enable = true;
      dataPath = "/mnt/storage";
      timezone = "Europe/London";

      unpackerr.enable = false;

      qbittorrent = {
        enable = true;
        webUI = {
          address = "*";
          username = "lewis";

          password = "@ByteArray(J5lri+TddZR2AJqNVPndng==:no5T50n4CD9peISk6jZQ+Cb8qzv6DoV2MtOxE2oErywXVFngVDq/eySGpoNjUCFOHFdbifjwwHI4jlV2LH4ocQ==)";
        };

        categories = {
          radarr = "/mnt/storage/movies";
          sonarr = "/mnt/storage/tv";
          lidarr = "/mnt/storage/music";
          readarr = "/mnt/storage/books";
        };

        bittorrent = {
          protocol = "TCP"; # TCP is preferred for VPN - more reliable than UTP over VPN tunnels
          queueingEnabled = true;
          maxActiveCheckingTorrents = 3; # Increased from 1 - allows faster torrent checking if storage is fast
          maxActiveUploads = 0; # 0 = Infinite
          maxActiveTorrents = 0; # 0 = Infinite
          diskCacheSize = 2048; # Disk cache in MB (2GB - optimal for high-speed downloads)
          # Note: Changed from -1 (OS cache) to explicit size because -1 was showing 0 B buffer
          # This ensures qBittorrent actually uses the cache for better I/O performance
          maxConnections = 2000; # Global maximum number of connections (optimal for most systems)
          maxConnectionsPerTorrent = 200; # Maximum number of connections per torrent (good balance)
          maxUploads = 200; # Global maximum number of upload slots
          maxUploadsPerTorrent = 15; # Upload slots per torrent (balanced: 10-20 is optimal for high-speed)
        };

        connection = {
          dhtEnabled = true;
          pexEnabled = true;
        };

        bittorrentAdvanced = {
          utpMixedModeAlgorithm = "Prefer TCP";
          uploadSlotsBehavior = "Upload rate based"; # Changed from "Fixed slots" - dynamically allocates slots based on upload speed
          uploadChokingAlgorithm = "Fastest upload";
        };

        vpn = {
          enable = true;

        };
      };
    };

    aiTools = defaultFeatures.aiTools // {
      enable = true;
      ollama = {
        enable = true;
        acceleration = "cuda";
        models = [ "llama2" ];
      };
      openWebui = {
        enable = true;
        port = 7000;
      };
    };

    containersSupplemental = defaultFeatures.containersSupplemental // {
      enable = true;
      uid = 985;
      gid = 976;
      homarr.enable = true;
      wizarr.enable = true;
      doplarr.enable = false;
      comfyui.enable = false;

      janitorr = {
        enable = true;

        extraConfig = {

          clients = {
            sonarr.url = "https://sonarr.blmt.io";
            radarr.url = "https://radarr.blmt.io";
            jellyfin.url = "https://jellyfin.blmt.io";
          };

          application = {

            "dry-run" = false;

            "leaving-soon" = "21d";

            "media-deletion" = {
              enabled = true;

              "movie-expiration" = {
                "5" = "30d";
                "10" = "60d";
                "15" = "120d";
                "20" = "180d";
              };
              "season-expiration" = {
                "5" = "30d";
                "10" = "45d";
                "15" = "90d";
                "20" = "180d";
              };
            };

            "tag-based-deletion" = {
              enabled = true;
              "minimum-free-disk-percent" = 20;
              schedules = [

              ];
            };

            "episode-deletion" = {
              enabled = false;
            };
          };
        };
      };

      calcom = {
        enable = true;
        useSops = true;
        port = 3000;
        webappUrl = "https://cal.blmt.io";

        email = {
          host = "smtp.fastmail.com";
          port = 465;
          from = "lewis@lewisflude.com";
          fromName = "Lewis Flude";
          username = "lewis@lewisflude.com";

        };

        branding = {
          appName = "Lewis Flude";
          companyName = "Lewis Flude";
          supportEmail = "support@lewisflude.com";
        };

        disableSignup = true;
        disableTelemetry = true;
        availabilityInterval = 15;
        logLevel = 3;

        googleCalendar = {
          enabled = true;

        };

      };
    };
  };
}
