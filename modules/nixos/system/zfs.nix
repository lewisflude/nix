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
      enableMail = false;
      settings = {
        ZED_NOTIFY_VERBOSE = "1";
        ZED_NOTIFY_INTERVAL_SECS = "3600";
        ZED_LOG_LEVEL = "notice";
      };
    };
    trim = {
      enable = true;
      interval = "weekly";
    };
    autoScrub = {
      enable = true;
      interval = "weekly";
    };
  };
}
