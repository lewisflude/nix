# Home Server Aspect
#
# Combines all home server configuration in a single file.
# Reads options from config.host.features.homeServer (defined in modules/shared/host-options/features/home-server.nix)
#
# Platform support:
# - NixOS: Samba file sharing, restic backups
# - Darwin: Placeholder (file sharing typically uses native sharing)
{
  config,
  lib,
  pkgs,
  constants,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
  cfg = config.host.features.homeServer;
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  config = mkMerge [
    # ================================================================
    # NixOS Configuration
    # ================================================================
    (mkIf (cfg.enable && isLinux) {
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

    # ================================================================
    # Darwin Configuration
    # ================================================================
    (mkIf (cfg.enable && isDarwin) {
      # macOS file sharing uses native SMB support via System Settings
      # Placeholder for any future nix-darwin integration
    })

    # ================================================================
    # Assertions (both platforms)
    # ================================================================
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
          assertion = !(cfg.fileSharing && isLinux) || (config.networking.firewall.enable or true);
          message = "fileSharing requires firewall to be enabled for security";
        }
        {
          assertion = !(cfg.backups && isLinux) || (config.sops.secrets ? restic-password);
          message = "backups requires restic-password secret to be configured";
        }
      ];
    }
  ];
}
