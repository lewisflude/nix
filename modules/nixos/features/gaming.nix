{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkMerge optionals;
  cfg = config.host.features.gaming;
  constants = import ../../../lib/constants.nix;
in
{
  config = mkMerge [
    (mkIf cfg.enable {
      # ESYNC fallback requires high file descriptor limit
      host.systemDefaults.fileDescriptorLimit = lib.mkOverride 60 1048576;

      programs = {
        steam = mkIf cfg.steam {
          enable = true;
          protontricks.enable = true;
          remotePlay.openFirewall = true;
          dedicatedServer.openFirewall = true;
          extraCompatPackages = [ pkgs.proton-ge-bin ];

          # mkDefault allows VR module to override
          package = lib.mkDefault (
            pkgs.steam.override {
              # -pipewire: Screen capture for Remote Play on Wayland
              # -system-composer: Fix flickering on Niri
              extraArgs = "-pipewire -system-composer";
            }
          );
        };

        gamescope = mkIf cfg.steam {
          enable = true;
          capSysNice = true;
        };

        gamemode = mkIf cfg.performance {
          enable = true;
          settings.general.renice = 10;
        };
      };

      services = {
        ananicy = mkIf cfg.steam {
          enable = true;
          package = pkgs.ananicy-cpp;
          rulesProvider = pkgs.ananicy-rules-cachyos;
        };

        udev.packages = [ pkgs.game-devices-udev-rules ];
      };

      # Steam Link firewall (remotePlay.openFirewall may not cover Quest 3)
      networking.firewall = mkIf cfg.steam {
        allowedUDPPorts = [
          constants.ports.gaming.steamLink.discovery
        ]
        ++ constants.ports.gaming.steamLink.streamingUdp;
        allowedTCPPorts = [ constants.ports.gaming.steamLink.streamingTcp ];
      };

      environment.systemPackages = [
        pkgs.protonup-qt
      ]
      ++ optionals cfg.steam [
        pkgs.steamcmd
        pkgs.steam-run
        pkgs.gamescope
        pkgs.gamescope-wsi
      ]
      ++ optionals cfg.lutris [ pkgs.lutris ];

      hardware.uinput.enable = true;
    })

    {
      assertions = [
        {
          assertion = cfg.emulators -> cfg.enable;
          message = "Emulators require gaming feature to be enabled";
        }
      ];
    }
  ];
}
