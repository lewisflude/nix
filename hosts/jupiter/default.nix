{
  username = "lewis";
  useremail = "lewis@lewisflude.com";
  system = "x86_64-linux";
  hostname = "jupiter";

  features = {
    development = {
      lua = true;
      # Moved to devShells to reduce system size (~2-4GB savings)
      # Use: nix develop .#rust or direnv with .envrc
      rust = false; # Use: nix develop .#rust
      python = false; # Use: nix develop .#python
      node = false; # Use: nix develop .#node
    };

    gaming = {
      enable = true;
      steam = true;
      performance = true;
    };

    virtualisation = {
      enable = true;
      podman = true;
    };

    homeServer = {
      enable = true;
      fileSharing = true;
    };

    desktop = {
      niri = true;
      utilities = true;
    };

    restic = {
      enable = true;
      restServer.enable = true;
    };

    media = {
      enable = true;

      audio = {
        enable = true;
        realtime = true;
      };
    };

    productivity = {
      enable = true;
      notes = true;
      email = true;
      calendar = true;
    };

    mediaManagement = {
      enable = true;

      unpackerr.enable = false;
      listenarr.enable = true;

      qbittorrent = {
        enable = true;

        # IP Protocol: Use IPv4 only (IPv6 port forwarding not supported by ProtonVPN NAT-PMP)
        ipProtocol = "IPv4";

        # Storage optimization: SSD for incomplete downloads, HDD for final storage
        incompleteDownloadPath = "/mnt/nvme/qbittorrent/incomplete";
        diskCacheSize = 512; # MiB - Optimized for SSD write protection and 64GB RAM
        maxActiveTorrents = 150; # Reduced from 200 to avoid HDD saturation with Jellyfin
        maxActiveUploads = 75; # Reduced to prevent HDD thrashing during streaming
        maxUploads = 300; # Increased from 150 for better slot allocation across torrents
        maxUploadsPerTorrent = 10; # Increased from 5 for improved seed ratio
        # Upload speed limit: 80% of upload capacity through VPN
        # Measured VPN upload speed: 82.16 Mbit/s = 10,270 KB/s (tested via: sudo ip netns exec qbt speedtest-cli --simple)
        # 80% of measured VPN upload = 8,216 KB/s (leaves 20% headroom for ACKs and resend requests)
        uploadSpeedLimit = 8216; # KB/s - 80% of measured VPN upload (82.16 Mbit/s)

        # Automatic torrent management
        autoTMMEnabled = true;
        defaultSavePath = "/mnt/storage/torrents";
        maxRatio = 3.0;
        maxRatioAction = 0; # 0 = pause torrent when ratio reached

        # Torrent behavior settings
        addToTopOfQueue = true;
        preallocation = true;
        addExtensionToIncompleteFiles = true;
        useCategoryPathsInManualMode = true;
        deleteTorrentFilesAfterwards = "Always";

        # VPN Configuration
        vpn = {
          enable = true;
          namespace = "qbt";
          torrentPort = 62000; # Will be updated by NAT-PMP
          webUIBindAddress = "*"; # Accessible from any interface
        };

        # WebUI Configuration
        webUI = {
          port = 8080;
          bindAddress = "*"; # Accessible from any interface (192.168.1.210:8080)
          username = "lewis";
          password = "@ByteArray(J5lri+TddZR2AJqNVPndng==:no5T50n4CD9peISk6jZQ+Cb8qzv6DoV2MtOxE2oErywXVFngVDq/eySGpoNjUCFOHFdbifjwwHI4jlV2LH4ocQ==)";
          alternativeUIEnabled = true;
          # rootFolder will default to vuetorrent package path when alternativeUIEnabled is true
        };

        # Category Mappings (final download destinations on HDD)
        categories = {
          radarr = "/mnt/storage/movies";
          sonarr = "/mnt/storage/tv";
          lidarr = "/mnt/storage/music";
          readarr = "/mnt/storage/books";
          listenarr = "/mnt/storage/audiobooks";
          pc = "/mnt/storage/pc";
          movies = "/mnt/storage/movies";
          tv = "/mnt/storage/tv";
        };
      };
    };

    aiTools = {
      enable = true;
      ollama = {
        acceleration = "cuda";
        models = [ "llama2" ];
      };
      openWebui.enable = false;
    };

    containersSupplemental = {
      enable = true;
      uid = 985;
      gid = 976;
      jellystat.enable = true;
      termix = {
        enable = true;
        port = 8083;
      };

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

      cleanuparr = {
        enable = true;
        dataPath = "/mnt/storage";
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
