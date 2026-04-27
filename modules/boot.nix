# Boot configuration module
# Provides systemd-boot and ZFS support
_: {
  flake.modules.nixos.boot =
    { lib, ... }:
    {
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
