{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.lists) optionals;
  cfg = config.host.features.gaming;
in
{
  config = mkIf cfg.enable {

    programs.steam = mkIf cfg.steam {
      enable = true;
      gamescopeSession.enable = false;
      protontricks.enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;

      # Fix for Steam/Proton games not producing audio with PipeWire
      # Provides complete audio stack for all game audio APIs:
      # - PulseAudio/libpulseaudio: For SDL2 games and Wine/Proton
      # - PipeWire: For native PipeWire-aware games
      # - ALSA libs: For FMOD games (Dwarf Fortress), OpenAL, and low-level audio
      extraCompatPackages = [
        pkgs.pipewire # PipeWire daemon and libraries
        pkgs.pulseaudio # PulseAudio daemon (for fallback)
        pkgs.libpulseaudio # PulseAudio client library
        pkgs.alsa-lib # ALSA user-space library (required for FMOD)
        pkgs.alsa-plugins # ALSA plugins including PipeWire bridge
      ];

      # Wrap Steam to fix pressure-vessel container audio issues
      # pressure-vessel tries to use /run/pressure-vessel/pulse/native which doesn't exist
      # Override to use the actual PipeWire-pulse socket location
      package = pkgs.steam.override {
        extraEnv = {
          # Force games to use host's PipeWire-pulse socket directly
          # This bypasses pressure-vessel's broken audio socket setup
          PULSE_SERVER = "unix:\${XDG_RUNTIME_DIR}/pulse/native";
        };
      };
    };

    # Audio environment variables are now configured in modules/nixos/features/desktop/audio.nix

    # Ensure PipeWire PulseAudio socket is available for Steam
    # This allows Steam and games running in different namespaces to find audio
    systemd.user.services.pipewire-pulse.environment = mkIf cfg.steam {
      PULSE_SERVER = "unix:/run/user/%U/pulse/native";
    };

    services.sunshine = mkIf cfg.steam {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
    };

    services.udev = mkIf cfg.enable {
      packages = [
        pkgs.game-devices-udev-rules
      ];
    };

    hardware.uinput.enable = mkIf cfg.enable true;

    environment.systemPackages = [
      # System-level gaming tools
      pkgs.protonup-qt
    ]

    ++ optionals cfg.steam [
      pkgs.steamcmd
      pkgs.steam-run
      pkgs.gamescope
    ]

    ++ optionals cfg.performance [
      # Note: mangohud is configured via home-manager programs.mangohud
      pkgs.gamemode
    ]

    ++ optionals cfg.lutris [
      pkgs.lutris
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
