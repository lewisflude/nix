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
    autoScrub = {
      enable = true;
      interval = "weekly";
    };
  };
}
