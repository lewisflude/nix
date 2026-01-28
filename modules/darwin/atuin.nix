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
      description = "Open ports in the firewall";
    };

    database.uri = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Database connection URI (defaults to SQLite)";
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

    logging.directory = lib.mkOption {
      type = lib.types.str;
      default = "${config.home-manager.users.${config.host.username}.home.homeDirectory}/.local/state/atuin";
      description = "Directory for Atuin server logs";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.tls.enable -> (cfg.tls.cert != null && cfg.tls.key != null);
        message = "Atuin TLS enabled but cert/key not set";
      }
    ];

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
        StandardOutPath = "${cfg.logging.directory}/atuin-server.log";
        StandardErrorPath = "${cfg.logging.directory}/atuin-server-error.log";
      };
    };
  };
}
