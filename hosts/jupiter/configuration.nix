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

  # WireGuard tools (required for VPN-Confinement)
  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];

  # Firewall configuration
  networking.firewall = {
    allowedTCPPorts = [ 6280 ]; # Docs MCP Server HTTP interface
  };

  # Dante SOCKS proxy for routing traffic through vlan2 (VPN)
  services.dante-proxy = {
    enable = true;
    port = 1080;
    interface = "vlan2";
    listenAddress = "127.0.0.1"; # Localhost only for security
    allowedClients = [
      "127.0.0.1/32" # Localhost
      "192.168.0.0/16" # Local network
    ];
    openFirewall = false; # Localhost only, no need to open firewall
  };

  # Caddy reverse proxy
  host.services.caddy = {
    enable = true;
    email = "lewis@lewisflude.com";
  };

}
