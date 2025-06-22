{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    networkmanagerapplet
  ];


  networking = {
    hostName = "jupiter";
    enableIPv6 = true;
    networkmanager.enable = true;
    networkmanager.dns = "systemd-resolved";

    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        21
        25
        27015
        27036
        8123
        8095
        80
        443
        563
        6600
        5353
        3456
        5555
        5001
        8096
        1188
        8080
        9090
        2875
        2880
        7000
        11434
        7878
        8989
        5055
        5690
        8191
        9696
        3030
        465
        587
        5000
        7100
        8008
        8009
        8200
        1900
        2869
        554
        3689
        5228
        3283
        5900
        47990
        8686
        8787
        8920
        8888
        5656
        6969
        6881
        7575
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
        { from = 6000; to = 7000; }
        { from = 16384; to = 16403; }
        { from = 47998; to = 48000; }
        { from = 49152; to = 65535; }
      ];

      allowedTCPPortRanges = [
        { from = 49152; to = 65535; }
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

