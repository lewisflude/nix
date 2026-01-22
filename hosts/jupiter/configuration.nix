{
  pkgs,
  lib,
  config,
  constants,
  ...
}:
{

  imports = [
    ./hardware-configuration.nix
    ./sunshine.nix
  ];

  # Jupiter-specific boot configuration
  # Overrides core boot.nix defaults for high-performance gaming
  boot = {
    # XanMod kernel (6.12) for gaming performance with ZFS compatibility
    # ZFS 2.3.5 supports up to kernel 6.17, so 6.12 is safe
    # Using linuxPackages_xanmod (6.12) instead of xanmod_latest (6.18)
    kernelPackages = pkgs.linuxPackages_xanmod;

    # Blacklist unnecessary kernel modules to reduce overhead
    blacklistedKernelModules = [
      # Unused filesystems
      "cramfs"
      "freevxfs"
      "jffs2"
      "hfs"
      "hfsplus"
      "udf"

      # Unused network protocols
      "dccp"
      "sctp"
      "rds"
      "tipc"

      # Bluetooth (if not using)
      # "bluetooth"
      # "btusb"

      # Webcam (if not using)
      # "uvcvideo"
    ];

    kernelParams = [
      # NVIDIA & Display Tuning
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"

      # ZFS ARC Tuning for 64GB RAM system
      # 16GB limit prevents ZFS from competing with games for memory
      "zfs.zfs_arc_max=17179869184" # 16GB

      # WiFi Regulatory Domain: UK (enables proper frequency ranges and power limits)
      # Fixes restrictive "00" global default that limits WiFi performance
      # See: https://wiki.archlinux.org/title/Network_configuration/Wireless#Respecting_the_regulatory_domain
      "cfg80211.ieee80211_regdom=GB"

      # Maximum Performance Tuning
      "nohz=off" # Disable tickless kernel for consistent latency
      "rcu_nocbs=all" # Offload RCU callbacks from all CPUs
      "rcu_nocb_poll" # Poll for RCU callbacks instead of interrupting
      "skew_tick=1" # Spread timer ticks across CPUs to reduce contention
    ];
  };

  users = {
    mutableUsers = false;
    users.${config.host.username} = {
      home = "/home/${config.host.username}";
      isNormalUser = true;
      hashedPassword = null;
      openssh.authorizedKeys.keys = [
        # Mercury MacBook (ED25519)
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEyBDIzK/OoFY7M1i96wP9wE+OeKk56iTvPwStEiFc+k lewis@lewisflude.com"
        # YubiKey hardware security key
        "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBGB2FdscjELsv6fQ4dwLN7ky3Blye+pxJHBfACdYmxhgPodPaRLqbekyrt+XDdXvQYmuiZ0XIa/fL4/452g5MWcAAAAEc3NoOg== lewis@lewisflude.com"
        # iPhone Termux (ED25519)
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOuc2y4LO/GMf02/as8OqUB+zKl+sU44umYXNVC7KzF9 termix@phone"
        # iPhone Prompt 3 with Secure Enclave (hardware-backed, very secure)
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBL9zRrDvYpeH9zmtzNEMbMaML1mZOilWZbWfHtwDP0cn36PO0lyuRqsKYlrgmCrTdGkh34gk2hQvI4HMeGf2Bxs="
      ];
      extraGroups = [
        "dialout"
        "admin"
        "wheel"
        "staff"
        "_developer"
        "git"
        "media" # Access to /mnt/storage and media services
        "audio" # Enhanced realtime audio performance (memlock, rtprio)
        "uinput" # Required for Sunshine to capture input (mouse/keyboard)
        "video" # Required for GPU access
      ];
      shell = pkgs.zsh;
    };
  };
  time.timeZone = constants.defaults.timezone;
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  boot.loader.systemd-boot.configurationLimit = 5;

  # /tmp on tmpfs (RAM) for faster Nix builds and system responsiveness
  # This prevents ZFS CoW overhead from impacting build performance
  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "50%"; # 32GB for builds (plenty with 64GB total RAM)
  };

  # System performance optimizations
  # Comprehensive tuning: VM, I/O, network, OOM handling
  # Note: ZFS ARC max is set to 16GB in kernelParams above (gaming priority)
  nixosConfig.diskPerformance = {
    enable = true;
    enableVMTuning = true;
    enableIOTuning = true;
    enableNetworkTuning = true; # TCP BBR, optimized buffers
    enableOOMHandling = true; # systemd-oomd for better responsiveness
    enableZram = true; # Compressed swap in RAM for better responsiveness
    disableCoreDumps = true; # Save disk space, improve performance
    enableZFSTuning = false; # ARC handled by kernelParams, datasets by hardware-configuration
  };

  # CPU performance optimizations
  nixosConfig.cpuPerformance = {
    enable = true;
    # irqbalance: Distributes hardware interrupts across all CPU cores
    # Prevents single-core bottlenecks (especially CPU0) for high-speed NVMe/network
    # WARNING: Some users report gaming stuttering with irqbalance enabled
    # Enable if you experience interrupt bottlenecks, disable if you see game stuttering
    enableIrqbalance = true; # Enabled: Prevents interrupt pile-up on CPU0 for high-speed I/O
    enableFrequencyScaling = true;
    scalingGovernor = "schedutil"; # Better for hybrid P/E cores than "performance"
    disableMitigations = true; # PERFORMANCE MODE: 5-10% gain, safe for non-VM workloads
  };

  # Disable thermald - let BIOS handle thermal management for i9-13900K
  # Modern BIOS/UEFI handles P/E core thermal throttling better than userspace daemon
  services.thermald.enable = false;

  # I/O priority management: keep background tasks from impacting gaming
  nixosConfig.ioPriority = {
    enable = true;
    # These services run at idle I/O priority (only when no other I/O)
    # TRIM, scrubs, and other maintenance automatically get idle priority
    backgroundServices = [ ]; # Add service names here if needed, e.g. "docker"
  };

  # Gaming latency optimizations (Arch Wiki recommendations)
  nixosConfig.gamingLatency = {
    enable = true;
    enableMemoryTuning = true; # Reduce memory allocation stalls and jitter
    enableSchedulerTuning = true; # Lower latency CPU scheduling
    enableTransparentHugepages = false; # Disable for consistent latency (enable if using TCMalloc games)
    minFreeKilobytes = 2097152; # 2GB reserved memory (3% of 64GB) - eliminates allocation stalls
    watermarkScaleFactor = 1000; # 10% watermark distance - maximum protection against stalls
  };

  # PCI Express latency tuning
  nixosConfig.pciLatency = {
    enable = true;
    defaultLatency = 32; # Conservative default for most devices
    hostBridgeLatency = 0; # Host bridge doesn't need bus time
    audioLatency = 80; # Higher priority for audio devices
  };

  # Alternative CPU schedulers (optional - test for your workload)
  # Note: scx-scheds package not yet available in nixpkgs
  # Uncomment to enable scx_cosmos (good for gaming + desktop) or scx_lavd (gaming-focused)
  nixosConfig.scheduler = {
    enableScxScheds = false; # Set to true when package is available
    # defaultScheduler = "scx_lavd"; # Gaming-focused scheduler
  };

  # TSC clocksource for ~50x faster clock_gettime() (games use this heavily)
  # Enabled on Jupiter - modern Intel/AMD CPUs support this
  nixosConfig.boot.enableTscClocksource = true;

  # Additional high-performance sysctls
  # These override disk-performance module defaults for gaming-specific tuning
  boot.kernel.sysctl = {
    # Maximize writeback performance (more aggressive than module defaults)
    # Module sets: dirty_ratio=40, dirty_background_ratio=15, dirty_writeback_centisecs=6000
    # Jupiter overrides for gaming: faster writeback, higher dirty memory tolerance
    "vm.dirty_ratio" = lib.mkForce 80; # Dirty memory can reach 80% before sync writes
    "vm.dirty_background_ratio" = lib.mkForce 50; # Start background writeback at 50%
    "vm.dirty_expire_centisecs" = 6000; # Dirty data expires after 60s
    "vm.dirty_writeback_centisecs" = lib.mkForce 2000; # Write dirty data every 20s (vs module: 60s)

    # Reduce kernel timer frequency for lower latency
    "kernel.timer_migration" = 0; # Keep timers on the CPU that set them

    # Optimize for desktop responsiveness
    "kernel.hung_task_timeout_secs" = 0; # Disable hung task detection (reduces overhead)

    # Network performance
    # Increased buffers from 2.5MB to 32MB to prevent buffer underflow on 1Gbps fiber
    # This fixes the "114Mbps plateau" issue caused by buffer exhaustion
    "net.core.rmem_max" = lib.mkForce 33554432; # 32MB (optimal for 1Gbps connections)
    "net.core.wmem_max" = lib.mkForce 33554432; # 32MB
    "net.ipv4.tcp_rmem" = lib.mkForce "4096 87380 33554432";
    "net.ipv4.tcp_wmem" = lib.mkForce "4096 65536 33554432";
    # net.core.netdev_max_backlog already set in disk-performance module
    # tcp_fastopen already set in modules/nixos/core/networking.nix and disk-performance
    "net.ipv4.tcp_low_latency" = 1; # Optimize for low latency over throughput
    "net.ipv4.tcp_timestamps" = 0; # Disable TCP timestamps for lower overhead
  };

  # Network configuration
  networking = {
    # Optimized MTU for primary interface (discovered via scripts/optimize-mtu.sh)
    # Lower than standard 1500 to avoid fragmentation on path to internet
    interfaces.eno2.mtu = 1492;

    # Firewall configuration
    firewall = {
      allowedTCPPorts = [
        22 # SSH
        constants.ports.mcp.docs # Docs MCP Server HTTP interface
        # Sunshine ports are handled by services.sunshine.openFirewall = true
      ];
      # Sunshine UDP ports are handled by services.sunshine.openFirewall = true
    };
  };

  # Open-WebUI configuration (enabled via host.features.aiTools)
  services.open-webui = {
    port = constants.ports.services.openWebui; # 7000
    openFirewall = true;
  };

  # Host-level configurations
  host = {
    # Caddy reverse proxy
    services.caddy = {
      enable = true;
      email = "lewis@lewisflude.com";
    };

    features = {
      # Desktop configuration - enable auto-login for Sunshine streaming
      # This allows Moonlight clients to connect without needing to login via greeter
      desktop.autoLogin = {
        enable = true;
        user = config.host.username; # Auto-login as the configured user (lewis)
      };

      # Boot optimization: Delay non-essential services to speed up boot
      # AI services don't need to start immediately at boot
      bootOptimization = {
        enable = true;
        delayedServices = [
          "ollama"
          "ollama-models" # This takes 1min+ at boot pulling models
          "open-webui"
        ];
        delaySeconds = 30;
      };
    };
  };

  # XFS filesystem optimizations for /mnt/disk1 and /mnt/disk2
  features.xfs = {
    enable = true;
    enableScrubbing = true;
    scrubSchedule = "weekly";
    tuneWriteback = true;
    writebackInterval = 10000; # 100 seconds (vs default 30s)
  };

  # Home Manager configuration
  home-manager.users.${config.host.username} = {
    programs.hytale-launcher.enable = true;
  };

}
