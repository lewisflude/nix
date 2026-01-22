# Gaming Response Time Consistency Tuning
# Based on Arch Wiki Gaming optimizations
# https://wiki.archlinux.org/title/Gaming#Tweaking_kernel_parameters_for_response_time_consistency
#
# These settings prioritize consistent frame times and low latency over raw throughput.
# Reduces jitter, stuttering, and input lag in games.
{
  config,
  lib,
  ...
}:
let
  cfg = config.nixosConfig.gamingLatency;
in
{
  options.nixosConfig.gamingLatency = {
    enable = lib.mkEnableOption "gaming response time consistency optimizations";

    enableMemoryTuning = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable memory allocation and compaction tuning to reduce stalls";
    };

    enableSchedulerTuning = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable CPU scheduler tuning for lower latency";
    };

    enableTransparentHugepages = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Keep Transparent Hugepages enabled (madvise mode).
        Some games with TCMalloc (Dota 2, CS:GO) need this for performance.
        Disable if you experience latency spikes.
      '';
    };

    minFreeKilobytes = lib.mkOption {
      type = lib.types.int;
      default = 1048576; # 1GB
      description = ''
        Minimum free memory to maintain (in KB).
        Helps avoid memory allocation stalls.
        Should be 1-5% of total RAM. Default: 1GB.
      '';
    };

    watermarkScaleFactor = lib.mkOption {
      type = lib.types.int;
      default = 500; # 5% of RAM
      description = ''
        Watermark scale factor (in basis points, 500 = 5%).
        Increases watermark distances to reduce allocation stalls.
        Range: 10-1000. Default: 500 (5%).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernel.sysctl = lib.mkMerge [
      # Memory allocation and compaction tuning
      (lib.mkIf cfg.enableMemoryTuning {
        # Disable proactive compaction - it introduces jitter
        # Only compact on-demand when fragmentation is detected
        "vm.compaction_proactiveness" = 0;

        # Reduce watermark boost to defragment only one pageblock (2MB on x86-64)
        # Helps keep application data in last-level cache after fragmentation events
        "vm.watermark_boost_factor" = 1;

        # Reserve memory to avoid allocation stalls
        # Set to 1-5% of RAM (1GB default for systems with 32GB+)
        "vm.min_free_kbytes" = lib.mkForce cfg.minFreeKilobytes;

        # Increase watermark scale factor to further reduce allocation stalls
        # Default 10 (0.1%), we use 500 (5%) for gaming workloads
        "vm.watermark_scale_factor" = lib.mkForce cfg.watermarkScaleFactor;

        # Avoid swapping unless absolutely necessary
        # Overrides any previous swappiness settings with high priority
        "vm.swappiness" = lib.mkForce 10;

        # Enable Multi-Gen LRU but reduce lock contention
        # 5 = enabled with reduced locking (vs 1 = basic enable)
        "vm.lru_gen.enabled" = 5;

        # Disable zone reclaim - prevents latency spikes from memory page movement
        "vm.zone_reclaim_mode" = 0;

        # Transparent Hugepages configuration
        # madvise = only when application requests (safe default)
        # never = disabled (use if experiencing latency spikes)
        "vm.transparent_hugepage.enabled" = if cfg.enableTransparentHugepages then "madvise" else "never";
        "vm.transparent_hugepage.shmem_enabled" =
          if cfg.enableTransparentHugepages then "advise" else "never";
        "vm.transparent_hugepage.defrag" = "never"; # Never defragment synchronously

        # Reduce page lock acquisition latency while maintaining throughput
        "vm.page_lock_unfairness" = 1;
      })

      # CPU scheduler tuning for lower latency
      (lib.mkIf cfg.enableSchedulerTuning {
        # Don't prioritize child processes - parent (game) should run first
        "kernel.sched_child_runs_first" = 0;

        # Enable autogroup for better desktop responsiveness
        # Automatically groups related processes for fair scheduling
        "kernel.sched_autogroup_enabled" = 1;

        # CFS bandwidth slice: reduce from default 5000us to 3000us
        # Shorter slices = more frequent preemption = lower latency
        "kernel.sched_cfs_bandwidth_slice_us" = 3000;
      })
    ];

    # Additional scheduler tuning via debugfs
    # These require debugfs to be mounted, which systemd-tmpfiles handles
    systemd.tmpfiles.rules = lib.mkIf cfg.enableSchedulerTuning [
      # Base slice: minimum time a task runs before being preempted (2ms for lower latency)
      "w /sys/kernel/debug/sched/base_slice_ns - - - - 2000000"

      # Migration cost: how expensive it is to move a task to another CPU (5ms)
      # Higher = less migration = better cache locality for gaming
      "w /sys/kernel/debug/sched/migration_cost_ns - - - - 5000000"

      # Number of tasks to migrate at once (16 = balanced for gaming)
      "w /sys/kernel/debug/sched/nr_migrate - - - - 16"
    ];
  };
}
