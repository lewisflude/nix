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
    useNetworkd = true;
    useDHCP = false;
    networkmanager.enable = false;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ]; # SSH
      allowedUDPPorts = [ 123 ]; # NTP
    };
  };

  # Suppress harmless USB audio quirk messages for Apogee Symphony Desktop
  boot.kernelParams = [ "usbcore.quirks=0c60:002a:b" ];

  systemd.network = {
    enable = true;
    wait-online = {
      timeout = 10;
      anyInterface = true;
    };
    networks."10-main" = {
      matchConfig.Name = "eno2";
      DHCP = "yes";
      networkConfig.IPv6AcceptRA = true;
    };
  };

  services = {
    resolved = {
      enable = true;
      settings.Resolve.FallbackDNS = [ ];
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
      packages = [ pkgs.avahi ];
    };
  };

  boot.kernel.sysctl = {
    # IP forwarding for containers/VPN
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = lib.mkDefault 1;

    # BBR congestion control - proven throughput improvement
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";

    # Optimized buffer sizes for symmetrical fiber connections
    # Note: Lower values can reduce latency for some workloads
    # If experiencing issues, disk-performance module may override with higher values
    "net.core.rmem_max" = 2500000; # 2.5MB (as requested for testing)
    "net.core.wmem_max" = 2500000; # 2.5MB (as requested for testing)
    "net.ipv4.tcp_rmem" = "4096 87380 2500000";
    "net.ipv4.tcp_wmem" = "4096 65536 2500000";

    # TCP Fast Open - reduces latency for new connections
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_mtu_probing" = 1;
  };
}
