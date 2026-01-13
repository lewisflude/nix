{
  lib,
  ...
}:
let
  inherit (lib) mkOption mkEnableOption types;
in
{
  options.host.features.containersSupplemental = {
    enable = mkEnableOption "supplemental container services" // {
      default = false;
    };

    uid = mkOption {
      type = types.int;
      default = 1000;
      description = "User ID for container processes";
      example = 1000;
    };

    gid = mkOption {
      type = types.int;
      default = 100;
      description = "Group ID for container processes";
      example = 100;
    };

    homarr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Homarr dashboard";
        example = true;
      };
    };

    wizarr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Wizarr invitation system";
        example = true;
      };
    };

    janitorr = mkOption {
      type = types.attrsOf types.anything;
      default = {
        enable = true;
      };
      description = "Janitorr media cleanup automation configuration";
      example = { enable = true; };
    };

    jellystat = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Jellystat statistics dashboard for Jellyfin";
        example = true;
      };

      port = mkOption {
        type = types.int;
        default = 3004;
        description = "Port to expose Jellystat on";
        example = 3004;
      };

      useSops = mkOption {
        type = types.bool;
        default = true;
        description = "Use sops-nix for Jellystat secrets management";
        example = true;
      };
    };

    doplarr = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Doplarr Discord bot";
        example = true;
      };
    };

    profilarr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Profilarr configuration management tool for Radarr/Sonarr";
        example = true;
      };
    };

    cleanuparr = mkOption {
      type = types.attrsOf types.anything;
      default = {
        enable = false;
      };
      description = "Cleanuparr download queue cleanup automation configuration";
      example = { enable = true; };
    };

    termix = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Termix terminal sharing service";
        example = true;
      };

      port = mkOption {
        type = types.int;
        default = 8081;
        description = "Port to expose Termix on";
        example = 8081;
      };
    };

    comfyui = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable ComfyUI AI image generation";
        example = true;
      };
    };

    calcom = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Cal.com scheduling platform";
        example = true;
      };

      port = mkOption {
        type = types.int;
        default = 3000;
        description = "Port to expose Cal.com on";
        example = 3000;
      };

      webappUrl = mkOption {
        type = types.str;
        default = "http://localhost:3000";
        description = "Public URL for Cal.com (e.g., https://cal.example.com)";
        example = "https://cal.example.com";
      };

      useSops = mkOption {
        type = types.bool;
        default = false;
        description = "Use sops-nix for Cal.com secrets management";
        example = true;
      };

      nextauthSecret = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "NextAuth secret for Cal.com session encryption";
        example = "super-secret-key-123";
      };

      calendarEncryptionKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Calendar encryption key for Cal.com";
        example = "encryption-key-456";
      };

      dbPassword = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "PostgreSQL database password for Cal.com";
        example = "db-password-789";
      };

      email = {
        host = mkOption {
          type = types.str;
          default = "localhost";
          description = "SMTP server host for sending emails";
          example = "smtp.gmail.com";
        };

        port = mkOption {
          type = types.int;
          default = 587;
          description = "SMTP server port (587 for STARTTLS, 465 for SSL)";
          example = 587;
        };

        from = mkOption {
          type = types.str;
          default = "noreply@localhost";
          description = "Email address to send emails from";
          example = "notifications@example.com";
        };

        fromName = mkOption {
          type = types.str;
          default = "Cal.com";
          description = "Display name for outgoing emails";
          example = "My Scheduling App";
        };

        username = mkOption {
          type = types.str;
          default = "";
          description = "SMTP authentication username";
          example = "apikey";
        };

        password = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "SMTP authentication password (only used if useSops is false)";
          example = "smtp-password";
        };
      };

      branding = {
        appName = mkOption {
          type = types.str;
          default = "Cal.com";
          description = "Application name shown in the interface";
          example = "My Calendar";
        };

        companyName = mkOption {
          type = types.str;
          default = "Cal.com, Inc.";
          description = "Company name for legal/footer information";
          example = "My Company LLC";
        };

        supportEmail = mkOption {
          type = types.str;
          default = "help@cal.com";
          description = "Support email address for user assistance";
          example = "support@example.com";
        };
      };

      disableSignup = mkOption {
        type = types.bool;
        default = true;
        description = "Disable public user registration (recommended for personal use)";
        example = true;
      };

      disableTelemetry = mkOption {
        type = types.bool;
        default = true;
        description = "Disable anonymous usage telemetry";
        example = true;
      };

      availabilityInterval = mkOption {
        type = types.nullOr types.int;
        default = 15;
        description = "Time slot interval in minutes for availability scheduling";
        example = 30;
      };

      logLevel = mkOption {
        type = types.int;
        default = 3;
        description = "Logging level (0=silly, 1=trace, 2=debug, 3=info, 4=warn, 5=error, 6=fatal)";
        example = 4;
      };

      cronApiKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "API key for cron jobs";
        example = "cron-api-key";
      };

      serviceAccountEncryptionKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Encryption key for service account credentials";
        example = "service-account-key";
      };

      googleCalendar = {
        enabled = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Google Calendar integration and Login with Google";
          example = true;
        };

        credentials = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Google API credentials JSON string";
          example = ''{"web":{"client_id":"..."}}'';
        };
      };
    };
  };
}
