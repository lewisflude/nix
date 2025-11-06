{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.atuin;
in {
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
  };

  config = lib.mkIf cfg.enable {
    launchd.daemons.atuin = {
      command = lib.getExe cfg.package;
      serviceConfig = {
        Label = "com.atuin.server";
        ProgramArguments =
          [
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
          ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/atuin-server.log";
        StandardErrorPath = "/tmp/atuin-server.log";
      };
    };
  };
}
