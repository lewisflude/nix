{
  config,
  lib,
  constants,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
  cfg = config.host.features.homeServer;
in
{
  config = mkMerge [
    (mkIf cfg.enable {

      services = mkMerge [
        (mkIf cfg.fileSharing {
          samba = {
            enable = true;
            openFirewall = true;
            settings = {
              global = {
                "workgroup" = "WORKGROUP";
                "server string" = config.host.hostname;
                "netbios name" = config.host.hostname;
                "security" = "user";
                "hosts allow" =
                  "${constants.networks.lan.prefix} ${constants.networks.lan.secondaryPrefix} ${constants.networks.localhost.ipv4} localhost";
                "hosts deny" = constants.networks.all.cidr;
                "guest account" = "nobody";
                "map to guest" = "bad user";
              };
            };
          };
        })
        (mkIf cfg.backups {
          restic.backups = {
            daily = {
              paths = [
                "/home/${config.host.username}"
              ];
              repository = "/mnt/backup/restic";
              passwordFile = config.sops.secrets.restic-password.path or null;
              timerConfig = {
                OnCalendar = "daily";
                Persistent = true;
              };
            };
          };
        })
      ];

      networking.firewall = mkMerge [
        (mkIf cfg.fileSharing {
          allowedTCPPorts = [
            139
            445
          ];
          allowedUDPPorts = [
            137
            138
          ];
        })
      ];
    })

    {
      assertions = [
        {
          assertion = cfg.fileSharing -> cfg.enable;
          message = "fileSharing requires homeServer.enable to be true";
        }
        {
          assertion = cfg.backups -> cfg.enable;
          message = "backups requires homeServer.enable to be true";
        }
        {
          assertion = cfg.fileSharing -> (config.networking.firewall.enable or true);
          message = "fileSharing requires firewall to be enabled for security";
        }
        {
          assertion = cfg.backups -> (config.sops.secrets ? restic-password);
          message = "backups requires restic-password secret to be configured";
        }
      ];
    }
  ];
}
