# CPU Performance Optimizations
# Includes: interrupt balancing, CPU frequency scaling, and optional exploit mitigation disabling
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixosConfig.cpuPerformance;
in
{
  options.nixosConfig.cpuPerformance = {
    enable = lib.mkEnableOption "CPU performance optimizations";

    enableIrqbalance = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable irqbalance to distribute hardware interrupts across CPU cores.
        WARNING: Can cause stuttering in games and video playback.
        Only enable if you have specific needs for interrupt distribution.
      '';
    };

    enableFrequencyScaling = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable CPU frequency scaling for power efficiency";
    };

    scalingGovernor = lib.mkOption {
      type = lib.types.str;
      default = "performance";
      description = ''
        CPU frequency scaling governor.
        Options: performance, powersave, ondemand, conservative, schedutil
        For gaming/desktop: "performance" or "schedutil"
        For laptops: "powersave" or "schedutil"
      '';
    };

    disableMitigations = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Disable CPU exploit mitigations (Spectre, Meltdown, etc.).

        WARNING: SECURITY RISK - Only enable if you understand the implications:
        - Do NOT rely on VMs to isolate untrusted programs if enabled
        - Increases vulnerability to side-channel attacks
        - Performance gain on modern CPUs (Intel 10th gen+, Ryzen 1000+) is minimal (0-5%)
        - Older CPUs may see up to 25% improvement in some workloads

        Recommended: Keep false unless you have a specific need and accept the risks.
      '';
    };

    enableCpusetManagement = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable CPU set management for process isolation.
        Useful for dedicated gaming cores or real-time applications.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # irqbalance: Distribute interrupts across CPUs
    # WARNING: Known to cause issues with gaming and media playback
    services.irqbalance.enable = cfg.enableIrqbalance;

    # CPU frequency scaling
    powerManagement = lib.mkIf cfg.enableFrequencyScaling {
      enable = true;
      cpuFreqGovernor = lib.mkDefault cfg.scalingGovernor;
    };

    # Intel Thermal Daemon (thermald) - critical for Intel P-core/E-core management
    # Prevents thermal throttling and manages Intel's hybrid architecture
    services.thermald.enable = lib.mkDefault true;

    # Disable CPU exploit mitigations (if explicitly enabled)
    boot.kernelParams = lib.mkIf cfg.disableMitigations [
      "mitigations=off"
    ];

    # CPU performance monitoring and tuning tools
    # Note: htop is configured via programs.htop in home-manager
    environment.systemPackages = [
      pkgs.i7z # Intel CPU frequency monitoring
      pkgs.linuxPackages.cpupower # CPU frequency utilities
      pkgs.iotop # I/O monitoring
    ];

    # CPU scheduling optimizations
    boot.kernel.sysctl = {
      # Reduce scheduling latency for better desktop responsiveness
      "kernel.sched_latency_ns" = 10000000; # 10ms (default: 6ms)
      "kernel.sched_min_granularity_ns" = 2000000; # 2ms (default: 0.75ms)
      "kernel.sched_wakeup_granularity_ns" = 3000000; # 3ms (default: 1ms)

      # Scheduler tuning for gaming
      "kernel.sched_migration_cost_ns" = 5000000; # 5ms - reduce migration
      "kernel.sched_nr_migrate" = 32; # Migrate up to 32 tasks at once
    };
  };
}
