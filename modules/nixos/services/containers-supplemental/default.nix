# Supplemental Container Services
# Services that don't have native NixOS modules yet
# These remain as containers: Homarr, Wizarr, Doplarr, ComfyUI, Cal.com
#
# ⚠️  SECURITY WARNING: SECRETS MANAGEMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Services like Cal.com, Doplarr require secrets (API keys, passwords, etc.)
# This module does NOT provide default secrets for security reasons.
#
# You MUST configure secrets before enabling these services:
# - Cal.com: requires nextauthSecret, calendarEncryptionKey, dbPassword
# - Doplarr: requires discordToken, sonarrApiKey, radarrApiKey
#
# For development: Set secrets directly in your host configuration
# For production: Use sops-nix for encrypted secrets management
#
# See docs/SECRETS-MANAGEMENT.md for detailed implementation guide.
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.services.containersSupplemental;

  commonEnv = {
    PUID = toString cfg.uid;
    PGID = toString cfg.gid;
    TZ = cfg.timezone;
  };

  # Helper to create resource limit options
  mkResourceOptions = defaults: {
    memory = mkOption {
      type = types.str;
      default = defaults.memory or "512m";
      description = "Memory limit for the container (e.g., '512m', '1g')";
      example = "1g";
    };
    cpus = mkOption {
      type = types.str;
      default = defaults.cpus or "1";
      description = "CPU limit for the container (number of CPUs or fraction)";
      example = "2";
    };
    memorySwap = mkOption {
      type = types.nullOr types.str;
      default = defaults.memorySwap or null;
      description = "Memory + swap limit (null means no limit)";
      example = "2g";
    };
  };
in {
  options.host.services.containersSupplemental = {
    enable = mkEnableOption "supplemental container services";

    configPath = mkOption {
      type = types.str;
      default = "/var/lib/containers/supplemental";
      description = "Path to store container configurations";
    };

    timezone = mkOption {
      type = types.str;
      default = "Europe/London";
      description = "Timezone for all containers";
    };

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

    # Individual service enables
    homarr.enable =
      mkEnableOption "Homarr dashboard"
      // {
        default = true;
      };
    wizarr.enable =
      mkEnableOption "Wizarr invitation system"
      // {
        default = true;
      };
    doplarr.enable =
      mkEnableOption "Doplarr Discord bot"
      // {
        default = false;
      };
    comfyui.enable =
      mkEnableOption "ComfyUI NVIDIA"
      // {
        default = false;
      };
    calcom.enable =
      mkEnableOption "Cal.com scheduling platform"
      // {
        default = false;
      };

    # Service-specific configurations

    # Homarr resource limits
    homarr = {
      resources = mkResourceOptions {
        memory = "512m";
        cpus = "0.5";
      };
    };

    # Wizarr resource limits
    wizarr = {
      resources = mkResourceOptions {
        memory = "256m";
        cpus = "0.25";
      };
    };

    # Doplarr Discord bot secrets and resources - REQUIRED when doplarr.enable = true
    doplarr = {
      resources = mkResourceOptions {
        memory = "128m";
        cpus = "0.25";
      };
      discordToken = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          '
                    Discord bot token - REQUIRED for Doplarr.
                    Create a bot at https://discord.com/developers/applications

                    WARNING: Never commit secrets to git. Use sops-nix for production.
                    See docs/SECRETS-MANAGEMENT.md for proper implementation.
        '';
      };
      sonarrApiKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          '
                    Sonarr API key - REQUIRED for Doplarr.
                    Find in Sonarr: Settings → General → Security → API Key

                    WARNING: Never commit secrets to git. Use sops-nix for production.
        '';
      };
      radarrApiKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          '
                    Radarr API key - REQUIRED for Doplarr.
                    Find in Radarr: Settings → General → Security → API Key

                    WARNING: Never commit secrets to git. Use sops-nix for production.
        '';
      };
    };

    comfyui = {
      dataPath = mkOption {
        type = types.str;
        default = "/var/lib/containers/supplemental/comfyui";
        description = "Path for ComfyUI data";
      };
      resources = mkResourceOptions {
        memory = "16g";
        cpus = "8";
        memorySwap = "20g";
      };
    };

    # Cal.com configuration
    calcom = {
      # Resource limits for Cal.com services
      resources = {
        app = mkResourceOptions {
          memory = "2g";
          cpus = "2";
        };
        db = mkResourceOptions {
          memory = "1g";
          cpus = "2";
        };
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

      # Secrets can be provided directly or via sops-nix
      # If useSops = true, secrets will be read from sops-nix paths
      useSops = mkOption {
        type = types.bool;
        default = false;
        description = "Use sops-nix for secrets management (recommended for production)";
      };

      nextauthSecret = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "NextAuth secret for session encryption. Generate with 'openssl rand -base64 32'";
      };
      calendarEncryptionKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Calendar encryption key for sensitive calendar data. Generate with 'openssl rand -base64 32'";
      };
      dbPassword = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "PostgreSQL database password for Cal.com";
      };
    };
  };

  config = mkIf cfg.enable {
    # Define sops-nix secrets if Cal.com uses sops
    sops.secrets = mkIf (cfg.calcom.enable && cfg.calcom.useSops) {
      calcom-nextauth-secret = {
        mode = "0400";
        owner = "root";
        group = "root";
      };
      calcom-encryption-key = {
        mode = "0400";
        owner = "root";
        group = "root";
      };
      calcom-db-password = {
        mode = "0400";
        owner = "root";
        group = "root";
      };
    };

    # Create environment file templates for Cal.com containers when using sops
    sops.templates = mkIf (cfg.calcom.enable && cfg.calcom.useSops) {
      "calcom-db-env" = {
        content = ''
          POSTGRES_PASSWORD=${config.sops.placeholder."calcom-db-password"}
        '';
        mode = "0400";
        owner = "root";
      };
      "calcom-app-env" = {
        content = ''
          DATABASE_URL=postgresql://calcom:${
            config.sops.placeholder."calcom-db-password"
          }@calcom-db:5432/calcom
          DATABASE_DIRECT_URL=postgresql://calcom:${
            config.sops.placeholder."calcom-db-password"
          }@calcom-db:5432/calcom
          NEXTAUTH_SECRET=${config.sops.placeholder."calcom-nextauth-secret"}
          CALENDSO_ENCRYPTION_KEY=${config.sops.placeholder."calcom-encryption-key"}
        '';
        mode = "0400";
        owner = "root";
      };
    };

    # Assertions for required secrets
    assertions = [
      {
        assertion = cfg.calcom.enable && !cfg.calcom.useSops -> cfg.calcom.nextauthSecret != null;
        message = ''
          Cal.com requires 'nextauthSecret' to be set for session encryption.
          Either:
          1. Set calcom.nextauthSecret directly (for development)
             Generate with: openssl rand -base64 32
          2. Enable calcom.useSops = true and define the secret in sops
             See docs/SECRETS-MANAGEMENT.md for proper implementation.
        '';
      }
      {
        assertion = cfg.calcom.enable && !cfg.calcom.useSops -> cfg.calcom.calendarEncryptionKey != null;
        message = ''
          Cal.com requires 'calendarEncryptionKey' to be set for calendar data encryption.
          Either:
          1. Set calcom.calendarEncryptionKey directly (for development)
             Generate with: openssl rand -base64 32
          2. Enable calcom.useSops = true and define the secret in sops
             See docs/SECRETS-MANAGEMENT.md for proper implementation.
        '';
      }
      {
        assertion = cfg.calcom.enable && !cfg.calcom.useSops -> cfg.calcom.dbPassword != null;
        message = ''
          Cal.com requires 'dbPassword' to be set for PostgreSQL database.
          Either:
          1. Set calcom.dbPassword directly (for development)
             Generate a strong password
          2. Enable calcom.useSops = true and define the secret in sops
             See docs/SECRETS-MANAGEMENT.md for proper implementation.
        '';
      }
      {
        assertion = cfg.calcom.enable && cfg.calcom.useSops -> config.sops.secrets ? calcom-nextauth-secret;
        message = ''
          Cal.com useSops is enabled but 'calcom-nextauth-secret' is not defined in sops.
          Add it to your secrets.yaml file and ensure it's encrypted.
          See docs/SECRETS-MANAGEMENT.md for proper implementation.
        '';
      }
      {
        assertion = cfg.calcom.enable && cfg.calcom.useSops -> config.sops.secrets ? calcom-encryption-key;
        message = ''
          Cal.com useSops is enabled but 'calcom-encryption-key' is not defined in sops.
          Add it to your secrets.yaml file and ensure it's encrypted.
        '';
      }
      {
        assertion = cfg.calcom.enable && cfg.calcom.useSops -> config.sops.secrets ? calcom-db-password;
        message = ''
          Cal.com useSops is enabled but 'calcom-db-password' is not defined in sops.
          Add it to your secrets.yaml file and ensure it's encrypted.
        '';
      }
    ];

    virtualisation = {
      # Enable Podman for containers with rootless mode for better security
      podman = {
        enable = true;
        defaultNetwork.settings.dns_enabled = true;

        # Enable rootless mode - containers run as non-root user
        # This provides defense-in-depth security
        # Only enable dockerCompat and socket if docker isn't already enabled
        dockerCompat = mkDefault (!config.virtualisation.docker.enable);
        dockerSocket.enable = mkDefault (!config.virtualisation.docker.enable);
      };

      oci-containers = {
        backend = "podman";

        # Define containers
        containers = {
          # Homarr - Dashboard
          homarr = mkIf cfg.homarr.enable {
            # Pinned version for reproducibility
            image = "ghcr.io/ajnart/homarr:0.15.3";

            environment = {
              TZ = cfg.timezone;
            };

            volumes = [
              "${cfg.configPath}/homarr/configs:/app/data/configs"
              "${cfg.configPath}/homarr/icons:/app/public/icons"
              "${cfg.configPath}/homarr/data:/data"
            ];

            ports = ["7575:7575"];

            extraOptions =
              [
                # Health check for automatic restart on failure
                "--health-cmd=wget --no-verbose --tries=1 --spider http://localhost:7575/ || exit 1"
                "--health-interval=30s"
                "--health-timeout=10s"
                "--health-retries=3"

                # Resource limits (configurable)
                "--memory=${cfg.homarr.resources.memory}"
                "--cpus=${cfg.homarr.resources.cpus}"
              ]
              ++ optional (
                cfg.homarr.resources.memorySwap != null
              ) "--memory-swap=${cfg.homarr.resources.memorySwap}";
          };

          # Wizarr - Invitation system
          wizarr = mkIf cfg.wizarr.enable {
            # Pinned version for reproducibility
            image = "ghcr.io/wizarrrr/wizarr:4.1.1";

            environment = {
              TZ = cfg.timezone;
            };

            volumes = ["${cfg.configPath}/wizarr:/data/database"];
            ports = ["5690:5690"];

            extraOptions =
              [
                # Health check
                "--health-cmd=wget --no-verbose --tries=1 --spider http://localhost:5690/ || exit 1"
                "--health-interval=30s"
                "--health-timeout=10s"
                "--health-retries=3"

                # Resource limits (configurable)
                "--memory=${cfg.wizarr.resources.memory}"
                "--cpus=${cfg.wizarr.resources.cpus}"
              ]
              ++ optional (
                cfg.wizarr.resources.memorySwap != null
              ) "--memory-swap=${cfg.wizarr.resources.memorySwap}";
          };

          # Doplarr - Discord bot
          doplarr = mkIf cfg.doplarr.enable {
            # Pinned version for reproducibility
            image = "ghcr.io/hotio/doplarr:release-3.7.0";

            environment =
              commonEnv
              // {
                # WARNING: Secrets should be managed via sops-nix in production
                # See docs/SECRETS-MANAGEMENT.md for proper implementation
                DISCORD_TOKEN = cfg.doplarr.discordToken;
                SONARR_API_KEY = cfg.doplarr.sonarrApiKey;
                RADARR_API_KEY = cfg.doplarr.radarrApiKey;
                SONARR_URL = "http://localhost:8989";
                RADARR_URL = "http://localhost:7878";
              };

            volumes = ["${cfg.configPath}/doplarr:/config"];

            extraOptions =
              [
                "--network=host"

                # Resource limits (configurable)
                "--memory=${cfg.doplarr.resources.memory}"
                "--cpus=${cfg.doplarr.resources.cpus}"
              ]
              ++ optional (
                cfg.doplarr.resources.memorySwap != null
              ) "--memory-swap=${cfg.doplarr.resources.memorySwap}";
          };

          # ComfyUI - AI image generation with NVIDIA GPU
          comfyui-nvidia = mkIf cfg.comfyui.enable {
            # Pinned version for reproducibility
            image = "mmartial/comfyui-nvidia-docker:1.0.0";

            environment = {
              WANTED_UID = toString cfg.uid;
              WANTED_GID = toString cfg.gid;
              BASE_DIRECTORY = "/basedir";
              SECURITY_LEVEL = "normal";
              NVIDIA_VISIBLE_DEVICES = "all";
              NVIDIA_DRIVER_CAPABILITIES = "all";
            };

            volumes = [
              "${cfg.comfyui.dataPath}/comfyui:/comfy/mnt"
              "${cfg.comfyui.dataPath}/basedir:/basedir"
            ];

            ports = ["8188:8188"];

            extraOptions =
              [
                "--device=nvidia.com/gpu=all"

                # Resource limits (configurable)
                "--memory=${cfg.comfyui.resources.memory}"
                "--cpus=${cfg.comfyui.resources.cpus}"
              ]
              ++ optional (
                cfg.comfyui.resources.memorySwap != null
              ) "--memory-swap=${cfg.comfyui.resources.memorySwap}";
          };

          # Cal.com PostgreSQL Database
          calcom-db = mkIf cfg.calcom.enable {
            # Pinned version - always pin postgres to avoid migration issues
            image = "docker.io/library/postgres:16.3-alpine";
            autoStart = true;

            environment =
              {
                POSTGRES_USER = "calcom";
                POSTGRES_DB = "calcom";
              }
              // optionalAttrs (!cfg.calcom.useSops) {
                # Only set password directly if not using sops
                POSTGRES_PASSWORD = cfg.calcom.dbPassword;
              };

            # Use environment file for secrets when sops is enabled
            environmentFiles = optional cfg.calcom.useSops config.sops.templates."calcom-db-env".path;

            volumes = [
              "${cfg.configPath}/calcom/postgres:/var/lib/postgresql/data"
            ];

            extraOptions =
              [
                # Note: Don't use --restart flag - systemd handles restarts
                # Using --restart conflicts with NixOS's --rm flag

                # Health check for database
                "--health-cmd=pg_isready -U calcom"
                "--health-interval=10s"
                "--health-timeout=5s"
                "--health-retries=5"

                # Resource limits (configurable)
                "--memory=${cfg.calcom.resources.db.memory}"
                "--cpus=${cfg.calcom.resources.db.cpus}"
                "--shm-size=256m" # Shared memory for postgres
              ]
              ++ optional (
                cfg.calcom.resources.db.memorySwap != null
              ) "--memory-swap=${cfg.calcom.resources.db.memorySwap}";
          };

          # Cal.com Application
          calcom = mkIf cfg.calcom.enable {
            # Pinned version for reproducibility
            image = "docker.io/calcom/cal.com:v4.0.8";
            autoStart = true;

            environment =
              {
                NEXT_PUBLIC_WEBAPP_URL = cfg.calcom.webappUrl;
                NEXT_PUBLIC_LICENSE_CONSENT = "true";
                CALCOM_TIMEZONE = cfg.timezone;
                TZ = cfg.timezone;
              }
              // optionalAttrs (!cfg.calcom.useSops) {
                # Only set secrets directly if not using sops
                DATABASE_URL = "postgresql://calcom:${cfg.calcom.dbPassword}@calcom-db:5432/calcom";
                DATABASE_DIRECT_URL = "postgresql://calcom:${cfg.calcom.dbPassword}@calcom-db:5432/calcom";
                NEXTAUTH_SECRET = cfg.calcom.nextauthSecret;
                CALENDSO_ENCRYPTION_KEY = cfg.calcom.calendarEncryptionKey;
              };

            # Use environment file for secrets when sops is enabled
            environmentFiles = optional cfg.calcom.useSops config.sops.templates."calcom-app-env".path;

            volumes = [
              "${cfg.configPath}/calcom/app_data:/app/data"
            ];

            ports = ["${toString cfg.calcom.port}:3000"];

            extraOptions =
              [
                # Note: Don't use --restart flag - systemd handles restarts
                # Using --restart conflicts with NixOS's --rm flag

                # Health check - Cal.com takes time to initialize and run migrations
                # Using curl as it's more commonly available in Node.js containers
                "--health-cmd=curl -f http://localhost:3000/api/health || exit 1"
                "--health-interval=30s"
                "--health-timeout=10s"
                "--health-retries=5"
                "--health-start-period=120s" # Give 2 minutes for migrations and startup

                # Resource limits (configurable)
                "--memory=${cfg.calcom.resources.app.memory}"
                "--cpus=${cfg.calcom.resources.app.cpus}"
              ]
              ++ optional (
                cfg.calcom.resources.app.memorySwap != null
              ) "--memory-swap=${cfg.calcom.resources.app.memorySwap}";

            dependsOn = ["calcom-db"];
          };
        };
      };
    };

    # Create necessary directories
    systemd.tmpfiles.rules =
      [
        "d ${cfg.configPath} 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      ]
      ++ optional cfg.homarr.enable "d ${cfg.configPath}/homarr 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      ++ optional cfg.homarr.enable "d ${cfg.configPath}/homarr/configs 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      ++ optional cfg.homarr.enable "d ${cfg.configPath}/homarr/icons 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      ++ optional cfg.homarr.enable "d ${cfg.configPath}/homarr/data 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      ++ optional cfg.wizarr.enable "d ${cfg.configPath}/wizarr 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      ++ optional cfg.doplarr.enable "d ${cfg.configPath}/doplarr 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      ++ optional cfg.comfyui.enable "d ${cfg.comfyui.dataPath}/comfyui 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      ++ optional cfg.comfyui.enable "d ${cfg.comfyui.dataPath}/basedir 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      ++ optional cfg.calcom.enable "d ${cfg.configPath}/calcom 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      ++ optional cfg.calcom.enable "d ${cfg.configPath}/calcom/postgres 0755 999 999 -" # PostgreSQL runs as UID 999
      ++ optional cfg.calcom.enable "d ${cfg.configPath}/calcom/app_data 0755 ${toString cfg.uid} ${toString cfg.gid} -";

    # GPU support for ComfyUI
    hardware.nvidia-container-toolkit.enable =
      mkIf (
        cfg.comfyui.enable && config.hardware.nvidia.modesetting.enable or false
      )
      true;
  };
}
