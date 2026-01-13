{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
  cfg = config.host.features.homeServer;
  constants = import ../../../lib/constants.nix;
in
{
  config = mkIf cfg.enable {

    services = mkMerge [
      (mkIf cfg.homeAssistant {
        home-assistant = {
          enable = true;
          extraComponents = [
            "esphome"
            "met"
            "radio_browser"
          ];
          config = {
            default_config = { };
            http = {
              server_host = "0.0.0.0";
              trusted_proxies = [
                constants.networks.localhost.ipv4
                constants.networks.localhost.ipv6
              ];
            };
          };
        };
      })
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
      (mkIf cfg.homeAssistant {
        allowedTCPPorts = [ constants.ports.services.homeAssistant ];
      })
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
  };
}
