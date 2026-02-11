# Networking configuration module
# Provides systemd-networkd, resolved, avahi, and firewall
_: {
  flake.modules.nixos.networking =
    { pkgs, lib, ... }:
    {
      networking = {
        enableIPv6 = lib.mkDefault true;
        useNetworkd = lib.mkDefault true;
        useDHCP = lib.mkDefault false;
        networkmanager.enable = lib.mkDefault false;
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
          publish.enable = true;
        };
        dbus.packages = [ pkgs.avahi ];
      };

      boot.kernel.sysctl = {
        # IP forwarding for containers/VPN
        "net.ipv4.conf.all.forwarding" = 1;
      };
    };
}
