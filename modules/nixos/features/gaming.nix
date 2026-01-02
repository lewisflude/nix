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
  # GPU ID can be configured per-host via host.hardware.gpuID
  # Default to empty string to allow auto-detection when not set
  gpuID = config.host.hardware.gpuID or "";
in
{
  config = mkIf cfg.enable {
    # ESYNC fallback still benefits from 1,048,576 FDs, so raise the shared limit
    # FSYNC (futex synchronization) is preferred on kernel 5.16+ and doesn't need
    # high file descriptor limits, but ESYNC (eventfd synchronization) is still
    # used as a fallback and requires this setting for Wine/Proton compatibility
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

    programs = {
      steam = mkIf cfg.steam {
        enable = true;
        gamescopeSession.enable = false; # We use standalone gamescope instead
        protontricks.enable = true; # Useful for Wine prefix debugging
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;

        # Modern Steam handles audio properly via pressure-vessel
        # The extensive audio stack (PulseAudio/PipeWire/ALSA) that was previously
        # added here is no longer needed - fixed in nixpkgs PR #114024 (2021)
        extraCompatPackages = [
          pkgs.proton-ge-bin # GE-Proton for improved game compatibility
        ];

        # Note: VR-specific Steam wrapping (NVIDIA libraries, XR_RUNTIME_JSON)
        # is handled by the VR module (modules/nixos/features/vr.nix) to avoid
        # duplication and conflicts when both features are enabled
      };

      # Gamescope compositor for improved gaming experience
      # Supports HDR, frame limiting, FSR upscaling, and more
      gamescope = mkIf cfg.steam {
        enable = true;
        # capSysNice doesn't work with Steam's nested bubblewrap (FHS + Steam Runtime)
        # Use ananicy instead to manage process priority
        capSysNice = false;

        # Conditionally add GPU preference if gpuID is configured
        # If not set, gamescope will auto-detect the GPU
        args = optionals (gpuID != "") [ "--prefer-vk-device ${gpuID}" ] ++ [
          "--hdr-enabled"
        ];
      };

      gamemode = mkIf cfg.performance {
        enable = true;
        settings = {
          general = {
            renice = 10;
          };
          gpu = {
            apply_gpu_optimisations = "accept-responsibility";
            gpu_device = 0; # Primary GPU
            # Note: NVIDIA GPU optimizations are handled by the driver
            # AMD-specific settings (amd_performance_level) are not applicable
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

      # Sunshine game streaming is configured via home-manager
      # See: home/nixos/apps/sunshine.nix for KMS capture and NVENC settings
      # The service itself is enabled in modules/nixos/features/gaming.nix when
      # cfg.steam is true, with CAP_SYS_ADMIN for KMS capture
      sunshine = mkIf cfg.steam {
        enable = true;
        autoStart = true;
        capSysAdmin = true;
        openFirewall = true;
        # Enable CUDA support for NVENC hardware encoding
        # Without this, Sunshine can't load libcuda.so.1 and falls back to software encoding
        package = pkgs.sunshine.override { cudaSupport = true; };
      };

      # Controller and Bluetooth udev rules
      udev = {
        packages = [
          pkgs.game-devices-udev-rules
        ];

        # Disable USB autosuspend for game controllers and Bluetooth adapters
        # This prevents Steam Input crashes and HID read failures when controllers idle
        # Issue: USB autosuspend can cause "Controller device closed after hid_read failure"
        extraRules = ''
          # USB game controllers - disable autosuspend to prevent Steam Input crashes

          # Sony PlayStation controllers (DualSense, DualShock 4, etc.)
          ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="054c", TEST=="power/control", ATTR{power/control} = "on"

          # Microsoft Xbox controllers
          ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="045e", TEST=="power/control", ATTR{power/control} = "on"

          # Logitech game controllers and receivers
          ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", TEST=="power/control", ATTR{power/control} = "on"

          # Nintendo Switch Pro Controller and Joy-Cons
          ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="057e", TEST=="power/control", ATTR{power/control} = "on"

          # SteelSeries controllers
          ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1038", TEST=="power/control", ATTR{power/control} = "on"

          # Razer controllers
          ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1532", TEST=="power/control", ATTR{power/control} = "on"

          # 8BitDo controllers
          ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2dc8", TEST=="power/control", ATTR{power/control} = "on"

          # Generic HID gamepad class (catches other controllers)
          ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="03", ATTR{bInterfaceSubClass}=="01", ATTR{bInterfaceProtocol}=="01", TEST=="power/control", ATTR{power/control} = "on"

          # Bluetooth adapters - keep active to prevent controller disconnections
          # This is critical for maintaining stable connections to Bluetooth game controllers
          ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="btusb", TEST=="power/control", ATTR{power/control} = "on"

          # HID devices - disable autosuspend (covers both USB and Bluetooth HID)
          # This prevents game controllers from sleeping during Steam Input polling
          ACTION=="add", SUBSYSTEM=="hid", ATTR{idVendor}=="054c", TEST=="power/control", ATTR{power/control} = "on"
          ACTION=="add", SUBSYSTEM=="hid", ATTR{idVendor}=="045e", TEST=="power/control", ATTR{power/control} = "on"
        '';
      };
    };

    # Explicit Steam Link firewall ports for Quest 3 compatibility
    # While remotePlay.openFirewall should handle these, explicit rules ensure
    # compatibility with Quest 3 and other Steam Link clients that may have
    # stricter discovery requirements
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

    # Bluetooth power management for game controllers
    # Prevent Bluetooth controllers (DualSense, etc.) from going to sleep
    # Fixes Steam Input crashes caused by HID read failures when controllers idle
    hardware.bluetooth.settings = {
      Policy = {
        # Auto-connect to known devices (helps with reconnection after sleep)
        AutoConnect = true;
      };
      General = {
        # Enable fast connectable mode for better responsiveness
        FastConnectable = true;
      };
    };

    # System packages based on enabled features
    environment.systemPackages = [
      # System-level gaming tools (always installed when gaming is enabled)
      pkgs.protonup-qt
    ]
    ++ optionals cfg.steam [
      pkgs.steamcmd
      pkgs.steam-run
      pkgs.gamescope
      pkgs.gamescope-wsi # Required for HDR support in Gamescope
    ]
    ++ optionals cfg.performance [
      pkgs.gamemode
    ]
    ++ optionals cfg.lutris [
      pkgs.lutris
    ]
    ++ optionals cfg.emulators [
      # Emulator packages can be added here when emulators feature is enabled
    ];

    # Ensure graphics support (may be redundant with graphics.nix, but safe)
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
      };
      uinput.enable = true;
    };

    # Assertions to catch configuration mistakes
    assertions = [
      {
        assertion = cfg.emulators -> cfg.enable;
        message = "Emulators require gaming feature to be enabled";
      }
    ];
  };
}
