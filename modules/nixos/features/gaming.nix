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
      # Enable user namespaces for Steam/Flatpak sandboxing
      security.unprivilegedUsernsClone = true;

      # Note: Avoid setting boot.kernel.sysctl."kernel.yama.ptrace_scope" > 0
      # and security.hideProcessInformation = true (hidepid) as these break
      # Easy Anti-Cheat and other anti-cheat systems that need process visibility

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
              extraArgs = "-pipewire -system-composer";
              extraProfile = ''
                # Required for OpenXR games to find WiVRn runtime
                export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1
              '';
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
        udev.packages = [ pkgs.game-devices-udev-rules ];

        # Override Steam's udev rule to restrict uinput to steam group
        # Default behavior grants uinput to all logged-in users (TAG+="uaccess")
        # which can allow sandbox escape. See: https://github.com/ValveSoftware/steam-devices/issues/71
        udev.extraRules = ''
          # Restrict uinput to steam group instead of all logged-in users
          KERNEL=="uinput", SUBSYSTEM=="misc", TAG-="uaccess", GROUP="steam", MODE="0660"
        '';
      };

      # Create steam system group for uinput access control
      users.groups.steam = { };

      # Add user to steam group for Steam Input access
      # Note: This assumes username 'lewis' - adjust per-host if needed
      users.users.lewis.extraGroups = [ "steam" ];

      # Steam Link firewall (remotePlay.openFirewall may not cover Quest 3)
      networking.firewall = mkIf cfg.steam {
        allowedUDPPorts = [
          constants.ports.gaming.steamLink.discovery
        ]
        ++ constants.ports.gaming.steamLink.streamingUdp;
        allowedTCPPorts = [ constants.ports.gaming.steamLink.streamingTcp ];
      };

      # Note: User gaming tools (protonup-qt, steamcmd, steam-run) are configured in home-manager
      # gamescope is configured via programs.gamescope above
      environment.systemPackages = optionals cfg.steam [
        pkgs.gamescope-wsi # WSI layer for gamescope (system-level dependency)
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
