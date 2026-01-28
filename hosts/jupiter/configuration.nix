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

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
    "cfg80211.ieee80211_regdom=GB"
  ];

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

  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "50%";
  };

  powerManagement.cpuFreqGovernor = "schedutil";

  networking = {
    interfaces.eno2.mtu = 1492;
    firewall.allowedTCPPorts = [
      22
      constants.ports.mcp.docs
    ];
  };

  services.open-webui = {
    port = constants.ports.services.openWebui;
    openFirewall = true;
  };

  host = {
    services.caddy = {
      enable = true;
      email = "lewis@lewisflude.com";
    };

    features = {
      desktop.autoLogin = {
        enable = true;
        user = config.host.username;
      };
    };
  };

  # Home Manager configuration
  home-manager.users.${config.host.username} = {
    programs.hytale-launcher.enable = true;
  };

}
