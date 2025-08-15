{
  services.zfs = {
    autoSnapshot = {
      enable = true;
      frequent = 0;
      hourly = 0;
      daily = 7;
      weekly = 2;
      monthly = 1;
    };
    zed = {
      # Optional: send emails (requires an MTA configured separately)
      enableMail = false;
      # zed.rc key/values written to /etc/zfs/zed.d/zed.rc
      settings = {
        ZED_NOTIFY_VERBOSE = "1"; # more detailed notifications/logs
        ZED_NOTIFY_INTERVAL_SECS = "3600"; # rate-limit repeated events
        ZED_LOG_LEVEL = "notice"; # notice|info|warning
        # Examples you can add if desired:
        # ZED_SYSLOG_PRIORITY = "daemon.notice";
        # ZED_EMAIL_ADDR = "you@example.com";   # if enableMail = true and MTA present
      };
    };
    trim = {
      enable = true;
      interval = "weekly";
    }; # trim is used to clean up unused space on the disk (zfs)
    autoScrub = {
      enable = true;
      interval = "weekly";
    };
  };
}
