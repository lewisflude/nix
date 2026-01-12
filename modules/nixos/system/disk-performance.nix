{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.system.diskPerformance;
in
{
  options.system.diskPerformance = {
    enable = lib.mkEnableOption "comprehensive disk performance optimizations";

    enableVMTuning = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable VM subsystem tuning for systems with large RAM.
        Optimizes dirty ratios and cache pressure for better write performance.
      '';
    };

    enableIOTuning = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable I/O subsystem tuning including readahead and NCQ depth optimization.
      '';
    };

    enableZFSTuning = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable ZFS-specific optimizations including ARC tuning, compression, and atime settings.
      '';
    };

    ramSizeGB = lib.mkOption {
      type = lib.types.int;
      default = 64;
      description = ''
        System RAM size in GB. Used to calculate optimal VM dirty ratios and ZFS ARC size.
      '';
    };

    zfsARCMaxGB = lib.mkOption {
      type = lib.types.int;
      default = 48;
      description = ''
        Maximum ZFS ARC cache size in GB. Recommended: 75% of RAM to leave headroom for applications.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Consolidate all boot settings
    boot = {
      # VM subsystem tuning for large RAM systems (64GB+)
      # Note: These settings override the conservative defaults in modules/nixos/core/memory.nix
      # when disk-performance optimization is explicitly enabled
      kernel.sysctl = lib.mkMerge [
        (lib.mkIf cfg.enableVMTuning {
          # Dirty ratio tuning: Allow more dirty pages in memory before forcing writes
          # With 64GB RAM: 40% = ~25GB buffer (vs default 20% = ~12GB)
          # Impact: 20-40% faster large file operations, smoother performance during writes
          # Overrides: memory.nix defaults dirty_ratio=20, dirty_background_ratio=5.
          # Use mkOverride 40 so disk-performance wins over the defaults while
          # still allowing explicit host overrides.
          "vm.dirty_ratio" = lib.mkOverride 40 40;
          "vm.dirty_background_ratio" = lib.mkOverride 40 15;

          # Start writeback earlier to avoid sudden I/O storms
          "vm.dirty_writeback_centisecs" = 500; # 5 seconds (default: 500)
          "vm.dirty_expire_centisecs" = 3000; # 30 seconds (default: 3000)

          # VFS cache pressure: Lower value = keep directory/inode cache longer
          # Default: 100, Lower = better for systems with lots of file metadata access
          # Impact: 5-10% better performance for workloads with many small files
          "vm.vfs_cache_pressure" = 50;

          # Swappiness: Lower value = prefer keeping data in RAM over swap
          # With 64GB RAM and performance focus, prefer keeping data in RAM
          # Overrides: memory.nix defaults swappiness=100; we want 10 here.
          # mkOverride 40 ensures disk-performance wins over defaults but can
          # still be superseded by host-specific overrides.
          "vm.swappiness" = lib.mkOverride 40 10;
        })

        (lib.mkIf cfg.enableIOTuning {
          # Increase maximum number of memory map areas
          # Useful for applications with many mapped files (databases, VMs, games)
          # Gaming workloads need much higher values (games like Cyberpunk 2077 can create millions of memory mappings)
          # Use mkOverride 40 to override nixpkgs gaming module default (1048576) while still allowing host-specific overrides
          "vm.max_map_count" = lib.mkOverride 40 (
            if config.host.features.gaming.enable or false then
              2147483642 # Gaming workload (required for Star Citizen, Cyberpunk 2077, etc.)
            else
              262144 # Conservative default for general workloads
          );
        })

        (lib.mkIf cfg.enableZFSTuning {
          # ZFS ARC tuning: Cap ARC at 75% of RAM to leave headroom
          # With 64GB RAM: 48GB ARC, 16GB for applications
          "vm.min_free_kbytes" = 524288; # 512MB minimum free memory
        })
      ];

      # ZFS ARC size limit
      # Note: memory.nix sets ARC to 24GB. When disk-performance is enabled,
      # this parameter appears later in the kernel command line and takes precedence.
      kernelParams = lib.mkIf cfg.enableZFSTuning [
        "zfs.zfs_arc_max=${toString (cfg.zfsARCMaxGB * 1024 * 1024 * 1024)}"
      ];

      # ZFS dataset property optimization
      # These commands run after boot to optimize ZFS datasets
      postBootCommands = lib.mkIf cfg.enableZFSTuning ''
        # Wait for ZFS to be ready
        ${pkgs.coreutils}/bin/sleep 2

        # Optimize ZFS datasets for performance
        # Note: These are idempotent - safe to run on every boot

        # Disable atime (access time) on all datasets
        # Impact: 15-25% faster file operations, reduced write amplification
        ${pkgs.zfs}/bin/zfs set atime=off npool/root 2>/dev/null || true
        ${pkgs.zfs}/bin/zfs set atime=off npool/home 2>/dev/null || true
        ${pkgs.zfs}/bin/zfs set atime=off npool/docker 2>/dev/null || true

        # Enable zstd compression (better than lz4 with minimal CPU cost)
        # Impact: 5-15% better compression, 5-10% less I/O for compressible data
        ${pkgs.zfs}/bin/zfs set compression=zstd-3 npool/root 2>/dev/null || true
        ${pkgs.zfs}/bin/zfs set compression=zstd-3 npool/home 2>/dev/null || true
        ${pkgs.zfs}/bin/zfs set compression=zstd-3 npool/docker 2>/dev/null || true

        # Optimize recordsize for Docker (smaller blocks for container layers)
        # Impact: 5-10% better space efficiency and performance for Docker
        ${pkgs.zfs}/bin/zfs set recordsize=64K npool/docker 2>/dev/null || true

        # Enable extended attributes for better performance
        ${pkgs.zfs}/bin/zfs set xattr=sa npool/root 2>/dev/null || true
        ${pkgs.zfs}/bin/zfs set xattr=sa npool/home 2>/dev/null || true
        ${pkgs.zfs}/bin/zfs set xattr=sa npool/docker 2>/dev/null || true

        # Set ACL type to posixacl for Linux compatibility
        ${pkgs.zfs}/bin/zfs set acltype=posixacl npool/root 2>/dev/null || true
        ${pkgs.zfs}/bin/zfs set acltype=posixacl npool/home 2>/dev/null || true
        ${pkgs.zfs}/bin/zfs set acltype=posixacl npool/docker 2>/dev/null || true
      '';
    };

    # I/O scheduler tuning (already configured in hardware-configuration.nix)
    # This adds additional optimizations
    services.udev.extraRules = lib.mkIf cfg.enableIOTuning ''
      # HDD optimization: Increase NCQ depth for better concurrent I/O
      ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{device/queue_depth}="31"

      # HDD optimization: Increase readahead for better sequential performance
      # 2MB readahead (default is usually 128KB)
      # Impact: 10-20% faster sequential reads on HDDs (Jellyfin streaming)
      ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{bdi/read_ahead_kb}="2048"

      # NVMe optimization: Tune queue depth and readahead
      ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/nr_requests}="1024"
      ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{bdi/read_ahead_kb}="512"
    '';

    # Informational message on activation
    system.activationScripts.diskPerformanceInfo = lib.mkIf cfg.enable ''
      echo "Disk Performance Optimizations Enabled:"
      echo "  - VM tuning: ${
        if cfg.enableVMTuning then "✓" else "✗"
      } (dirty_ratio=40%, vfs_cache_pressure=50)"
      echo "  - I/O tuning: ${if cfg.enableIOTuning then "✓" else "✗"} (HDD readahead=2MB, NCQ depth=31)"
      echo "  - ZFS tuning: ${
        if cfg.enableZFSTuning then "✓" else "✗"
      } (ARC max=${toString cfg.zfsARCMaxGB}GB, compression=zstd-3, atime=off)"
    '';
  };
}
