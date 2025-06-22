{ pkgs, hostname, ... }: {
  environment.systemPackages = with pkgs; [
    networkmanagerapplet
  ];

  networking = {
    hostName = hostname;
    enableIPv6 = true;
    networkmanager.enable = true;
    networkmanager.dns = "systemd-resolved";

    firewall = {
      enable = true;
      allowedTCPPorts = [
        22    # SSH
        80    # HTTP
        443   # HTTPS
        8080  # Common web services
        8123  # Home Assistant
      ];

      allowedUDPPorts = [
        5353  # mDNS
        123   # NTP
      ];
    };
  };

  services.resolved.enable = true;

  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  services.avahi = {
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

  services.dbus.packages = [ pkgs.avahi ];
}