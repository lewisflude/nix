{
  pkgs,
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

    kernelParams = [
      # NVIDIA & Display Tuning
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"

      # ZFS ARC Tuning for 64GB RAM system
      # 16GB limit prevents ZFS from competing with games for memory
      "zfs.zfs_arc_max=17179869184" # 16GB

      # Intel Gaming Tuning: Low-latency C-states
      # Prevents CPU latency spikes during gaming
      "processor.max_cstate=1"
      "intel_idle.max_cstate=1"
    ];
  };

  users = {
    mutableUsers = false;
    users.${config.host.username} = {
      home = "/home/${config.host.username}";
      isNormalUser = true;
      hashedPassword = null;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPeK0wgNYUtZScvg64MoZObPaqjaDd7Gdj4GBsDcqAt7 lewis@lewisflude.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEyBDIzK/OoFY7M1i96wP9wE+OeKk56iTvPwStEiFc+k lewis@lewisflude.com" # mercury
        "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBGB2FdscjELsv6fQ4dwLN7ky3Blye+pxJHBfACdYmxhgPodPaRLqbekyrt+XDdXvQYmuiZ0XIa/fL4/452g5MWcAAAAEc3NoOg== lewis@lewisflude.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOuc2y4LO/GMf02/as8OqUB+zKl+sU44umYXNVC7KzF9 termix@phone"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAiJX39eDkzIc3zWlr/u0nXmzZObmS6wQ7GPgYFt5I80 iphone@lewis"
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBL9zRrDvYpeH9zmtzNEMbMaML1mZOilWZbWfHtwDP0cn36PO0lyuRqsKYlrgmCrTdGkh34gk2hQvI4HMeGf2Bxs="
      ];
      extraGroups = [
        "dialout"
        "admin"
        "wheel"
        "staff"
        "_developer"
        "git"
        "media" # Access to /mnt/storage and media services
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

  # Disk performance optimizations
  # Note: ZFS ARC max is set to 16GB in kernelParams above (gaming priority)
  system.diskPerformance = {
    enable = true;
    enableVMTuning = true;
    enableIOTuning = true;
    enableZFSTuning = false; # ARC handled by kernelParams, datasets by hardware-configuration
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
      ];
    };
  };

  # Dante SOCKS proxy - disabled (VLAN2 removed)
  # services.dante-proxy = {
  #   enable = false;
  # };

  # Avahi mDNS for Moonlight auto-discovery
  # Enables Moonlight clients to automatically find the PC on the network
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      userServices = true;
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
          "open-webui"
        ];
        delaySeconds = 30;
      };
    };
  };

}
