{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.nixosConfig.boot = {
    enableTscClocksource = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable TSC (Time Stamp Counter) as the system clocksource.
        Provides ~50x higher throughput than HPET/ACPI_PM for clock_gettime() calls.

        WARNING: Only enable if your CPU has a reliable TSC. Test after enabling.
        Modern CPUs (Intel Core 2nd gen+, AMD Zen+) typically support this.

        If enabled and system crashes or Firefox has random crashes, disable immediately.
      '';
    };
  };

  config = {
    boot = {
      # Default to stable kernel with ZFS support
      # Hosts can override with specific kernels (e.g., XanMod for gaming)
      kernelPackages = lib.mkDefault pkgs.linuxPackages;

      loader = {
        systemd-boot = {
          enable = lib.mkDefault true;
          editor = false; # Security: Prevent boot parameter editing without authentication
          configurationLimit = lib.mkDefault 10;
        };
        efi.canTouchEfiVariables = lib.mkDefault true;
        timeout = lib.mkDefault 0;
      };

      # ZFS Support
      supportedFilesystems = [ "zfs" ];
      zfs.forceImportRoot = false; # Best practice for modern ZFS

      # Initramfs optimizations for faster boot
      initrd = {
        verbose = false;
        systemd.enable = true; # Use systemd in initrd for parallel initialization

        # Use zstd compression (good balance of speed and size)
        # Note: lz4 is currently broken in NixOS unstable (uses wrong package output)
        compressor = "zstd";
        compressorArgs = [
          "-1" # Fast compression level
          "-T0" # Use all CPU threads
        ];
      };

      # Universal quiet boot parameters
      kernelParams = [
        "quiet"
        "loglevel=3"
        "rd.systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
      ]
      ++ lib.optionals config.nixosConfig.boot.enableTscClocksource [
        # TSC clocksource: ~50x higher throughput than HPET for clock_gettime()
        # Games make extensive clock_gettime() calls for physics/fps calculations
        # See: https://wiki.archlinux.org/title/Gaming#Improve_clock_gettime_throughput
        "tsc=reliable"
        "clocksource=tsc"
      ];

      # Suppress verbose boot messages
      consoleLogLevel = 0;
    };
  };
}
