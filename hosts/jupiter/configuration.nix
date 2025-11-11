{
  lib,
  pkgs,
  config,
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

  boot.loader.systemd-boot.configurationLimit = 5;

  # WireGuard VPN for qBittorrent with user-specific routing
  services.wireguard-qbittorrent = {
    enable = true;
    user = "media"; # qBittorrent runs as this user
    privateKeyFile = config.sops.secrets."protonvpn/private_key".path;
    peers = [
      {
        publicKey = "ronr+8v670J0CPb0xT5QLGMWDfE7+1g7HmC6YMdCIDk=";
        allowedIPs = [
          "0.0.0.0/0"
          "::/0"
        ];
        endpoint = "138.199.7.129:51820";
      }
    ];
    localNetworks = [
      "192.168.1.0/24" # Local network
      "127.0.0.1/32" # Localhost
      "::1/128" # IPv6 localhost
    ];
  };

  # ProtonVPN NAT-PMP Port Forwarding
  # This service automatically maintains port forwarding mappings using NAT-PMP
  # It runs in a loop, renewing the port mappings every 45 seconds (before the 60s lease expires)
  services.protonvpnPortForwarding = {
    enable = true;
    vpnInterface = "qbittor0";
    vpnGateway = "10.2.0.1"; # ProtonVPN DNS/gateway IP
    internalPort = 6881; # Port that qBittorrent listens on
    leaseTime = 60; # NAT-PMP lease time (ProtonVPN uses 60 seconds)
    renewInterval = 45; # Renew every 45 seconds (before lease expires)

    # Optional: Automatically update qBittorrent when a new port is assigned
    # Set updateQBittorrent = true and configure qbittorrent options to enable
    updateQBittorrent = false;
    # qbittorrent = {
    #   webuiUrl = "http://192.168.15.1:8080";
    #   username = "lewis";
    #   # password can be provided here or will be read from SOPS secrets.yaml
    #   password = null; # Will try to read from SOPS if not provided
    # };
  };

  # Firewall configuration for systemd.network WireGuard
  networking.firewall = {
    allowedUDPPorts = [ 51820 ];
    allowedTCPPorts = [ 6280 ]; # Docs MCP Server HTTP interface
    checkReversePath = "loose";
  };

}
