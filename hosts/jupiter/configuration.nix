{
  lib,
  pkgs,
  config,
  ...
}:
{
  # Host configuration using the new options system

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
  time.timeZone = lib.mkForce "Europe/London";
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # Limit system generations to save space
  boot.loader.systemd-boot.configurationLimit = 5;

  # WireGuard ProtonVPN configuration for qBittorrent
  # Note: VPN-Confinement manages the WireGuard interface using a config file stored in sops
  # The WireGuard config file should be stored in secrets.yaml as "vpn-confinement/qbittorrent"
  # Format: Standard WireGuard config file with [Interface] and [Peer] sections
  # VPN-Confinement handles interface creation, DNS configuration, and leak prevention automatically
}
