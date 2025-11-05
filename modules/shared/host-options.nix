# Host configuration options with type safety
# Defines a proper module options interface for host-specific configuration
{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkOption mkEnableOption types;
in
{
  options.host = {
    username = mkOption {
      type = types.str;
      description = "Primary user's username";
      example = "lewis";
    };

    useremail = mkOption {
      type = types.str;
      description = "Primary user's email address";
      example = "lewis@example.com";
    };

    hostname = mkOption {
      type = types.str;
      description = "System hostname";
      example = "jupiter";
    };

    system = mkOption {
      type = types.str;
      description = "System architecture (e.g., x86_64-linux, aarch64-darwin)";
      example = "x86_64-linux";
    };

    features = {
      development = {
        enable = mkEnableOption "development tools and environments";

        # Language sub-features
        rust = mkEnableOption "Rust development environment";
        python = mkEnableOption "Python development environment";
        go = mkEnableOption "Go development environment";
        node = mkEnableOption "Node.js/TypeScript development";
        lua = mkEnableOption "Lua development environment";
        java = mkEnableOption "Java development environment";
        nix = mkEnableOption "Nix development tools";

        # Tool sub-features
        docker = mkEnableOption "Docker and containerization";
        kubernetes = mkEnableOption "Kubernetes and container orchestration";
        git = mkEnableOption "Git and version control tools";
        buildTools = mkEnableOption "Build tools (make, cmake, pkg-config, etc.)";

        # Editor sub-features
        vscode = mkEnableOption "VS Code editor";
        helix = mkEnableOption "Helix editor";
        neovim = mkEnableOption "Neovim editor";
      };

      gaming = {
        enable = mkEnableOption "gaming platforms and optimizations";
        steam = mkEnableOption "Steam gaming platform";
        lutris = mkEnableOption "Lutris game manager";
        emulators = mkEnableOption "game console emulators";
        performance = mkEnableOption "gaming performance optimizations";
      };

      virtualisation = {
        enable = mkEnableOption "virtual machines and containers";
        docker = mkEnableOption "Docker containers";
        podman = mkEnableOption "Podman containers";
        qemu = mkEnableOption "QEMU virtual machines";
        virtualbox = mkEnableOption "VirtualBox VMs";
      };

      homeServer = {
        enable = mkEnableOption "home server and self-hosting";
        homeAssistant = mkEnableOption "Home Assistant smart home";
        mediaServer = mkEnableOption "Plex/Jellyfin media server";
        fileSharing = mkEnableOption "Samba/NFS file sharing";
        backups = mkEnableOption "automated backup systems";
      };

      desktop = {
        enable = mkEnableOption "desktop environment and customization";
        niri = mkEnableOption "Niri Wayland compositor";
        hyprland = mkEnableOption "Hyprland Wayland compositor";
        theming = mkEnableOption "system-wide theming";
        utilities = mkEnableOption "desktop utilities";
      };

      restic = {
        enable = mkEnableOption "Restic backup integration";

        backups = mkOption {
          type = types.attrsOf (
            types.submodule (_: {
              options = {
                enable = mkEnableOption "Enable this Restic backup job";
                path = mkOption {
                  type = types.str;
                  description = "Path to back up.";
                };
                repository = mkOption {
                  type = types.str;
                  description = "Restic repository URL.";
                };
                passwordFile = mkOption {
                  type = types.str;
                  description = "Path to the file containing the repository password.";
                };
                timer = mkOption {
                  type = types.str;
                  default = "daily";
                  description = "Timer specification for the backup job (e.g., 'daily').";
                };
                user = mkOption {
                  type = types.str;
                  default = "root";
                  description = "User account that owns the backup job.";
                };
                extraOptions = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                  description = "Additional CLI options passed to restic.";
                };
                initialize = mkOption {
                  type = types.bool;
                  default = false;
                  description = "Initialise the repository if it does not yet exist.";
                };
                createWrapper = mkOption {
                  type = types.bool;
                  default = false;
                  description = "Create a security wrapper for restic to access protected paths.";
                };
              };
            })
          );
          default = { };
          description = "Per-backup job configuration for Restic.";
        };

        restServer = {
          enable = mkEnableOption "Restic REST server";
          port = mkOption {
            type = types.int;
            default = 8000;
            description = "Port the Restic REST server listens on.";
          };
          extraFlags = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Additional flags for restic-rest-server.";
          };
          htpasswdFile = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Path to an htpasswd file for server authentication.";
          };
        };
      };

      productivity = {
        enable = mkEnableOption "productivity and office tools";
        office = mkEnableOption "LibreOffice suite";
        notes = mkEnableOption "note-taking (Obsidian)";
        email = mkEnableOption "email clients";
        calendar = mkEnableOption "calendar applications";
        resume = mkEnableOption "resume generation and management";
      };

      # Media production feature (audio, video, streaming)
      media = {
        enable = mkEnableOption "media production tools and environments";

        # Audio sub-features
        audio = {
          enable = mkEnableOption "audio production and music";
          production = mkEnableOption "DAW and audio tools";
          realtime = mkEnableOption "real-time audio optimizations (musnix)";
          streaming = mkEnableOption "audio streaming";

          # Audio.nix packages (from polygon/audio.nix flake)
          audioNix = {
            enable = mkOption {
              type = types.bool;
              default = false;
              description = "Enable audio packages from polygon/audio.nix flake";
            };

            bitwig = mkOption {
              type = types.bool;
              default = true;
              description = "Install Bitwig Studio (latest beta version)";
            };

            plugins = mkOption {
              type = types.bool;
              default = true;
              description = "Install audio plugins from audio.nix (neuralnote, paulxstretch, etc.)";
            };
          };
        };

        # Video sub-features
        video = {
          enable = mkEnableOption "video production and editing";
          editing = mkEnableOption "Video editing tools (Kdenlive, etc.)";
          streaming = mkEnableOption "Video streaming tools (OBS, etc.)";
        };

        # Streaming sub-features
        streaming = {
          enable = mkEnableOption "Streaming and recording tools";
          obs = mkEnableOption "OBS Studio for streaming/recording";
        };
      };

      # Legacy audio feature (deprecated, use host.features.media.audio instead)
      audio = {
        enable = mkEnableOption "audio production and music (deprecated, use host.features.media.audio)";
        production = mkEnableOption "DAW and audio tools";
        realtime = mkEnableOption "real-time audio optimizations";
        streaming = mkEnableOption "audio streaming";

        # Audio.nix packages (from polygon/audio.nix flake)
        audioNix = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable audio packages from polygon/audio.nix flake";
          };

          bitwig = mkOption {
            type = types.bool;
            default = true;
            description = "Install Bitwig Studio (latest beta version)";
          };

          plugins = mkOption {
            type = types.bool;
            default = true;
            description = "Install audio plugins from audio.nix (neuralnote, paulxstretch, etc.)";
          };
        };
      };

      security = {
        enable = mkEnableOption "security and privacy tools";
        yubikey = mkEnableOption "YubiKey hardware support";
        gpg = mkEnableOption "GPG/PGP encryption";
        firewall = mkEnableOption "advanced firewall";
      };

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

    # Legacy virtualisation config for backward compatibility
    virtualisation = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Legacy virtualisation configuration (deprecated, use host.features.virtualisation)";
    };
  };

  config = {
    # Validation assertions
    assertions = [
      {
        assertion = config.host.username != "";
        message = "host.username must be set";
      }
      {
        assertion = config.host.hostname != "";
        message = "host.hostname must be set";
      }
      {
        assertion = builtins.match ".*@.*" config.host.useremail != null;
        message = "host.useremail must be a valid email address";
      }
    ];
  };
}
