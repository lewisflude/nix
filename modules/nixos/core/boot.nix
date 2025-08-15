{
  pkgs,
  lib,
  config,
  ...
}:
let
  zfsCompatibleKernelPackages = lib.filterAttrs (
    name: kernelPackages:
    (builtins.match "linux_[0-9]+_[0-9]+" name) != null
    && (builtins.tryEval kernelPackages).success
    && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
  ) pkgs.linuxKernel.packages;
  latestKernelPackage = lib.last (
    lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
      builtins.attrValues zfsCompatibleKernelPackages
    )
  );
in
{
  boot = {
    kernelPackages = latestKernelPackage;
    loader.grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      zfsSupport = true;
      mirroredBoots = [
        {
          devices = [ "nodev" ];
          path = "/boot";
        }
      ];
    };
    zfs.package = pkgs.zfs_unstable;
    supportedFilesystems = [ "zfs" ];
    loader.timeout = 0;
    kernelParams = [
      "quiet"
      "splash"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "nvidia-drm.modeset=1"
      "vt.global_cursor_default=0"
      "enable_fbc=1"
      "enable_psr=2"

    ]
    ++ lib.optionals (config.hardware.nvidia.package != null) [
      "nvidia.NVreg=KmemLimit=0"
    ];
    consoleLogLevel = 0;
    initrd.verbose = false;

  };
}
