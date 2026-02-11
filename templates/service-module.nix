# Service Module Template - Dendritic Pattern
# For system services with options
{ config, ... }:
{
  # NixOS service configuration
  flake.modules.nixos.SERVICE_NAME =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.services.SERVICE_NAME;
    in
    {
      # Service options
      options.services.SERVICE_NAME = {
        enable = lib.mkEnableOption "SERVICE_NAME service";

        port = lib.mkOption {
          type = lib.types.port;
          default = 8080;
          description = "Port to listen on";
        };

        dataDir = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/SERVICE_NAME";
          description = "Directory to store service data";
        };
      };

      # Service implementation
      config = lib.mkIf cfg.enable {
        users.users.SERVICE_NAME = {
          isSystemUser = true;
          group = "SERVICE_NAME";
          home = cfg.dataDir;
        };
        users.groups.SERVICE_NAME = { };

        systemd.tmpfiles.rules = [
          "d ${cfg.dataDir} 0750 SERVICE_NAME SERVICE_NAME -"
        ];

        systemd.services.SERVICE_NAME = {
          description = "SERVICE_NAME Service";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];

          serviceConfig = {
            Type = "simple";
            User = "SERVICE_NAME";
            Group = "SERVICE_NAME";
            WorkingDirectory = cfg.dataDir;
            ExecStart = "${pkgs.SERVICE_PACKAGE}/bin/SERVICE_NAME --port ${toString cfg.port}";
            Restart = "on-failure";
            RestartSec = "10s";

            # Security hardening
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            ReadWritePaths = [ cfg.dataDir ];
          };
        };

        networking.firewall.allowedTCPPorts = [ cfg.port ];
      };
    };
}
