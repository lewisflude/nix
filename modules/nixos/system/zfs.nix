{ pkgs, lib, ... }:

{
  # ZFS ARC (Adaptive Replacement Cache) tuning
  # NOTE: Per-host ARC tuning is done in host configuration (e.g., jupiter: 16GB)
  # Module parameters for all ZFS systems
  boot.extraModprobeConfig = ''
    # Enable bclone support for cp --reflink and other COW operations
    # Requires ZFS 2.2.2+ with upgraded pool feature flags
    options zfs zfs_bclone_enabled=1
  '';

  # ZFS configuration and maintenance
  services.zfs = {
    # Automatic snapshots for data protection
    # Arch Wiki recommendation: snapshot at least as often as oldest backup expires
    autoSnapshot = {
      enable = true;
      frequent = 4; # Keep 4x 15min snapshots (1 hour coverage)
      hourly = 24; # Keep 24 hourly snapshots (1 day coverage)
      daily = 7; # Keep 7 daily snapshots (1 week coverage)
      weekly = 4; # Keep 4 weekly snapshots (1 month coverage)
      monthly = 12; # Keep 12 monthly snapshots (1 year coverage)
    };

    # ZFS Event Daemon (ZED) for monitoring and notifications
    zed = {
      enableMail = false; # Email notifications disabled (no mail server)
      settings = {
        ZED_NOTIFY_VERBOSE = "1"; # Verbose notifications to systemd journal
        ZED_NOTIFY_INTERVAL_SECS = "3600"; # Notify at most once per hour
        ZED_LOG_LEVEL = "notice"; # Log level: notice (info/warning/error)

        # Ensure ZFS history is logged for disaster recovery
        ZED_USE_ENCLOSURE_LEDS = "1"; # Enable disk LED notifications if supported
        ZED_SYSLOG_SUBCLASS_INCLUDE = "history_event";
      };
    };

    # Automatic TRIM for SSD/NVMe longevity and performance
    # Arch Wiki: Weekly automatic TRIM + monthly full trim recommended
    trim = {
      enable = true;
      interval = "weekly"; # Automatic TRIM weekly
    };

    # Automatic scrub for data integrity verification
    # Arch Wiki: Monthly scrubs recommended, weekly for critical data
    autoScrub = {
      enable = true;
      interval = "monthly"; # Scrub monthly (changed from weekly to reduce I/O contention)
      pools = [ "npool" ]; # Explicit pool list
    };
  };

  # Ensure ZFS pools are imported before network services start
  # This is important for services that depend on ZFS datasets
  systemd.services.zfs-import.before = [ "network-pre.target" ];

  # Monthly full TRIM service (in addition to weekly autotrim)
  # Arch Wiki: Full trim occasionally makes sense even with autotrim enabled
  systemd.services.zfs-trim-monthly = {
    description = "Monthly full ZFS TRIM on npool";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.zfs}/bin/zpool trim -w npool";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
  };

  systemd.timers.zfs-trim-monthly = {
    description = "Monthly full ZFS TRIM timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "monthly";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };

  # Add ZFS utilities to system packages for manual management
  environment.systemPackages = [
    pkgs.zfs # Core ZFS utilities (zpool, zfs, etc.)
  ];

  # Runtime ZFS dataset optimizations
  # Applied on every boot to ensure properties are correct
  # Arch Wiki recommendations: relatime > atime=off, compression, ACLs
  systemd.services.zfs-optimize-datasets = {
    description = "Optimize ZFS dataset properties";
    after = [ "zfs-import.target" ];
    before = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      # Only optimize top-level datasets to avoid processing thousands of container datasets
      # Arch Wiki: relatime is a good compromise - updates atime only if:
      # - mtime/ctime changed, OR
      # - existing atime hasn't been updated in 24 hours

      # List of main datasets to optimize (add more as needed)
      MAIN_DATASETS="npool npool/root npool/home npool/docker npool/database"

      for ds in $MAIN_DATASETS; do
        if ${pkgs.zfs}/bin/zfs list "$ds" &>/dev/null; then
          echo "Optimizing $ds..."
          # atime=off for maximum performance (no access time updates)
          # relatime is a compromise, but atime=off is better for performance workloads
          ${pkgs.zfs}/bin/zfs set atime=off "$ds" 2>/dev/null || true
          ${pkgs.zfs}/bin/zfs set xattr=sa acltype=posixacl "$ds" 2>/dev/null || true
        fi
      done

      # Workload-specific recordsize optimizations
      # Nix store: Larger recordsize (1M) improves compression ratios and read performance
      # The /nix/store lives on npool/root, so optimize root for nix store workloads
      if ${pkgs.zfs}/bin/zfs list "npool/root" &>/dev/null; then
        echo "Optimizing npool/root recordsize for Nix store (1M)..."
        ${pkgs.zfs}/bin/zfs set recordsize=1M "npool/root" 2>/dev/null || true
      fi

      # Database datasets: Smaller recordsize (16k) matches Postgres/MariaDB page sizes
      # Reduces write amplification for database workloads
      if ${pkgs.zfs}/bin/zfs list "npool/database" &>/dev/null; then
        echo "Optimizing npool/database recordsize for databases (16k)..."
        ${pkgs.zfs}/bin/zfs set recordsize=16k "npool/database" 2>/dev/null || true
      fi

      # Docker: Already optimized to 64k in disk-performance module
      # This matches Docker's default block size and reduces fragmentation

      echo "Dataset optimization complete"
    '';
  };
}
