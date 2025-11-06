{
  pkgs,
  lib,
  config,
  ...
}:
let
  zfsKernelModuleAttr = pkgs.zfs.kernelModuleAttribute;

  # Check if a kernel package is compatible with ZFS
  isZfsCompatible =
    kernelPackages:
    let
      hasZfsModule = builtins.hasAttr zfsKernelModuleAttr kernelPackages;
      zfsModuleEval =
        if hasZfsModule then
          builtins.tryEval kernelPackages.${zfsKernelModuleAttr}
        else
          {
            success = false;
            value = null;
          };
    in
    zfsModuleEval.success && (!(zfsModuleEval.value.meta.broken or false));

  # Find all ZFS-compatible kernel packages
  zfsCompatibleKernelPackages = lib.filterAttrs (
    name: kernelPackages:
    (builtins.match "linux_[0-9]+_[0-9]+" name) != null
    && (builtins.tryEval kernelPackages).success
    && isZfsCompatible kernelPackages
  ) pkgs.linuxKernel.packages;

  compatibleKernelList = builtins.attrValues zfsCompatibleKernelPackages;
  latestKernelPackage =
    if compatibleKernelList != [ ] then
      lib.last (
        lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) compatibleKernelList
      )
    else
      pkgs.linuxPackages;

in
{
  boot = {
    kernelPackages = lib.mkDefault latestKernelPackage;
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

    zfs.package = pkgs.zfs;
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

  # Assert that the selected kernel is compatible with ZFS
  assertions = [
    {
      assertion = isZfsCompatible config.boot.kernelPackages;
      message = ''
        The selected kernel (${config.boot.kernelPackages.kernel.version}) is not compatible with ZFS ${pkgs.zfs.version}.
        Please select a compatible kernel or update ZFS to a version that supports this kernel.
      '';
    }
  ];

}
