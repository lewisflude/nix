# System Performance Optimizations
# Comprehensive tuning based on Arch Linux performance guide
# Includes: VM/memory, I/O, network, OOM handling, and ZFS-specific optimizations
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
    enable = lib.mkEnableOption "comprehensive system performance optimizations";

    enableVMTuning = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "VM subsystem tuning for large RAM systems";
    };

    enableIOTuning = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "I/O subsystem tuning (readahead, NCQ depth, schedulers)";
    };

    enableNetworkTuning = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Network performance tuning (TCP BBR, buffer sizes)";
    };

    enableOOMHandling = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable systemd-oomd for better low-memory responsiveness";
    };

    enableZram = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable zram compressed swap (reduces SSD writes)";
    };

    zramSize = lib.mkOption {
      type = lib.types.int;
      default = 50;
      description = "Percentage of RAM to use for zram (default: 50%)";
    };

    enableZFSTuning = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "ZFS-specific optimizations (ARC, compression, atime)";
    };

    disableCoreDumps = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Disable core dumps to save disk space and improve performance";
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
    # Core dump handling
    systemd.coredump.enable = lib.mkIf cfg.disableCoreDumps false;
    systemd.settings.Manager = lib.mkIf cfg.disableCoreDumps {
      DefaultLimitCORE = "0:0";
    };

    # zram for compressed swap (reduces SSD writes, improves responsiveness)
    zramSwap = lib.mkIf cfg.enableZram {
      enable = true;
      algorithm = "zstd";
      memoryPercent = cfg.zramSize;
      priority = 100; # Higher priority than disk swap
    };

    # OOM handling for better system responsiveness under memory pressure
    systemd.oomd = lib.mkIf cfg.enableOOMHandling {
      enable = true;
      enableRootSlice = true;
      enableUserSlices = true;
      # Kill user processes before system services under memory pressure
      settings.OOM = {
        DefaultMemoryPressureDurationSec = "20s";
      };
    };

    # SSD TRIM support
    services.fstrim = {
      enable = true;
      interval = "weekly";
    };

    boot = {
      kernel.sysctl = lib.mkMerge [
        # VM/Memory tuning
        (lib.mkIf cfg.enableVMTuning {
          # Swappiness: Different values for zram vs disk swap
          # - zram: 180-200 (in-memory swap is vastly faster, set in core/memory.nix)
          # - disk swap: 10 (prefer keeping things in RAM on systems with plenty of RAM)
          # Only override to 10 when zram is explicitly disabled
          "vm.swappiness" = lib.mkIf (!cfg.enableZram) (lib.mkOverride 40 10);

          # Dirty ratio: Percentage of RAM that can be filled with dirty pages
          # Higher values = better write performance on systems with lots of RAM
          "vm.dirty_ratio" = lib.mkOverride 40 40;
          "vm.dirty_background_ratio" = lib.mkOverride 40 15;

          # Writeback time: How often (in centiseconds) dirty pages are written to disk
          # Higher = less frequent writes = better for SSDs, but more potential data loss
          "vm.dirty_writeback_centisecs" = 6000; # 60 seconds (default: 5s)

          # Cache pressure: Lower = kernel prefers keeping cache over reclaiming
          "vm.vfs_cache_pressure" = 50; # Default is 100

          # Page cache usage: How long to wait before dropping cache
          "vm.dirtytime_expire_seconds" = 43200; # 12 hours

          # Minimum free memory to maintain
          "vm.min_free_kbytes" = lib.mkIf cfg.enableZFSTuning 524288; # 512MB
        })

        # I/O tuning
        (lib.mkIf cfg.enableIOTuning {
          # Gaming needs high max_map_count (Star Citizen, Cyberpunk 2077, etc.)
          "vm.max_map_count" = lib.mkOverride 40 (
            if config.host.features.gaming.enable or false then 2147483642 else 262144
          );
        })

        # Network performance tuning (enhanced settings beyond core/networking.nix)
        (lib.mkIf cfg.enableNetworkTuning {
          # TCP Buffer sizes - larger than core defaults (64MB vs 32MB)
          "net.core.rmem_max" = lib.mkDefault 67108864; # 64MB
          "net.core.wmem_max" = lib.mkDefault 67108864; # 64MB
          "net.core.rmem_default" = lib.mkDefault 16777216; # 16MB
          "net.core.wmem_default" = lib.mkDefault 16777216; # 16MB

          # TCP memory (min, default, max in bytes)
          "net.ipv4.tcp_rmem" = lib.mkDefault "4096 87380 67108864";
          "net.ipv4.tcp_wmem" = lib.mkDefault "4096 65536 67108864";
          "net.ipv4.tcp_mem" = lib.mkDefault "67108864 67108864 67108864";

          # TCP BBR congestion control (set in core/networking.nix, reaffirm here)
          "net.core.default_qdisc" = lib.mkDefault "fq";
          "net.ipv4.tcp_congestion_control" = lib.mkDefault "bbr";

          # TCP optimizations (tcp_fastopen and tcp_mtu_probing in core/networking.nix)
          "net.ipv4.tcp_fastopen" = lib.mkDefault 3;
          "net.ipv4.tcp_slow_start_after_idle" = lib.mkDefault 0; # Additional optimization
          "net.ipv4.tcp_mtu_probing" = lib.mkDefault 1;

          # Increase connection backlog
          "net.core.somaxconn" = lib.mkDefault 8192;
          "net.core.netdev_max_backlog" = lib.mkDefault 16384;

          # TCP keepalive settings (more aggressive)
          "net.ipv4.tcp_keepalive_time" = lib.mkDefault 600;
          "net.ipv4.tcp_keepalive_intvl" = lib.mkDefault 60;
          "net.ipv4.tcp_keepalive_probes" = lib.mkDefault 10;
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

    # Enhanced I/O scheduler configuration via udev
    services.udev.extraRules = lib.mkIf cfg.enableIOTuning ''
      # I/O Schedulers (optimal for each device type)
      # HDDs: BFQ provides best responsiveness for rotational media
      ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"

      # SSDs/eMMC: BFQ also good for SATA SSDs
      ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="bfq"

      # NVMe: none (no scheduling) is best for fast NVMe drives
      ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"

      # Queue depth tuning
      # HDD: NCQ depth optimization
      ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{device/queue_depth}="31"

      # NVMe: Higher queue depth for better parallelism (max is 1023)
      ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/nr_requests}="1023"

      # Read-ahead tuning (helps with sequential reads)
      # HDD: Larger read-ahead for sequential workloads (2MB)
      ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{bdi/read_ahead_kb}="2048"

      # SSD: Moderate read-ahead (512KB)
      ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="0", ATTR{bdi/read_ahead_kb}="512"

      # NVMe: Moderate read-ahead (512KB)
      ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{bdi/read_ahead_kb}="512"

      # BFQ I/O scheduler tuning for better responsiveness
      # Increase slice_idle for HDDs to reduce seeking
      ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/iosched/slice_idle}="8"

      # Disable slice_idle for SSDs (no seeking delay)
      ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="0", ATTR{queue/iosched/slice_idle}="0"
    '';
  };
}
