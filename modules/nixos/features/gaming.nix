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
    # ESYNC fallback still benefits from 1,048,576 FDs, so raise the shared limit
    host.systemDefaults.fileDescriptorLimit = lib.mkOverride 60 1048576;

    # Wine/Proton synchronization optimizations
    #
    # FSYNC (futex synchronization) - Preferred method (kernel 5.16+)
    # - Uses Linux futexes for thread synchronization
    # - More efficient than ESYNC, no file descriptor limits needed
    # - Automatically enabled by Wine/Proton when kernel support detected
    # - Kernel 6.6+ has full FUTEX2 support (this system: 6.6.112-rt63)
    #
    # ESYNC (eventfd synchronization) - Fallback method
    # - Uses eventfd for synchronization when FSYNC unavailable
    # - Requires high file descriptor limits (1,048,576)
    # - Still useful as fallback for older Wine versions
    #
    # Audio environment variables are now configured in modules/nixos/features/desktop/audio.nix

    programs = {
      steam = mkIf cfg.steam {
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
          pkgs.proton-ge-bin # GE-Proton for improved game compatibility
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
            # Use direct path since XDG_RUNTIME_DIR is always /run/user/UID
            PULSE_SERVER = "unix:/run/user/1000/pulse/native";
          };
        };
      };

      # Gamescope compositor for improved gaming experience
      # Supports HDR, frame limiting, FSR upscaling, and more
      gamescope = mkIf cfg.steam {
        enable = true;
        # capSysNice doesn't work with Steam's nested bubblewrap (FHS + Steam Runtime)
        # Use ananicy instead to manage process priority
        capSysNice = false;
      };

      gamemode = mkIf cfg.performance {
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
    };

    services = {
      # ananicy-cpp manages process priorities for gamescope and games
      # This is a workaround for capSysNice not working in Steam's nested bubblewrap
      ananicy = mkIf cfg.steam {
        enable = true;
        package = pkgs.ananicy-cpp;
        rulesProvider = pkgs.ananicy-rules-cachyos; # Includes quality rules for gamescope and games
      };

      sunshine = mkIf cfg.steam {
        enable = true;
        autoStart = true;
        capSysAdmin = true;
        openFirewall = true;
      };

      udev = mkIf cfg.enable {
        packages = [
          pkgs.game-devices-udev-rules
        ];
      };
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
      pkgs.gamescope-wsi # Required for HDR support in Gamescope
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
