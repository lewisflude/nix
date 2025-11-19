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
      # Proton/Wine games need full 32-bit audio stack to work properly
      extraCompatPackages = with pkgs; [
        pipewire
        pulseaudio
        libpulseaudio
      ];
    };

    # Set audio environment variables for Steam/Proton games
    # SDL_AUDIODRIVER forces SDL games to use PulseAudio (PipeWire compat layer)
    # PULSE_SERVER lets PipeWire auto-detect (empty = auto)
    # PULSE_LATENCY_MSEC ensures reasonable buffer for games
    # These fix games not appearing in audio mixer
    environment.sessionVariables = mkIf cfg.steam {
      SDL_AUDIODRIVER = "pulseaudio";
      PULSE_LATENCY_MSEC = "60";
      PIPEWIRE_LATENCY = "256/48000";
    };

    # Ensure PipeWire PulseAudio socket is available system-wide
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
