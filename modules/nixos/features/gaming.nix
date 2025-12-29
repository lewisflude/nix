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

    # Gaming-specific kernel parameters
    boot.kernel.sysctl = {
      # Memory management - essential for some Windows games via Wine/Proton
      # Must override disk-performance.nix's conservative value (262144)
      # Games like Cyberpunk 2077 can create millions of memory mappings
      "vm.max_map_count" = lib.mkForce 2147483642;

      # Note: vm.swappiness and vm.vfs_cache_pressure are already optimally
      # configured in disk-performance.nix (swappiness=10, vfs_cache_pressure=50)
    };

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

        # Complete audio stack for game compatibility
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

        # Steam wrapper: Ensure NVIDIA encoding libraries are accessible for Remote Play streaming
        # Steam Remote Play needs NVENC for hardware-accelerated encoding to Quest 3
        # Without this, Steam may fall back to software encoding which can fail or perform poorly
        # Note: If VR is enabled, VR module will handle Steam wrapping (includes NVIDIA encoding)
        package = lib.mkIf (!(config.host.features.vr.enable or false)) (
          pkgs.steam.overrideAttrs (oldAttrs: {
            buildCommand = (oldAttrs.buildCommand or "") + ''
              wrapProgram $out/bin/steam \
                --set LD_LIBRARY_PATH "${config.hardware.nvidia.package}/lib:''${LD_LIBRARY_PATH:-}" \
                --set __GLX_VENDOR_LIBRARY_NAME "nvidia" \
                --set GBM_BACKEND "nvidia-drm"
            '';
            nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
          })
        );

        # Note: pressure-vessel audio issues were fixed in nixpkgs PR #114024 (2021)
        # No custom package override needed - using stock Steam
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
            # Note: NVIDIA GPU optimizations handled by driver
            # AMD-specific settings (amd_performance_level) not applicable
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
        # Enable CUDA support for NVENC hardware encoding
        # Without this, Sunshine can't load libcuda.so.1 and falls back to software encoding
        # See: https://discourse.nixos.org/t/rtx-3070-sunshine-nvec-encoding-fails/62131
        package = pkgs.sunshine.override { cudaSupport = true; };
      };

      udev = mkIf cfg.enable {
        packages = [
          pkgs.game-devices-udev-rules
        ];
      };
    };

    # Explicit Steam Link firewall ports for Quest 3 compatibility
    # These ports are used by Steam Link for discovery and streaming
    # Note: remotePlay.openFirewall should handle these, but explicit rules ensure compatibility
    # with Quest 3 and other Steam Link clients that may have stricter requirements
    networking.firewall = mkIf cfg.steam {
      allowedUDPPorts = [
        27031 # Steam Link discovery
        27036 # Steam Link streaming
        27037 # Steam Link streaming
      ];
      allowedTCPPorts = [
        27036 # Steam Link streaming
      ];
    };

    hardware.uinput.enable = mkIf cfg.enable true;

    # Add user to input group for Sunshine KMS capture
    users.users.lewis = mkIf cfg.steam {
      extraGroups = [ "input" ];
    };

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
