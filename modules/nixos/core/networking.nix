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
    networkmanager.enable = true;
    networkmanager.dns = "systemd-resolved";
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
  services = {
    resolved.enable = true;
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

    # WireGuard performance optimizations
    # Increase maximum buffer sizes for high-throughput VPN traffic
    "net.core.rmem_max" = 16777216; # 16MB
    "net.core.wmem_max" = 16777216; # 16MB

    # TCP buffer sizes (min, default, max) - IPv4
    "net.ipv4.tcp_rmem" = "4096 87380 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";

    # TCP buffer sizes (min, default, max) - IPv6 (same as IPv4 for consistency)
    "net.ipv6.tcp_rmem" = "4096 87380 16777216";
    "net.ipv6.tcp_wmem" = "4096 65536 16777216";

    # Enable BBR congestion control for better throughput (IPv4 and IPv6)
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv6.tcp_congestion_control" = "bbr";
  };
}
