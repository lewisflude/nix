{ pkgs, ... }:

{
  # ZFS configuration and maintenance
  services.zfs = {
    # Automatic snapshots for data protection
    autoSnapshot = {
      enable = true;
      frequent = 0; # No frequent snapshots (every 15min)
      hourly = 0; # No hourly snapshots
      daily = 7; # Keep 7 daily snapshots
      weekly = 2; # Keep 2 weekly snapshots
      monthly = 1; # Keep 1 monthly snapshot
    };

    # ZFS Event Daemon (ZED) for monitoring and notifications
    zed = {
      enableMail = false; # Email notifications disabled
      settings = {
        ZED_NOTIFY_VERBOSE = "1"; # Verbose notifications
        ZED_NOTIFY_INTERVAL_SECS = "3600"; # Notify at most once per hour
        ZED_LOG_LEVEL = "notice"; # Log level: notice (info/warning/error)
      };
    };

    # Automatic TRIM for SSD/NVMe longevity and performance
    trim = {
      enable = true;
      interval = "weekly"; # Run TRIM weekly
    };

    # Automatic scrub for data integrity verification
    autoScrub = {
      enable = true;
      interval = "weekly"; # Scrub weekly to detect bit rot
    };
  };

  # Ensure ZFS pools are imported before network services start
  # This is important for services that depend on ZFS datasets
  systemd.services.zfs-import.before = [ "network-pre.target" ];

  # Add ZFS utilities to system packages for manual management
  environment.systemPackages = [
    pkgs.zfs # Core ZFS utilities (zpool, zfs, etc.)
  ];
}
