{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.host.features.cachyos-kernel;

  # Check if ZFS is enabled
  zfsEnabled = builtins.elem "zfs" config.boot.supportedFilesystems;

  # ZFS compatibility check for CachyOS kernel
  # Note: CachyOS kernels include ZFS support via zfs_cachyos module
  isZfsCompatible =
    kernelPackages:
    let
      zfsModuleEval = builtins.tryEval (
        kernelPackages.zfs_cachyos or kernelPackages.zfs or { meta.broken = true; }
      );
    in
    zfsModuleEval.success && (!(zfsModuleEval.value.meta.broken or false));

  # Select CachyOS kernel variant
  # Available variants: cachyos, cachyos-lto, cachyos-hardened, cachyos-server, cachyos-lts
  selectedKernel = pkgs.linuxPackages_cachyos; # Default: EEVDF-BORE scheduler

  # Verify ZFS compatibility if ZFS is enabled
  kernelPackages =
    if zfsEnabled then
      (
        if isZfsCompatible selectedKernel then
          selectedKernel
        else
          throw "CachyOS kernel ${selectedKernel.kernel.version} is not compatible with ZFS. Use cachyos-lts or disable ZFS."
      )
    else
      selectedKernel;
in
{
  options.host.features.cachyos-kernel = {
    enable = lib.mkEnableOption "CachyOS kernel with EEVDF-BORE scheduler and optimizations";

    enableSchedExt = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable sched-ext schedulers (requires kernel 6.12+).
        Provides userspace schedulers like scx_rustland, scx_rusty, etc.
      '';
    };

    schedExtScheduler = lib.mkOption {
      type = lib.types.str;
      default = "scx_rustland";
      description = ''
        Which sched-ext scheduler to use.
        Available: scx_rustland, scx_rusty, scx_lavd, scx_bpfland, etc.
      '';
    };

    schedExtPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.scx_git.full;
      description = ''
        Which scx package to use.
        Options: pkgs.scx (stable) or pkgs.scx_git.full (bleeding-edge)
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # Base CachyOS kernel configuration
      {
        boot.kernelPackages = lib.mkForce kernelPackages;

        # Recommended kernel parameters for CachyOS
        boot.kernelParams = [
          "transparent_hugepage=madvise"
          "processor.max_cstate=1"
        ];
      }

      # Optional: sched-ext scheduler support
      (lib.mkIf cfg.enableSchedExt {
        services.scx = {
          enable = true;
          scheduler = cfg.schedExtScheduler;
          package = cfg.schedExtPackage;
        };
      })
    ]
  );
}
