{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  cfg = config.services.SERVICE_NAME;
in
{
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
      default = { };
      description = "Additional configuration options";
    };
  };

  config = mkIf cfg.enable {

    users.users.${cfg.user} = {
      isSystemUser = true;
      inherit (cfg) group;
      home = cfg.dataDir;
      description = "SERVICE_NAME service user";
    };

    users.groups.${cfg.group} = { };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.SERVICE_NAME = {
      description = "SERVICE_NAME Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${pkgs.SERVICE_PACKAGE}/bin/SERVICE_NAME --port ${toString cfg.port}";
        Restart = "on-failure";
        RestartSec = "10s";

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ cfg.dataDir ];
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];

  };
}
