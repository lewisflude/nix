# I/O Priority Management
# Prevents background tasks from impacting interactive performance
# Uses ionice to set I/O scheduling class and priority for systemd services
{
  config,
  lib,
  ...
}:
let
  cfg = config.nixosConfig.ioPriority;
in
{
  options.nixosConfig.ioPriority = {
    enable = lib.mkEnableOption "I/O priority management for background services";

    backgroundServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        List of systemd services to run at idle I/O priority.
        These services will not impact interactive performance.
        Useful for: backups, builds, media scanning, TRIM operations.
      '';
      example = [
        "nix-daemon"
        "docker"
        "backup"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    # Apply idle I/O scheduling to specified services
    # IOSchedulingClass options:
    #   0 = none (default)
    #   1 = realtime (dangerous, root only)
    #   2 = best-effort (default for most services)
    #   3 = idle (only when no other I/O, perfect for background tasks)
    # IOSchedulingPriority: 0-7, where 0 is highest (only for best-effort/realtime)
    systemd.services = lib.mkMerge [
      # Apply to user-configured background services
      (lib.mkMerge (
        map (serviceName: {
          ${serviceName}.serviceConfig = {
            IOSchedulingClass = "idle"; # Only use idle I/O time
            IOSchedulingPriority = 7; # Lowest priority within class
          };
        }) cfg.backgroundServices
      ))

      # Apply to common system maintenance services
      {
        fstrim.serviceConfig = {
          IOSchedulingClass = "idle";
          IOSchedulingPriority = 7;
        };
      }

      # ZFS scrub and trim (if ZFS is enabled)
      (lib.mkIf (config.services.zfs.autoScrub.enable or false) {
        zfs-scrub.serviceConfig = {
          IOSchedulingClass = "idle";
          IOSchedulingPriority = 7;
        };
      })

      (lib.mkIf (config.services.zfs.trim.enable or false) {
        zfs-trim-monthly.serviceConfig = {
          IOSchedulingClass = "idle";
          IOSchedulingPriority = 7;
        };
      })

      # Nix operations (builds, garbage collection) - be careful with these
      # Only enable if you're okay with slower builds in exchange for better desktop responsiveness
      (lib.mkIf (builtins.elem "nix-daemon" cfg.backgroundServices) {
        nix-daemon.serviceConfig = {
          IOSchedulingClass = "best-effort"; # Don't use idle for nix-daemon, it needs responsive I/O
          IOSchedulingPriority = 7; # But lowest priority within best-effort
        };
      })

      (lib.mkIf (config.nix.gc.automatic or false) {
        nix-gc.serviceConfig = {
          IOSchedulingClass = "idle";
          IOSchedulingPriority = 7;
        };
      })
    ];
  };
}
