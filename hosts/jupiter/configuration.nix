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

  # VPN Confinement namespace for qBittorrent
  vpnNamespaces.qbittor = {
    enable = true;
    wireguardConfigFile = config.sops.templates.wireguard-config-file.path;
    accessibleFrom = [
      "192.168.1.0/24" # Local network
      "127.0.0.1" # Localhost
    ];
    portMappings = [
      {
        from = 8080;
        to = 8080;
        protocol = "tcp";
      }
      {
        from = 6881;
        to = 6881;
        protocol = "both";
      }
    ];
    openVPNPorts = [
      {
        port = 6881;
        protocol = "both";
      }
    ];
  };

  # SOPS configuration for WireGuard VPN
  sops = {
    templates.wireguard-config-file = {
      content = ''
        [Interface]
        # Bouncing = 4
        # NetShield = 0
        # Moderate NAT = off
        # NAT-PMP (Port Forwarding) = on
        # VPN Accelerator = off
        PrivateKey = ${config.sops.placeholder."protonvpn/private_key"}
        Address = 10.2.0.2/32
        DNS = 10.2.0.1

        [Peer]
        # NL#89
        PublicKey = +HCLUCm6PdbDIaKtEM3pOWBEKSB/UdpBwRY5cNl6ZnI=
        AllowedIPs = 0.0.0.0/0, ::/0
        Endpoint = 138.199.7.129:51820
      '';
      owner = config.host.services.mediaManagement.user;
    };
    secrets = {
      "protonvpn/private_key".owner = lib.mkForce config.host.services.mediaManagement.user;
    };
  };

}
