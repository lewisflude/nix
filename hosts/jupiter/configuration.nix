{
  lib,
  pkgs,
  config,
  constants,
  ...
}:
{

  imports = [
    ./hardware-configuration.nix
  ];
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
  system.diskPerformance = {
    enable = true;
    enableVMTuning = true; # VM subsystem tuning for 64GB RAM
    enableIOTuning = true; # I/O scheduler and readahead optimization
    enableZFSTuning = true; # ZFS ARC, compression, and atime optimization
    ramSizeGB = 64; # i9-13900K system with 64GB RAM
    zfsARCMaxGB = 48; # Cap ZFS ARC at 48GB (75% of RAM)
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

  # Caddy reverse proxy
  host.services.caddy = {
    enable = true;
    email = "lewis@lewisflude.com";
  };

  # Open-WebUI configuration (enabled via host.features.aiTools)
  services.open-webui = {
    port = constants.ports.services.openWebui; # 7000
    openFirewall = true;
  };

  # Boot optimization: Delay non-essential services to speed up boot
  systemd = {
    services = {
      # AI services don't need to start immediately at boot
      ollama.wantedBy = lib.mkForce [ ];
      open-webui.wantedBy = lib.mkForce [ ];

      # Start delayed services 30 seconds after boot
      delayed-services = {
        description = "Start non-essential services after boot";
        script = ''
          ${lib.optionalString config.services.ollama.enable "${pkgs.systemd}/bin/systemctl start ollama.service"}
          ${lib.optionalString config.services.open-webui.enable "${pkgs.systemd}/bin/systemctl start open-webui.service"}
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };
    };

    timers.delayed-services = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "30s";
        Unit = "delayed-services.service";
      };
    };
  };

}
