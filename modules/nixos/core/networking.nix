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
    useDHCP = false;
    # DHCP configured per-interface in systemd.network
    networkmanager.enable = false;
    firewall = {
      enable = true;
      # Core system ports that are essential for basic system functionality
      allowedTCPPorts = [
        22 # SSH
      ];
      allowedUDPPorts = [
        123 # NTP
      ];
    };
  };

  # --- CPU Latency Tuning for Network Speed ---
  # Prevents the CPU from entering deep sleep states (C3/C6), which causes
  # micro-stutters on 1Gbps+ links.
  boot.kernelParams = [
    "processor.max_cstate=1"
    "intel_idle.max_cstate=1"
    # Suppress harmless USB audio quirk messages for Apogee Symphony Desktop
    # The device tries to query 192kHz support but we use 48kHz - this is normal
    "usbcore.quirks=0c60:002a:b"
  ];

  # Network Interface Hardware Tuning
  # These settings must be applied via ethtool since systemd-networkd doesn't support
  # hardware-specific ring buffer and offload settings in its Link section
  systemd.services.network-tuning = {
    description = "Network performance tuning for eno2 (offloading + ring buffers)";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = [
        # 1. Fix "Dropped Packets": Increase ring buffers to hardware max (4096)
        "${pkgs.ethtool}/bin/ethtool -G eno2 rx 4096 tx 4096"
        # 2. Fix "VPN/Router Performance": Disable LRO, keep GRO enabled
        #    LRO breaks routing/VPN packet headers; GRO is software-friendly
        "${pkgs.ethtool}/bin/ethtool -K eno2 lro off gro on"
        # 3. Fix "Micro-Stutters": Disable pause frames (flow control)
        "${pkgs.ethtool}/bin/ethtool -A eno2 rx off tx off"
      ];
    };
  };

  # systemd-networkd - declarative, advanced routing capabilities
  systemd.network = {
    enable = true;

    # Optimize boot time: don't wait forever for all interfaces
    wait-online = {
      timeout = 10; # Reduced from default 120 seconds
      anyInterface = true; # Continue boot once any interface is up
    };

    # Main interface configuration
    networks."10-main" = {
      matchConfig.Name = "eno2";
      DHCP = "yes";
      networkConfig = {
        # Fix for "igc" driver random disconnects (Energy Efficient Ethernet)
        IPv6AcceptRA = true;
      };
    };

    # --- TODO: Add your VPN Interface here once you calculate MTU ---
    # networks."30-vpn" = {
    #   matchConfig.Name = "tun0"; # Change to your VPN interface name
    #   linkConfig.MTUBytes = 1400; # Change to your calculated MTU
    # };
  };

  services = {
    resolved = {
      enable = true;
      fallbackDns = [ ];
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
      packages = [ pkgs.avahi ];
    };
  };

  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = lib.mkDefault 1;

    # --- BBR & Buffer Tuning ---

    # REQUIRED for BBR: Use Fair Queueing (fq) instead of fq_codel
    "net.core.default_qdisc" = "fq";

    # Enable BBR Congestion Control
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv6.tcp_congestion_control" = "bbr";

    # Network performance optimizations for high-bandwidth torrenting
    "net.core.rmem_max" = 33554432; # 32MB
    "net.core.wmem_max" = 33554432; # 32MB

    # TCP buffer sizes (min, default, max) - IPv4
    "net.ipv4.tcp_rmem" = "4096 87380 33554432";
    "net.ipv4.tcp_wmem" = "4096 65536 33554432";

    # TCP buffer sizes - IPv6
    "net.ipv6.tcp_rmem" = "4096 87380 33554432";
    "net.ipv6.tcp_wmem" = "4096 65536 33554432";

    # Additional LAN optimizations
    "net.core.netdev_max_backlog" = 5000;
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.tcp_window_scaling" = 1;
    "net.ipv4.tcp_timestamps" = 1;
    "net.ipv4.tcp_fin_timeout" = 15;
  };
}
