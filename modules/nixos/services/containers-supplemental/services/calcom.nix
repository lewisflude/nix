{
  config,
  lib,
  ...
}: let
  inherit
    (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    optional
    optionalAttrs
    optionalString
    mkMerge
    ;
  containersLib = import ../lib.nix {inherit lib;};
  inherit (containersLib) mkResourceOptions mkResourceFlags;

  cfg = config.host.services.containersSupplemental;
  calCfg = cfg.calcom;

  # Extract hostname from webappUrl for ALLOWED_HOSTNAMES
  # Cal.com expects hostnames without protocol (e.g., "cal.example.com")
  calcomHost = let
    matches = builtins.match "https?://([^/:]+)" calCfg.webappUrl;
  in
    if matches == null || matches == []
    then calCfg.webappUrl
    else lib.head matches;

  # Extract domain for cookie settings (e.g., ".example.com" from "https://cal.example.com")
  calcomCookieDomain = let
    matches = builtins.match "https?://([^/:]+)" calCfg.webappUrl;
    host =
      if matches == null || matches == []
      then calCfg.webappUrl
      else lib.head matches;
    # Split by dots and take the last two parts for the base domain
    parts = lib.splitString "." host;
    partsLen = lib.length parts;
  in
    if partsLen >= 2
    then ".${lib.concatStringsSep "." (lib.drop (partsLen - 2) parts)}"
    else host;

  # Format as JSON array string for Cal.com's validation
  # Cal.com expects a JSON-encoded array like: ["cal.example.com","localhost:3000"]
  calcomAllowedHostnames = builtins.toJSON [
    calcomHost
    "localhost:${toString calCfg.port}"
  ];
in {
  options.host.services.containersSupplemental.calcom = {
    enable =
      mkEnableOption "Cal.com scheduling platform"
      // {
        default = false;
      };

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
      description = "Port to expose Cal.com on.";
    };

    webappUrl = mkOption {
      type = types.str;
      default = "http://localhost:3000";
      description = "Public URL for Cal.com (e.g., https://cal.example.com).";
    };

    useSops = mkOption {
      type = types.bool;
      default = false;
      description = "Use sops-nix for secrets management (recommended for production).";
    };

    nextauthSecret = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        NextAuth secret for session encryption (must be 32+ characters).
        Generate with: openssl rand -base64 32
        This produces a 44-character base64 string that Cal.com uses directly.
      '';
    };

    calendarEncryptionKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Calendar encryption key for sensitive data (must be exactly 32 bytes when base64-decoded).
        Generate with: openssl rand -base64 32
        IMPORTANT: Ensure this is exactly 44 characters (32 bytes base64-encoded).
      '';
    };

    dbPassword = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "PostgreSQL database password for Cal.com.";
    };

    # Email configuration
    email = {
      host = mkOption {
        type = types.str;
        default = "localhost";
        description = "SMTP server host for sending emails.";
      };

      port = mkOption {
        type = types.int;
        default = 587;
        description = "SMTP server port (587 for STARTTLS, 465 for SSL).";
      };

      from = mkOption {
        type = types.str;
        default = "noreply@localhost";
        description = "Email address to send emails from.";
      };

      fromName = mkOption {
        type = types.str;
        default = "Cal.com";
        description = "Display name for outgoing emails.";
      };

      username = mkOption {
        type = types.str;
        default = "";
        description = "SMTP authentication username (usually your email address).";
      };

      password = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "SMTP authentication password. Only used if useSops is false.";
      };
    };

    # Branding configuration
    branding = {
      appName = mkOption {
        type = types.str;
        default = "Cal.com";
        description = "Application name shown in the interface.";
      };

      companyName = mkOption {
        type = types.str;
        default = "Cal.com, Inc.";
        description = "Company name for legal/footer information.";
      };

      supportEmail = mkOption {
        type = types.str;
        default = "help@cal.com";
        description = "Support email address for user assistance.";
      };
    };

    # General settings
    disableSignup = mkOption {
      type = types.bool;
      default = true;
      description = "Disable public user registration (recommended for personal use).";
    };

    disableTelemetry = mkOption {
      type = types.bool;
      default = true;
      description = "Disable anonymous usage telemetry.";
    };

    availabilityInterval = mkOption {
      type = types.nullOr types.int;
      default = 15;
      description = "Time slot interval in minutes for availability scheduling.";
    };

    logLevel = mkOption {
      type = types.int;
      default = 3;
      description = "Logging level (0=silly, 1=trace, 2=debug, 3=info, 4=warn, 5=error, 6=fatal).";
    };

    cronApiKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "API key for cron jobs. Generate with 'openssl rand -hex 16'.";
    };

    serviceAccountEncryptionKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Encryption key for service account credentials (must be exactly 32 bytes when base64-decoded).
        Generate with: openssl rand -base64 32
        IMPORTANT: Ensure this is exactly 44 characters (32 bytes base64-encoded).
      '';
    };

    # Google Calendar integration
    googleCalendar = {
      enabled = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Google Calendar integration and Login with Google.";
      };

      credentials = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Google API credentials JSON string.
          Get from: https://console.cloud.google.com
          Format: {"web":{"client_id":"...","client_secret":"..."}}
        '';
      };
    };
  };

  config = mkIf (cfg.enable && calCfg.enable) (mkMerge [
    {
      virtualisation.oci-containers.containers = {
        "calcom-db" = {
          image = "docker.io/library/postgres:16.3-alpine";
          autoStart = true;
          environment =
            {
              POSTGRES_USER = "calcom";
              POSTGRES_DB = "calcom";
            }
            // optionalAttrs (!calCfg.useSops) {
              POSTGRES_PASSWORD = calCfg.dbPassword;
            };
          environmentFiles = optional calCfg.useSops config.sops.templates."calcom-db-env".path;
          volumes = [
            "${cfg.configPath}/calcom/postgres:/var/lib/postgresql/data"
          ];
          extraOptions =
            [
              "--shm-size=256m"
            ]
            ++ mkResourceFlags calCfg.resources.db;
        };

        calcom = {
          image = "docker.io/calcom/cal.com:v5.8.2";
          autoStart = true;
          environment =
            {
              NEXT_PUBLIC_WEBAPP_URL = calCfg.webappUrl;
              NEXT_PUBLIC_WEBSITE_URL = calCfg.webappUrl;
              NEXTAUTH_URL = calCfg.webappUrl;
              NEXTAUTH_COOKIE_DOMAIN = calcomCookieDomain;
              NEXT_PUBLIC_LICENSE_CONSENT = "true";
              CALCOM_TIMEZONE = cfg.timezone;
              TZ = cfg.timezone;
              ALLOWED_HOSTNAMES = calcomAllowedHostnames;

              # Email configuration
              EMAIL_FROM = calCfg.email.from;
              EMAIL_FROM_NAME = calCfg.email.fromName;
              EMAIL_SERVER_HOST = calCfg.email.host;
              EMAIL_SERVER_PORT = toString calCfg.email.port;
              EMAIL_SERVER_USER = calCfg.email.username;

              # Branding
              NEXT_PUBLIC_APP_NAME = calCfg.branding.appName;
              NEXT_PUBLIC_COMPANY_NAME = calCfg.branding.companyName;
              NEXT_PUBLIC_SUPPORT_MAIL_ADDRESS = calCfg.branding.supportEmail;

              # General settings
              CALCOM_TELEMETRY_DISABLED =
                if calCfg.disableTelemetry
                then "1"
                else "0";
              NEXT_PUBLIC_DISABLE_SIGNUP =
                if calCfg.disableSignup
                then "true"
                else "false";
              NEXT_PUBLIC_LOGGER_LEVEL = toString calCfg.logLevel;
            }
            // optionalAttrs (calCfg.availabilityInterval != null) {
              NEXT_PUBLIC_AVAILABILITY_SCHEDULE_INTERVAL = toString calCfg.availabilityInterval;
            }
            // optionalAttrs
            (calCfg.googleCalendar.enabled && !calCfg.useSops && calCfg.googleCalendar.credentials != null)
            {
              GOOGLE_API_CREDENTIALS = calCfg.googleCalendar.credentials;
              GOOGLE_LOGIN_ENABLED = "true";
            }
            // optionalAttrs (calCfg.googleCalendar.enabled && calCfg.useSops) {
              GOOGLE_LOGIN_ENABLED = "true";
            }
            // optionalAttrs (!calCfg.useSops) {
              DATABASE_URL = "postgresql://calcom:${calCfg.dbPassword}@calcom-db:5432/calcom";
              DATABASE_DIRECT_URL = "postgresql://calcom:${calCfg.dbPassword}@calcom-db:5432/calcom";
              NEXTAUTH_SECRET = calCfg.nextauthSecret;
              CALENDSO_ENCRYPTION_KEY = calCfg.calendarEncryptionKey;
              EMAIL_SERVER_PASSWORD = calCfg.email.password;
            }
            // optionalAttrs (!calCfg.useSops && calCfg.cronApiKey != null) {
              CRON_API_KEY = calCfg.cronApiKey;
            }
            // optionalAttrs (!calCfg.useSops && calCfg.serviceAccountEncryptionKey != null) {
              CALCOM_SERVICE_ACCOUNT_ENCRYPTION_KEY = calCfg.serviceAccountEncryptionKey;
            };
          environmentFiles = optional calCfg.useSops config.sops.templates."calcom-app-env".path;
          volumes = [
            "${cfg.configPath}/calcom/app_data:/app/data"
          ];
          ports = ["${toString calCfg.port}:3000"];
          extraOptions = mkResourceFlags calCfg.resources.app;
          dependsOn = ["calcom-db"];
        };
      };

      systemd.tmpfiles.rules = [
        "d ${cfg.configPath}/calcom 0755 ${toString cfg.uid} ${toString cfg.gid} -"
        "d ${cfg.configPath}/calcom/postgres 0755 999 999 -"
        "d ${cfg.configPath}/calcom/app_data 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      ];
    }
    (mkIf calCfg.useSops {
      sops.secrets =
        {
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
          calcom-email-password = {
            mode = "0400";
            owner = "root";
            group = "root";
          };
          calcom-cron-api-key = {
            mode = "0400";
            owner = "root";
            group = "root";
          };
          calcom-service-account-key = {
            mode = "0400";
            owner = "root";
            group = "root";
          };
        }
        // optionalAttrs calCfg.googleCalendar.enabled {
          calcom-google-credentials = {
            mode = "0400";
            owner = "root";
            group = "root";
          };
        };

      sops.templates = {
        "calcom-db-env" = {
          content = ''
            POSTGRES_PASSWORD=${config.sops.placeholder."calcom-db-password"}
          '';
          mode = "0400";
          owner = "root";
        };
        "calcom-app-env" = {
          content =
            ''
              DATABASE_URL=postgresql://calcom:${
                config.sops.placeholder."calcom-db-password"
              }@calcom-db:5432/calcom
              DATABASE_DIRECT_URL=postgresql://calcom:${
                config.sops.placeholder."calcom-db-password"
              }@calcom-db:5432/calcom
              NEXTAUTH_SECRET=${config.sops.placeholder."calcom-nextauth-secret"}
              CALENDSO_ENCRYPTION_KEY=${config.sops.placeholder."calcom-encryption-key"}
              EMAIL_SERVER_PASSWORD=${config.sops.placeholder."calcom-email-password"}
              CRON_API_KEY=${config.sops.placeholder."calcom-cron-api-key"}
              CALCOM_SERVICE_ACCOUNT_ENCRYPTION_KEY=${config.sops.placeholder."calcom-service-account-key"}
            ''
            + optionalString calCfg.googleCalendar.enabled ''
              GOOGLE_API_CREDENTIALS=${config.sops.placeholder."calcom-google-credentials"}
            '';
          mode = "0400";
          owner = "root";
        };
      };
    })
    {
      assertions =
        [
          {
            assertion = calCfg.useSops || calCfg.nextauthSecret != null;
            message = ''
              Cal.com requires 'nextauthSecret' to be set for session encryption.
              Either set host.services.containersSupplemental.calcom.nextauthSecret directly (for development)
              or enable calcom.useSops = true and define the secret via sops-nix.
            '';
          }
          {
            assertion = calCfg.useSops || calCfg.calendarEncryptionKey != null;
            message = ''
              Cal.com requires 'calendarEncryptionKey' to be set for calendar data encryption.
              Set the value directly or enable calcom.useSops = true and manage it via sops-nix.
            '';
          }
          {
            assertion = calCfg.useSops || calCfg.dbPassword != null;
            message = ''
              Cal.com requires 'dbPassword' to be set for the PostgreSQL database.
              Set the value directly or enable calcom.useSops = true and manage it via sops-nix.
            '';
          }
          {
            assertion = calCfg.useSops || calCfg.email.password != null;
            message = ''
              Cal.com requires 'email.password' to be set for sending emails.
              Set the value directly or enable calcom.useSops = true and manage it via sops-nix.
            '';
          }
        ]
        ++ optional calCfg.useSops {
          assertion = config.sops.secrets ? calcom-nextauth-secret;
          message = ''
            Cal.com useSops is enabled but 'calcom-nextauth-secret' is not defined in sops.
            Add it to your secrets file and ensure it is encrypted.
          '';
        }
        ++ optional calCfg.useSops {
          assertion = config.sops.secrets ? calcom-encryption-key;
          message = ''
            Cal.com useSops is enabled but 'calcom-encryption-key' is not defined in sops.
          '';
        }
        ++ optional calCfg.useSops {
          assertion = config.sops.secrets ? calcom-db-password;
          message = ''
            Cal.com useSops is enabled but 'calcom-db-password' is not defined in sops.
          '';
        }
        ++ optional calCfg.useSops {
          assertion = config.sops.secrets ? calcom-email-password;
          message = ''
            Cal.com useSops is enabled but 'calcom-email-password' is not defined in sops.
          '';
        }
        ++ optional calCfg.useSops {
          assertion = config.sops.secrets ? calcom-cron-api-key;
          message = ''
            Cal.com useSops is enabled but 'calcom-cron-api-key' is not defined in sops.
          '';
        }
        ++ optional calCfg.useSops {
          assertion = config.sops.secrets ? calcom-service-account-key;
          message = ''
            Cal.com useSops is enabled but 'calcom-service-account-key' is not defined in sops.
          '';
        }
        ++ optional (calCfg.useSops && calCfg.googleCalendar.enabled) {
          assertion = config.sops.secrets ? calcom-google-credentials;
          message = ''
            Cal.com Google Calendar is enabled but 'calcom-google-credentials' is not defined in sops.
          '';
        };
    }
  ]);
}
