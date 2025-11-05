# Gaming feature module for NixOS
# Controlled by host.features.gaming.*
# Integrates Chaotic-Nyx gaming packages and performance optimizations
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
    # Steam configuration with enhanced features
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

    # Sunshine game streaming service
    services.sunshine = mkIf cfg.steam {
      enable = true;
      package = pkgs.sunshine.override { cudaSupport = true; };
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

    # Chaotic-Nyx gaming optimizations
    # Use CachyOS kernel for gaming performance (if performance is enabled)
    # Use mkForce to override the default kernel from boot.nix
    boot.kernelPackages = mkIf cfg.performance (mkForce pkgs.linuxPackages_cachyos);

    # Enable bleeding-edge Mesa drivers for better gaming performance
    chaotic.mesa-git.enable = mkIf cfg.performance true;

    # Install gaming-related packages
    environment.systemPackages =
      with pkgs;
      [
        # Core gaming tools
        protonup-qt # Proton version manager
        wine # Windows compatibility layer
        winetricks # Wine utilities
      ]
      # Steam packages
      ++ optionals cfg.steam [
        steamcmd
        steam-run
        # Chaotic-Nyx bleeding-edge gaming packages
        gamescope_git # Latest Gamescope for better performance
      ]
      # Performance tools
      ++ optionals cfg.performance [
        mangohud_git # Bleeding-edge MangoHud from Chaotic-Nyx (preferred over stable)
        gamemode # Performance optimization daemon
      ]
      # Lutris game manager
      ++ optionals cfg.lutris [
        lutris
      ]
      # Emulators
      ++ optionals cfg.emulators [
        # Add popular emulators here
        # dolphin-emu # GameCube/Wii
        # pcsx2 # PlayStation 2
        # rpcs3 # PlayStation 3
      ];

    # Gamemode for performance optimization
    programs.gamemode = mkIf cfg.performance {
      enable = true;
      settings = {
        general = {
          renice = 10;
        };
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 0;
          # AMD performance level (adjust for NVIDIA if needed)
          amd_performance_level = "high";
        };
      };
    };

    # Graphics drivers & OpenGL support
    hardware.graphics = mkIf cfg.enable {
      enable = true;
      enable32Bit = true; # For 32-bit games
    };

    # Assertions
    assertions = [
      {
        assertion = cfg.emulators -> cfg.enable;
        message = "Emulators require gaming feature to be enabled";
      }
    ];
  };
}
