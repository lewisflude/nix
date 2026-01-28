{
  config,
  lib,
  ...
}:
{
  config = {
    boot = {
      loader.systemd-boot = {
        enable = lib.mkDefault true;
        editor = false;
        configurationLimit = lib.mkDefault 10;
      };

      supportedFilesystems = [ "zfs" ];
      zfs.forceImportRoot = true;
    };

    services.fstrim.enable = true;
  };
}
