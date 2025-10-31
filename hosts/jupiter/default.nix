# NixOS host configuration for Jupiter workstation
let
  defaultFeatures = import ../_common/features.nix;
in {
  # System identification
  username = "lewis";
  useremail = "lewis@lewisflude.com";
  system = "x86_64-linux";
  hostname = "jupiter";

  # Feature configuration
  features =
    defaultFeatures
    // {
      development =
        defaultFeatures.development
        // {
          docker = true;
          lua = true;
        };

      gaming =
        defaultFeatures.gaming
        // {
          enable = true;
          steam = true;
          performance = true;
        };

      virtualisation =
        defaultFeatures.virtualisation
        // {
          enable = true;
          docker = true;
          podman = true;
        };

      homeServer =
        defaultFeatures.homeServer
        // {
          enable = true;
          fileSharing = true;
        };

      desktop =
        defaultFeatures.desktop
        // {
          niri = true;
          utilities = true;
        };

      restic =
        defaultFeatures.restic
        // {
          enable = true;
          restServer =
            defaultFeatures.restic.restServer
            // {
              enable = true;
              port = 8000;
            };
        };

      audio =
        defaultFeatures.audio
        // {
          enable = true;
          realtime = true;
          production = true;
          audioNix = {
            enable = false; # TODO: Temporarily disabled due to webkitgtk dependency issue
            bitwig = true;
            plugins = true;
          };
        };

      productivity =
        defaultFeatures.productivity
        // {
          enable = true;
          office = true;
          notes = true;
          email = true;
          calendar = true;
          resume = true;
        };

      # Native media management services (preferred approach)
      mediaManagement =
        defaultFeatures.mediaManagement
        // {
          enable = true;
          dataPath = "/mnt/storage";
          timezone = "Europe/London";
          qbittorrent = {
            webUiUsername = "lewisflude";
            webUiPasswordHash = "@ByteArray(Cd0EXFF7l5z/Gc30XXcOQQ==:tv4EeaZuKRcqdPssL85j2T1+JGT1ac45CUVysbBrGA2vKRvjR7gECffEgPb5uxHdc4B6Un2CaBAOj4pSA4JH3w==)";
            webUiAuthSubnetWhitelist = [
              "127.0.0.1/32" # localhost
              "192.168.1.0/24" # local network (adjust if your subnet differs)
              "10.0.0.0/8" # private network range
            ];
            categoryPaths = {
              movies = "/mnt/storage/torrents/movies";
              tv = "/mnt/storage/torrents/tv";
            };
            vpn = {
              enable = true;
              addresses = ["10.2.0.2/32"];
              dns = ["10.2.0.1"];
              privateKeySecret = "qbittorrent/vpn/privateKey";
              peers = [
                {
                  publicKey = "YgGdHIXeCQgBc4nXKJ4vct8S0fPqBpTgk4I8gh3uMEg=";
                  endpoint = "185.107.44.110:51820";
                  allowedIPs = [
                    "0.0.0.0/0"
                    "::/0"
                  ];
                  persistentKeepalive = 25;
                }
              ];
            };
          };

          # All services enabled by default except unpackerr
          # To disable specific services, set enable = false
          unpackerr.enable = false; # Disabled - config format issues
        };

      # Native AI tools services (Ollama, Open WebUI)
      aiTools =
        defaultFeatures.aiTools
        // {
          enable = true;
          ollama = {
            enable = true;
            acceleration = "cuda"; # NVIDIA GPU acceleration
            models = ["llama2"]; # Pre-download models on first boot
          };
          openWebui = {
            enable = true;
            port = 7000;
          };
        };

      # Supplemental container services (no native modules available yet)
      containersSupplemental =
        defaultFeatures.containersSupplemental
        // {
          enable = true;
          uid = 985; # media user
          gid = 976; # media group
          homarr.enable = true; # Dashboard
          wizarr.enable = true; # Invitation system
          doplarr.enable = false; # Discord bot (requires secrets)
          comfyui.enable = false; # AI image generation (disabled)

          # Janitorr media cleanup automation
          janitorr = {
            enable = true;

            # Custom configuration for 24TB storage setup
            extraConfig = {
              # Override client URLs to use HTTPS endpoints
              clients = {
                sonarr.url = "https://sonarr.blmt.io";
                radarr.url = "https://radarr.blmt.io";
                jellyfin.url = "https://jellyfin.blmt.io";
              };

              application = {
                # Enable actual deletions (dry-run disabled)
                "dry-run" = false;

                # Conservative settings for large storage
                "leaving-soon" = "21d"; # 3 weeks warning before deletion

                "media-deletion" = {
                  enabled = true;
                  # Longer retention with 24TB storage
                  # Format: rating threshold -> days to keep after last watch
                  "movie-expiration" = {
                    "5" = "30d"; # Low-rated movies (≤5/10): 30 days
                    "10" = "60d"; # Medium-rated (≤10/10): 60 days
                    "15" = "120d"; # Good movies (≤15/10): 120 days
                    "20" = "180d"; # Great movies (≤20/10): 180 days
                  };
                  "season-expiration" = {
                    "5" = "30d"; # Low-rated TV (≤5/10): 30 days
                    "10" = "45d"; # Medium-rated (≤10/10): 45 days
                    "15" = "90d"; # Good TV (≤15/10): 90 days
                    "20" = "180d"; # Great TV (≤20/10): 180 days
                  };
                };

                "tag-based-deletion" = {
                  enabled = true;
                  "minimum-free-disk-percent" = 20; # Trigger when <20% free (~4.8TB remaining)
                  schedules = [
                    # Optional: Add tags in Radarr/Sonarr later for custom retention
                    # Examples you could use:
                    # { tag = "temporary"; expiration = "7d"; }
                    # { tag = "archive"; expiration = "365d"; }
                  ];
                };

                "episode-deletion" = {
                  enabled = false; # Disabled - no daily shows identified
                };
              };
            };
          };

          # Cal.com configuration with sops-nix for secrets
          calcom = {
            enable = true;
            useSops = true; # Use sops-nix for production secrets
            port = 3000; # Internal port
            webappUrl = "https://cal.blmt.io"; # Public domain

            # Email configuration (Fastmail SMTP)
            email = {
              host = "smtp.fastmail.com";
              port = 465; # SSL
              from = "lewis@lewisflude.com";
              fromName = "Lewis Flude";
              username = "lewis@lewisflude.com";
              # password is stored in secrets/secrets.yaml as calcom-email-password
            };

            # Branding
            branding = {
              appName = "Lewis Flude";
              companyName = "Lewis Flude";
              supportEmail = "support@lewisflude.com";
            };

            # General settings
            disableSignup = true; # Personal use only
            disableTelemetry = true; # Privacy
            availabilityInterval = 15; # 15-minute slots
            logLevel = 3; # Info and above

            # Google Calendar integration
            googleCalendar = {
              enabled = true;
              # Credentials stored in secrets/secrets.yaml as calcom-google-credentials
              # Contains OAuth 2.0 client_id and client_secret for Google Calendar API
            };

            # Secrets are stored in secrets/secrets.yaml:
            # - calcom-nextauth-secret (required)
            # - calcom-encryption-key (required)
            # - calcom-db-password (required)
            # - calcom-email-password (required - Fastmail app password)
            # - calcom-cron-api-key (required)
            # - calcom-service-account-key (required)
            # - calcom-google-credentials (required for Google Calendar - JSON string)
            # Run: sops secrets/secrets.yaml to add them
          };
        };
    };
}
