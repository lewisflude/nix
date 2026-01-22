{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.atuin;
in
{
  options.services.atuin = {
    enable = lib.mkEnableOption "Atuin server for shell history sync";

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "The host address the atuin server should listen on";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8888;
      description = "The port the atuin server should listen on";
    };

    path = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "A path to prepend to all the routes of the server";
    };

    maxHistoryLength = lib.mkOption {
      type = lib.types.ints.positive;
      default = 8192;
      description = "The max length of each history item the atuin server should store";
    };

    openRegistration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow new user registrations with the atuin server";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.atuin;
      description = "The atuin package to use";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open ports in the firewall for the atuin server";
      # Note: macOS doesn't have a declarative firewall like NixOS
      # This option is kept for compatibility but doesn't do anything
    };

    database = {
      uri = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "postgresql://atuin:password@localhost/atuin";
        description = ''
          Database connection URI. Atuin requires PostgreSQL 14+ for optimal performance.
          If null, defaults to SQLite at ~/.local/share/atuin/history.db

          Recommended: Use PostgreSQL for production deployments.
          SQLite is suitable for single-user development only.
        '';
      };
    };

    tls = {
      enable = lib.mkEnableOption "TLS/HTTPS support for Atuin server";

      cert = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = "/etc/ssl/certs/atuin.crt";
        description = "Path to TLS certificate file (PEM format)";
      };

      key = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = "/etc/ssl/private/atuin.key";
        description = "Path to TLS private key file (PEM format)";
      };
    };

    logging = {
      directory = lib.mkOption {
        type = lib.types.str;
        default = "${
          config.home-manager.users.${config.host.username or "lewis"}.home.homeDirectory or "/Users/lewis"
        }/.local/state/atuin";
        description = "Directory for Atuin server logs (replaces /tmp for persistence)";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Create log directory
    system.activationScripts.postActivation.text = lib.mkAfter ''
      mkdir -p ${cfg.logging.directory}
      chmod 755 ${cfg.logging.directory}
    '';

    # Assertions for TLS configuration
    assertions = [
      {
        assertion = cfg.tls.enable -> (cfg.tls.cert != null && cfg.tls.key != null);
        message = "Atuin TLS is enabled but cert or key path is not set";
      }
      {
        assertion = cfg.database.uri != null -> (lib.hasPrefix "postgresql://" cfg.database.uri);
        message = "Atuin database URI must start with 'postgresql://' (PostgreSQL 14+ required)";
      }
    ];

    # Set environment variables for Atuin server
    environment.variables = lib.mkIf (cfg.database.uri != null) {
      ATUIN_DB_URI = cfg.database.uri;
    };

    launchd.daemons.atuin = {
      command = lib.getExe cfg.package;
      serviceConfig = {
        Label = "com.atuin.server";
        ProgramArguments = [
          (lib.getExe cfg.package)
          "server"
          "--host"
          cfg.host
          "--port"
          (toString cfg.port)
        ]
        ++ lib.optionals (cfg.path != "") [
          "--path"
          cfg.path
        ]
        ++ [
          "--max-history-length"
          (toString cfg.maxHistoryLength)
        ]
        ++ lib.optionals cfg.openRegistration [
          "--open-registration"
        ]
        ++ lib.optionals cfg.tls.enable [
          "--tls-cert"
          (toString cfg.tls.cert)
          "--tls-key"
          (toString cfg.tls.key)
        ];

        # Environment for database configuration
        EnvironmentVariables = lib.mkIf (cfg.database.uri != null) {
          ATUIN_DB_URI = cfg.database.uri;
        };

        RunAtLoad = true;
        KeepAlive = true;

        # Improved logging with rotation support (use journald or rotate externally)
        StandardOutPath = "${cfg.logging.directory}/atuin-server.log";
        StandardErrorPath = "${cfg.logging.directory}/atuin-server-error.log";
      };
    };
  };
}
