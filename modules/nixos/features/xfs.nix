{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.xfs;
in
{
  options.features.xfs = {
    enable = lib.mkEnableOption "XFS filesystem optimizations and maintenance";

    enableScrubbing = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable periodic XFS metadata scrubbing for all XFS filesystems.
        Uses xfs_scrub to verify metadata consistency and detect corruption early.
      '';
    };

    scrubSchedule = lib.mkOption {
      type = lib.types.str;
      default = "weekly";
      description = ''
        Schedule for XFS scrubbing. Uses systemd timer calendar format.
        Default is weekly, but can be set to daily, monthly, etc.
      '';
    };

    tuneWriteback = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Tune XFS writeback interval for better performance.
        Increases fs.xfs.xfssyncd_centisecs from default 3000 (30s) to 10000 (100s).
        Warning: Larger values may increase data loss on unexpected power outages.
      '';
    };

    writebackInterval = lib.mkOption {
      type = lib.types.int;
      default = 10000;
      description = ''
        XFS writeback interval in centiseconds (100ths of a second).
        Default: 10000 (100 seconds). XFS system default: 3000 (30 seconds).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure xfsprogs is available system-wide
    environment.systemPackages = [ pkgs.xfsprogs ];

    # XFS periodic metadata scrubbing
    systemd.timers.xfs-scrub-all = lib.mkIf cfg.enableScrubbing {
      description = "Periodic XFS metadata scrubbing for all XFS filesystems";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.scrubSchedule;
        Persistent = true;
        RandomizedDelaySec = "1h"; # Spread load if multiple systems
      };
    };

    systemd.services.xfs-scrub-all = lib.mkIf cfg.enableScrubbing {
      description = "XFS metadata scrubbing service";
      documentation = [ "man:xfs_scrub(8)" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.xfsprogs}/bin/xfs_scrub_all";
        # Run as nobody user for security
        User = "nobody";
        # Allow access to mountpoints
        SupplementaryGroups = [ "disk" ];
        # Resource limits
        Nice = 19;
        IOSchedulingClass = "idle";
      };
    };

    # XFS performance tuning via sysctl
    boot.kernel.sysctl = lib.mkIf cfg.tuneWriteback {
      # Increase XFS writeback interval for better performance
      # Trade-off: Better performance vs. potential data loss on power failure
      "fs.xfs.xfssyncd_centisecs" = cfg.writebackInterval;
    };

    # Enable periodic TRIM for SSDs (also benefits XFS on any solid-state storage)
    services.fstrim = {
      enable = true;
      interval = "weekly";
    };
  };
}
