{
  pkgs,
  hostname,
  ...
}: {
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
        # System services
        22
        80
        443

        # Email services
        21
        25
        465
        587

        # Media and entertainment
        8096
        5000
        8123
        6600

        # Gaming services
        27015
        27036

        # Development and tools
        8080
        9090
        5555
        8095
        3030
        7000
        11434

        # Torrent/P2P
        6969
        6881
        7575

        # Media streaming/casting
        8008
        8009
        1900
        2869
        554
        3689
        5228

        # Remote access
        5900
        3283
        47990

        # Application specific
        563
        5353
        3456
        5001
        1188
        2875
        2880
        7100
        8191
        9696
        5055
        5690
        7878
        8989
        8200
        8686
        8787
        8920
        8888
        5656
        3001
      ];

      allowedUDPPorts = [
        5353
        1900
        8008
        8009
        7000
        7100
        554
        5000
        5001
        123
        5900
        3283
      ];

      allowedUDPPortRanges = [
        {
          from = 6000;
          to = 7000;
        }
        {
          from = 16384;
          to = 16403;
        }
        {
          from = 47998;
          to = 48000;
        }
        {
          from = 49152;
          to = 65535;
        }
      ];

      allowedTCPPortRanges = [
        {
          from = 49152;
          to = 65535;
        }
      ];
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
      packages = [pkgs.avahi];
    };
  };

  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
}
