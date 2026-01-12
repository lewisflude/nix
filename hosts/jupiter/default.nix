{
  username = "lewis";
  useremail = "lewis@lewisflude.com";
  system = "x86_64-linux";
  hostname = "jupiter";

  # Hardware configuration
  hardware = {
    gpuID = "10de:2684"; # RTX 4090
  };

  features = {
    security = {
      enable = true;
      yubikey = true;
      fail2ban = true;
    };

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
      lutris = true;
    };

    vr = {
      enable = true;
      alvr = false; # ALVR requires SteamVR - use WiVRn for Monado instead
      monado = true;
      wivrn = {
        enable = true;
        autoStart = true; # Start automatically for convenience
        defaultRuntime = true; # WiVRn manages Monado runtime
        openFirewall = true;
      };
      immersed = {
        enable = false; # Temporarily disabled due to onetbb i686 test failures
        openFirewall = true;
      };
      opencomposite = true; # Required for running OpenVR games on Monado (Wayland)
      steamvr = false; # Not needed on Wayland - Monado replaces SteamVR
      sidequest = true;
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

        # Real-time audio with RT kernel and musnix optimizations
        # Disabled due to RT kernel build issues with GPU drivers
        # XanMod provides excellent low-latency for gaming and general audio
        # Re-enable when needed for professional audio recording
        realtime = false;

        # Professional audio configuration for Apogee Symphony Desktop
        # Ultra-low latency: 64 frames @ 48kHz = ~1.3ms (for recording/monitoring)
        # Set to false for general use (256 frames = ~5.3ms)
        ultraLowLatency = false;

        # USB audio interface optimizations
        usbAudioInterface = {
          enable = true;
          # PCI ID of USB controller (not the Apogee device itself)
          # Intel Raptor Lake USB 3.2 Gen 2x2 XHCI Host Controller
          pciId = "00:14.0";
        };

        # musnix tools and features
        rtirq = true; # IRQ priority management (prioritizes USB + sound)
        dasWatchdog = true; # Safety: kills runaway RT processes
        rtcqs = true; # Install rtcqs analysis tool (run: rtcqs)

        # audio.nix flake packages (Bitwig Studio and plugins)
        # Temporarily disabling due to webkitgtk compatibility issue
        audioNix = {
          enable = false;
          bitwig = false;
          plugins = false;
        };
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

        # Storage optimization: NVMe (ZFS root pool) for incomplete downloads, HDD for final storage
        incompleteDownloadPath = "/var/lib/qbittorrent/incomplete";
        diskCacheSize = 4096; # MiB - 4GB cache for high-performance with 64GB RAM system

        # OPTIMIZED SETTINGS (balanced for stability and performance)
        # Based on 8,216 KB/s upload via VPN, but tuned to prevent packet drops
        # Upload speed: 8,216 KB/s (82.16 Mbit/s measured via VPN)
        # Priority: Stability with good performance
        uploadSpeedLimit = 8216; # KB/s - 80% of measured VPN upload (leaves 20% for ACKs)

        # Connection settings (reduced to prevent WireGuard interface overload)
        maxConnections = 300; # Global max connections (reduced from 600 for stability)
        maxConnectionsPerTorrent = 100; # Peer diversity maintained

        # Upload slot optimization (balanced for concurrent seeding without bursts)
        maxUploads = 200; # Upload slots - reduced from 1643 to prevent traffic bursts
        maxUploadsPerTorrent = 10; # Per-torrent slots (optimal)

        # Active torrent limits (balanced for performance without overwhelming interface)
        maxActiveTorrents = 150; # Reduced from 547 to prevent HDD thrashing
        maxActiveDownloads = 5; # Concurrent downloads (5 for faster grabbing, 3 for HDD protection)
        maxActiveUploads = 50; # Reduced from 273 to prevent packet drops

        # Automatic torrent management
        autoTMMEnabled = true;
        defaultSavePath = "/mnt/storage/torrents";

        # Share limits (ratio and seeding time)
        maxRatio = 3.0;
        maxInactiveSeedingTime = 43200; # 30 days in minutes (43200 = 30 * 24 * 60)
        shareLimitAction = "Stop"; # Pause torrent when limits reached

        # Slow torrent handling (private tracker settings - more aggressive)
        # These torrents don't count against active limits if below thresholds
        slowTorrentsDownloadRate = 10; # KiB/s - private tracker setting (default: 5)
        slowTorrentsUploadRate = 10; # KiB/s - private tracker setting (default: 5)
        slowTorrentsInactivityTimer = 30; # seconds - private tracker setting (default: 60)

        # Torrent behavior settings
        # Note: addToTopOfQueue, addExtensionToIncompleteFiles, and useCategoryPathsInManualMode
        # are now enabled by default in the module, so explicit settings are optional
        deleteTorrentFilesAfterwards = "Always";

        # Preallocation disabled for ZFS (prevents fragmentation and double-writes)
        preallocation = false;

        # VPN Configuration
        vpn = {
          enable = true;
          namespace = "qbt";
          torrentPort = 62000; # Initial placeholder - dynamically updated by protonvpn-portforward.service every 45s
          webUIBindAddress = "*"; # Accessible from any interface
        };

        # WebUI Configuration
        webUI = {
          port = 8080;
          bindAddress = "*"; # Accessible from any interface (192.168.10.210:8080)
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

      transmission = {
        enable = true;

        authentication = {
          enable = true;
          useSops = true;
        };

        downloadDir = "/mnt/storage/torrents";
        incompleteDir = "/var/lib/transmission/incomplete";

        # Run on host network (not VPN) since ProtonVPN only forwards one port
        # qBittorrent gets the forwarded port and VPN, Transmission runs directly
        peerPort = 51413; # Default Transmission port

        vpn = {
          enable = false; # Run on host network, not VPN
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
