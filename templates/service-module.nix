# Service module template
# For standalone services that don't fit into the feature system
# Replace SERVICE_NAME with your service name (e.g., "home-assistant", "grafana")
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.SERVICE_NAME;
in {
  options.services.SERVICE_NAME = {
    enable = mkEnableOption "SERVICE_NAME service";

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port to listen on";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/SERVICE_NAME";
      description = "Directory to store service data";
    };

    user = mkOption {
      type = types.str;
      default = "SERVICE_NAME";
      description = "User to run the service as";
    };

    group = mkOption {
      type = types.str;
      default = "SERVICE_NAME";
      description = "Group to run the service as";
    };

    extraConfig = mkOption {
      type = types.attrs;
      default = {};
      description = "Additional configuration options";
    };
  };

  config = mkIf cfg.enable {
    # Create user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      inherit (cfg) group;
      home = cfg.dataDir;
      description = "SERVICE_NAME service user";
    };

    users.groups.${cfg.group} = {};

    # Create data directory
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
    ];

    # Systemd service
    systemd.services.SERVICE_NAME = {
      description = "SERVICE_NAME Service";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${pkgs.SERVICE_PACKAGE}/bin/SERVICE_NAME --port ${toString cfg.port}";
        Restart = "on-failure";
        RestartSec = "10s";

        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [cfg.dataDir];
      };
    };

    # Firewall configuration
    networking.firewall.allowedTCPPorts = [cfg.port];

    # Backup configuration (optional)
    # services.restic.backups.SERVICE_NAME = mkIf config.services.restic.server.enable {
    #   paths = [ cfg.dataDir ];
    # };
  };
}
