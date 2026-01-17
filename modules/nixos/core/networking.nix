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

    # Large buffer sizes for high-bandwidth transfers (torrenting)
    "net.core.rmem_max" = 33554432; # 32MB
    "net.core.wmem_max" = 33554432; # 32MB
    "net.ipv4.tcp_rmem" = "4096 87380 33554432";
    "net.ipv4.tcp_wmem" = "4096 65536 33554432";

    # TCP Fast Open - reduces latency for new connections
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_mtu_probing" = 1;
  };
}
