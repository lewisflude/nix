# Disk Performance Optimizations
# Host-specific: ZFS datasets assume npool/{root,home,docker}
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixosConfig.diskPerformance;
in
{
  options.nixosConfig.diskPerformance = {
    enable = lib.mkEnableOption "disk performance optimizations";

    enableVMTuning = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "VM subsystem tuning for large RAM systems";
    };

    enableIOTuning = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "I/O subsystem tuning (readahead, NCQ depth)";
    };

    enableZFSTuning = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "ZFS-specific optimizations (ARC, compression, atime)";
    };

    ramSizeGB = lib.mkOption {
      type = lib.types.int;
      default = 64;
      description = "System RAM size in GB (for documentation purposes)";
    };

    zfsARCMaxGB = lib.mkOption {
      type = lib.types.int;
      default = 48;
      description = "Maximum ZFS ARC cache size in GB (75% of RAM recommended)";
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      kernel.sysctl = lib.mkMerge [
        (lib.mkIf cfg.enableVMTuning {
          # Higher dirty ratios for large RAM - better write performance
          "vm.dirty_ratio" = lib.mkOverride 40 40;
          "vm.dirty_background_ratio" = lib.mkOverride 40 15;
          "vm.vfs_cache_pressure" = 50;
          "vm.swappiness" = lib.mkOverride 40 10;
        })

        (lib.mkIf cfg.enableIOTuning {
          # Gaming needs high max_map_count (Star Citizen, Cyberpunk 2077)
          "vm.max_map_count" = lib.mkOverride 40 (
            if config.host.features.gaming.enable or false then 2147483642 else 262144
          );
        })

        (lib.mkIf cfg.enableZFSTuning {
          "vm.min_free_kbytes" = 524288; # 512MB minimum free
        })
      ];

      kernelParams = lib.mkIf cfg.enableZFSTuning [
        "zfs.zfs_arc_max=${toString (cfg.zfsARCMaxGB * 1024 * 1024 * 1024)}"
      ];

      # ZFS dataset optimization (idempotent, runs on every boot)
      postBootCommands = lib.mkIf cfg.enableZFSTuning ''
        ${pkgs.coreutils}/bin/sleep 2
        for ds in npool/root npool/home npool/docker; do
          ${pkgs.zfs}/bin/zfs set atime=off compression=zstd-3 xattr=sa acltype=posixacl "$ds" 2>/dev/null || true
        done
        ${pkgs.zfs}/bin/zfs set recordsize=64K npool/docker 2>/dev/null || true
      '';
    };

    services.udev.extraRules = lib.mkIf cfg.enableIOTuning ''
      # HDD: NCQ depth + 2MB readahead for sequential reads
      ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{device/queue_depth}="31"
      ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{bdi/read_ahead_kb}="2048"
      # NVMe: queue depth + readahead
      ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/nr_requests}="1024"
      ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{bdi/read_ahead_kb}="512"
    '';
  };
}
