{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkForce;
  inherit (lib.lists) optionals;
  cfg = config.host.features.gaming;
in
{
  config = mkIf cfg.enable {

    programs.steam = mkIf cfg.steam {
      enable = true;
      gamescopeSession.enable = true;
      protontricks.enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;

      package = pkgs.steam.override {
        extraPkgs =
          pkgs: with pkgs; [
            xorg.libXcursor
            xorg.libXi
            xorg.libXinerama
            xorg.libXScrnSaver
            libpng
            libpulseaudio
            libvorbis
            stdenv.cc.cc.lib
            libkrb5
            keyutils
          ];
      };
    };

    services.sunshine = mkIf cfg.steam {
      enable = true;
      package = pkgs.sunshine.override { cudaSupport = true; };
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
    };

    services.udev = mkIf cfg.enable {
      packages = with pkgs; [
        game-devices-udev-rules
      ];
    };

    hardware.uinput.enable = mkIf cfg.enable true;

    boot.kernel.sysctl = mkIf cfg.performance {
      "vm.max_map_count" = 2147483642;
    };

    boot.kernelPackages = mkIf cfg.performance (mkForce pkgs.linuxPackages_cachyos);

    chaotic.mesa-git.enable = mkIf cfg.performance true;

    environment.systemPackages =
      with pkgs;
      [

        protonup-qt
        wine
        winetricks
      ]

      ++ optionals cfg.steam [
        steamcmd
        steam-run

        gamescope
      ]

      ++ optionals cfg.performance [
        mangohud
        gamemode
      ]

      ++ optionals cfg.lutris [
        lutris
      ]

      ++ optionals cfg.emulators [

      ];

    programs.gamemode = mkIf cfg.performance {
      enable = true;
      settings = {
        general = {
          renice = 10;
        };
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 0;

          amd_performance_level = "high";
        };
      };
    };

    hardware.graphics = mkIf cfg.enable {
      enable = true;
      enable32Bit = true;
    };

    assertions = [
      {
        assertion = cfg.emulators -> cfg.enable;
        message = "Emulators require gaming feature to be enabled";
      }
    ];
  };
}
