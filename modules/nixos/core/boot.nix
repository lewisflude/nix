{
  lib,
  pkgs,
  ...
}:

{
  boot = {
    # Default to stable kernel with ZFS support
    # Hosts can override with specific kernels (e.g., XanMod for gaming)
    kernelPackages = lib.mkDefault pkgs.linuxPackages;

    loader = {
      systemd-boot = {
        enable = lib.mkDefault true;
        editor = false; # Security: Prevent boot parameter editing without authentication
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = lib.mkDefault true;
      timeout = lib.mkDefault 0;
    };

    # ZFS Support
    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = false; # Best practice for modern ZFS

    # Universal quiet boot parameters
    kernelParams = [
      "quiet"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
    ];

    # Suppress verbose boot messages
    consoleLogLevel = 0;
    initrd.verbose = false;
  };
}
