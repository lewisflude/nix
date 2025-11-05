# Service-specific feature options
# Defines options for service features: mediaManagement, aiTools, containersSupplemental
{
  lib,
  ...
}:
let
  inherit (lib) mkOption mkEnableOption types;
in
{
  options.host.features = {
    # Native media management services
    mediaManagement = {
      enable = mkEnableOption "native media management services";

      dataPath = mkOption {
        type = types.str;
        default = "/mnt/storage";
        description = "Path to media storage directory";
      };

      timezone = mkOption {
        type = types.str;
        default = "Europe/London";
        description = "Timezone for media services";
      };

      # Individual service enables (all default to service's default when parent is enabled)
      prowlarr = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Prowlarr indexer manager";
        };
      };

      radarr = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Radarr movie management";
        };
      };

      sonarr = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Sonarr TV show management";
        };
      };

      lidarr = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Lidarr music management";
        };
      };

      readarr = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Readarr book management";
        };
      };

      sabnzbd = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable SABnzbd usenet downloader";
        };
      };

      qbittorrent = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable qBittorrent BitTorrent client";
        };

        webUI = {
          address = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "WebUI bind address. Use '*' or '0.0.0.0' to bind to all interfaces. Defaults to '*' when VPN is enabled.";
          };

          username = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "WebUI username.";
          };

          password = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "WebUI password (PBKDF2 hash in @ByteArray format).";
          };
        };

        categories = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = "Category path mappings. Maps category names to their save paths. Example: { movies = \"/mnt/storage/movies\"; tv = \"/mnt/storage/tv\"; }";
          example = {
            movies = "/mnt/storage/movies";
            tv = "/mnt/storage/tv";
            music = "/mnt/storage/music";
          };
        };

        vpn = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable VPN routing via network namespace";
          };

          interfaceName = mkOption {
            type = types.str;
            default = "wg-mullvad";
            description = "WireGuard interface name for VPN routing";
          };

          namespace = mkOption {
            type = types.str;
            default = "wg-qbittorrent";
            description = "Network namespace name for VPN isolation";
          };

          vethHostIP = mkOption {
            type = types.str;
            default = "10.200.200.1/24";
            description = "IP address for veth-host interface";
          };

          vethVPNIP = mkOption {
            type = types.str;
            default = "10.200.200.2/24";
            description = "IP address for veth-vpn interface";
          };
        };
      };

      jellyfin = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Jellyfin media server";
        };
      };

      jellyseerr = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Jellyseerr request management";
        };
      };

      flaresolverr = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable FlareSolverr cloudflare bypass";
        };
      };

      unpackerr = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Unpackerr archive extractor";
        };
      };

      navidrome = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Navidrome music server";
        };
      };
    };

    # Native AI tools services
    aiTools = {
      enable = mkEnableOption "AI tools and LLM services";

      ollama = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Ollama LLM backend";
        };

        acceleration = mkOption {
          type = types.nullOr (
            types.enum [
              "rocm"
              "cuda"
            ]
          );
          default = null;
          description = "GPU acceleration type (null for CPU-only)";
        };

        models = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "List of models to pre-download";
          example = [
            "llama2"
            "mistral"
          ];
        };
      };

      openWebui = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Open WebUI interface for LLMs";
        };

        port = mkOption {
          type = types.port;
          default = 7000;
          description = "Port for Open WebUI";
        };
      };
    };

    # Supplemental container services (no native modules available yet)
    containersSupplemental = {
      enable = mkEnableOption "supplemental container services";

      uid = mkOption {
        type = types.int;
        default = 1000;
        description = "User ID for container processes";
      };

      gid = mkOption {
        type = types.int;
        default = 100;
        description = "Group ID for container processes";
      };

      homarr = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Homarr dashboard";
        };
      };

      wizarr = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Wizarr invitation system";
        };
      };

      janitorr = mkOption {
        type = types.attrsOf types.anything;
        default = {
          enable = true;
        };
        description = "Janitorr media cleanup automation configuration";
      };

      doplarr = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Doplarr Discord bot";
        };
      };

      comfyui = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable ComfyUI AI image generation";
        };
      };

      calcom = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Cal.com scheduling platform";
        };

        port = mkOption {
          type = types.int;
          default = 3000;
          description = "Port to expose Cal.com on";
        };

        webappUrl = mkOption {
          type = types.str;
          default = "http://localhost:3000";
          description = "Public URL for Cal.com (e.g., https://cal.example.com)";
        };

        useSops = mkOption {
          type = types.bool;
          default = false;
          description = "Use sops-nix for Cal.com secrets management";
        };

        nextauthSecret = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "NextAuth secret for Cal.com session encryption";
        };

        calendarEncryptionKey = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Calendar encryption key for Cal.com";
        };

        dbPassword = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "PostgreSQL database password for Cal.com";
        };

        # Email configuration
        email = {
          host = mkOption {
            type = types.str;
            default = "localhost";
            description = "SMTP server host for sending emails";
          };

          port = mkOption {
            type = types.int;
            default = 587;
            description = "SMTP server port (587 for STARTTLS, 465 for SSL)";
          };

          from = mkOption {
            type = types.str;
            default = "noreply@localhost";
            description = "Email address to send emails from";
          };

          fromName = mkOption {
            type = types.str;
            default = "Cal.com";
            description = "Display name for outgoing emails";
          };

          username = mkOption {
            type = types.str;
            default = "";
            description = "SMTP authentication username";
          };

          password = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "SMTP authentication password (only used if useSops is false)";
          };
        };

        # Branding configuration
        branding = {
          appName = mkOption {
            type = types.str;
            default = "Cal.com";
            description = "Application name shown in the interface";
          };

          companyName = mkOption {
            type = types.str;
            default = "Cal.com, Inc.";
            description = "Company name for legal/footer information";
          };

          supportEmail = mkOption {
            type = types.str;
            default = "help@cal.com";
            description = "Support email address for user assistance";
          };
        };

        # General settings
        disableSignup = mkOption {
          type = types.bool;
          default = true;
          description = "Disable public user registration (recommended for personal use)";
        };

        disableTelemetry = mkOption {
          type = types.bool;
          default = true;
          description = "Disable anonymous usage telemetry";
        };

        availabilityInterval = mkOption {
          type = types.nullOr types.int;
          default = 15;
          description = "Time slot interval in minutes for availability scheduling";
        };

        logLevel = mkOption {
          type = types.int;
          default = 3;
          description = "Logging level (0=silly, 1=trace, 2=debug, 3=info, 4=warn, 5=error, 6=fatal)";
        };

        cronApiKey = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "API key for cron jobs";
        };

        serviceAccountEncryptionKey = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Encryption key for service account credentials";
        };

        # Google Calendar integration
        googleCalendar = {
          enabled = mkOption {
            type = types.bool;
            default = false;
            description = "Enable Google Calendar integration and Login with Google";
          };

          credentials = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Google API credentials JSON string";
          };
        };
      };
    };
  };
}
