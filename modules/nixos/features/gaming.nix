# Gaming feature module for NixOS
# Controlled by host.features.gaming.*
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.host.features.gaming;
in {
  config = mkIf cfg.enable {
    # Steam configuration with enhanced features
    programs.steam = mkIf cfg.steam {
      enable = true;
      gamescopeSession.enable = true;
      protontricks.enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      package = pkgs.steam.override {
        extraPkgs = pkgs:
          with pkgs; [
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

    # Sunshine game streaming service
    services.sunshine = mkIf cfg.steam {
      enable = true;
      package = pkgs.sunshine.override {cudaSupport = true;};
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
    };

    # Gaming device udev rules
    services.udev = mkIf cfg.enable {
      packages = with pkgs; [
        game-devices-udev-rules
      ];
    };

    # Enable uinput for virtual input devices
    hardware.uinput.enable = mkIf cfg.enable true;

    # Gaming performance optimizations
    boot.kernel.sysctl = mkIf cfg.performance {
      "vm.max_map_count" = 2147483642; # Needed for some games
    };

    # Install gaming-related packages
    environment.systemPackages = with pkgs;
      []
      ++ optionals cfg.steam [
        steamcmd
        steam-run
      ]
      ++ optionals cfg.performance [
        mangohud
        gamemode
      ];

    # Gamemode for performance
    programs.gamemode = mkIf cfg.performance {
      enable = true;
    };
  };
}
