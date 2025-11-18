{
  lib,
  ...
}:
let
  inherit (lib) mkOption mkEnableOption types;
in
{
  options.host.features.containersSupplemental = {
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

    jellystat = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Jellystat statistics dashboard for Jellyfin";
      };

      port = mkOption {
        type = types.int;
        default = 3004;
        description = "Port to expose Jellystat on";
      };

      useSops = mkOption {
        type = types.bool;
        default = true;
        description = "Use sops-nix for Jellystat secrets management";
      };
    };

    doplarr = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Doplarr Discord bot";
      };
    };

    profilarr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Profilarr configuration management tool for Radarr/Sonarr";
      };
    };

    cleanuparr = mkOption {
      type = types.attrsOf types.anything;
      default = {
        enable = false;
      };
      description = "Cleanuparr download queue cleanup automation configuration";
    };

    termix = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Termix terminal sharing service";
      };

      port = mkOption {
        type = types.int;
        default = 8081;
        description = "Port to expose Termix on";
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
}
