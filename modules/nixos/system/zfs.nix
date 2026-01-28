{ pkgs, lib, ...}: {

  boot.extraModprobeConfig = ''
    options zfs zfs_bclone_enabled=1
  '';

  boot.zfs = {
    extraPools = [ "npool" ];
    devNodes = "/dev/disk/by-id";
  };

  services.zfs = {
    autoSnapshot = {
      enable = true;
      frequent = 4;
      hourly = 24;
      daily = 7;
      weekly = 4;
      monthly = 12;
    };
    trim = {
      enable = true;
      interval = "weekly";
    };
    autoScrub = {
      enable = true;
      interval = "monthly";
      pools = [ "npool" ];
    };
  };
  environment.systemPackages = [ pkgs.zfs ];
}
