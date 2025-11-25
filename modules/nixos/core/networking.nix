{
  hostname,
  pkgs,
  lib,
  ...
}:
{
  networking = {
    hostName = hostname;
    enableIPv6 = true;
    # Use systemd-networkd for advanced routing
    useNetworkd = true;
    useDHCP = false; # DHCP configured per-interface in systemd.network
    networkmanager.enable = false;
    firewall = {
      enable = true;

      # Core system ports that are essential for basic system functionality
      # These are not service-specific and should remain in core networking
      allowedTCPPorts = [
        22 # SSH - essential for system access
      ];
      allowedUDPPorts = [
        123 # NTP - essential for time synchronization
      ];

      # Service-specific firewall rules are declared by individual service modules
      # using the firewall library helpers from lib/firewall.nix
      # This ensures proper separation of concerns and maintainable configuration
    };
  };

  # systemd-networkd - declarative, advanced routing capabilities
  systemd.network = {
    enable = true;

    # Main interface configuration (VLAN 1 - Default network)
    networks."10-main" = {
      matchConfig.Name = "eno2";
      DHCP = "yes";
      # Configure this interface to create VLAN interfaces
      networkConfig = {
        # Create vlan2 interface on this physical interface
        VLAN = [ "vlan2" ];
      };
    };

    # VLAN 2 - Secondary network (routed through UDM)
    netdevs."10-vlan2" = {
      netdevConfig = {
        Name = "vlan2";
        Kind = "vlan";
      };
      vlanConfig = {
        Id = 2;
        # VLAN will be created on the interface that has this netdev referenced
        # Typically referenced from the main network's VLAN setting
      };
    };

    # VLAN 2 interface configuration
    networks."20-vlan2" = {
      matchConfig.Name = "vlan2";
      DHCP = "no";
      # Static IP for VLAN 2 - allows services to bind to specific interface
      # Services that bind to this interface (like qBittorrent) will route through it
      address = [
        "192.168.2.249/24"
      ];
      # Policy routing: traffic from this interface goes through VPN gateway
      routingPolicyRules = [
        {
          From = "192.168.2.249/32";
          Table = 2;
          Priority = 100;
        }
      ];
      # Custom routing table for VPN traffic
      routes = [
        {
          Gateway = "192.168.2.1";
          Destination = "0.0.0.0/0";
          Table = 2;
        }
      ];
    };
  };

  services = {
    resolved = {
      enable = true;
      # Disable fallback DNS - use only DHCP-provided DNS servers
      fallbackDns = [ ];
      # Prefer DNS servers from DHCP over fallback servers
      extraConfig = ''
        DNSStubListener=yes
      '';
    };
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
      publish = {
        enable = true;
        addresses = true;
        domain = true;
        hinfo = true;
        userServices = true;
        workstation = true;
      };
    };
    dbus = {
      implementation = "broker";
      # Note: NixOS automatically adds packages for enabled services
      # (networkmanager, polkit, gnome-keyring are auto-added when their services are enabled)
      # Only add packages here that provide dbus services but aren't managed by NixOS service modules
      packages = [ pkgs.avahi ];
    };
  };
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = lib.mkDefault 1;

    # Network performance optimizations for high-bandwidth torrenting
    # Increased to 32MB to prevent buffer bloat on 1Gbps+ links with 64GB RAM
    "net.core.rmem_max" = 33554432; # 32MB
    "net.core.wmem_max" = 33554432; # 32MB

    # TCP buffer sizes (min, default, max) - IPv4
    "net.ipv4.tcp_rmem" = "4096 87380 33554432";
    "net.ipv4.tcp_wmem" = "4096 65536 33554432";

    # TCP buffer sizes (min, default, max) - IPv6 (same as IPv4 for consistency)
    "net.ipv6.tcp_rmem" = "4096 87380 33554432";
    "net.ipv6.tcp_wmem" = "4096 65536 33554432";

    # Enable BBR congestion control for better throughput (IPv4 and IPv6)
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv6.tcp_congestion_control" = "bbr";
  };
}
