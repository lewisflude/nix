# Alternative CPU Scheduler Support
# Based on Arch Wiki Gaming recommendations
# https://wiki.archlinux.org/title/Gaming#Improving_performance
#
# Provides access to sched_ext schedulers (scx-scheds) for improved gaming performance:
# - scx_cosmos: Optimizes task-to-CPU locality, reduces lock contention, prioritizes interactive tasks
# - scx_lavd: Specifically optimized for consistent gaming performance
# - Others: scx_rustland, scx_bpfland, etc.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixosConfig.scheduler;
in
{
  options.nixosConfig.scheduler = {
    enableScxScheds = lib.mkEnableOption "sched_ext schedulers (scx-scheds)";

    defaultScheduler = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "scx_cosmos";
      description = ''
        Default sched_ext scheduler to use.
        Available schedulers: scx_cosmos, scx_lavd, scx_rustland, scx_bpfland, and more.

        Recommended for gaming:
        - scx_cosmos: Best all-around for gaming + desktop use (optimizes locality, interactive tasks)
        - scx_lavd: Specifically optimized for consistent gaming performance

        Set to null to install the package but not auto-start any scheduler.
        You can manually start schedulers with: sudo scx_sched <scheduler>
      '';
    };
  };

  config = lib.mkIf cfg.enableScxScheds {
    # Install scx-scheds package
    environment.systemPackages = [ pkgs.scx-scheds ];

    # Systemd service to start the default scheduler (if specified)
    systemd.services.scx-scheduler = lib.mkIf (cfg.defaultScheduler != null) {
      description = "sched_ext ${cfg.defaultScheduler} CPU Scheduler";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udev-settle.service" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.scx-scheds}/bin/scx_sched ${cfg.defaultScheduler}";
        Restart = "on-failure";
        RestartSec = "5s";

        # Security settings
        ProtectSystem = "strict";
        ProtectHome = true;
        NoNewPrivileges = false; # Needs privileges for scheduler operations
        PrivateTmp = true;

        # Allow scheduler to adjust priorities and load BPF programs
        AmbientCapabilities = "CAP_SYS_NICE CAP_SYS_ADMIN CAP_BPF";
        CapabilityBoundingSet = "CAP_SYS_NICE CAP_SYS_ADMIN CAP_BPF";
      };
    };

    # Add kernel module for sched_ext (if not already loaded)
    boot.kernelModules = [ "sched_ext" ];

    assertions = [
      {
        assertion = cfg.defaultScheduler != null -> cfg.enableScxScheds;
        message = "defaultScheduler requires enableScxScheds to be true";
      }
    ];
  };
}
