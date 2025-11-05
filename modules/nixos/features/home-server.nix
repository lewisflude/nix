# Home server feature module for NixOS
# Controlled by host.features.homeServer.*
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.host.features.homeServer;
in
{
  config = mkIf cfg.enable {
    # Home server services
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
                "127.0.0.1"
                "::1"
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
              "hosts allow" = "192.168.0. 127.0.0.1 localhost";
              "hosts deny" = "0.0.0.0/0";
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

    # Open firewall ports for services
    networking.firewall = mkMerge [
      (mkIf cfg.homeAssistant {
        allowedTCPPorts = [ 8123 ];
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
