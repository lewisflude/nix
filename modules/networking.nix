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
          # SSH is deliberately NOT opened here. eno2 carries both LAN traffic
          # and router-forwarded WAN traffic, so an interface-scoped rule cannot
          # separate them — opening 22 globally published sshd to the internet
          # (98 fail2ban bans and sustained root/ansible/zimbra brute-force
          # attempts in a single 21h boot). tailscale0 is already in
          # networking.firewall.trustedInterfaces (see tailscale.nix), so SSH
          # remains reachable over the tailnet with no port exposed.
          allowedTCPPorts = [ ];
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
          publish.userServices = true;
        };
        dbus.packages = [ pkgs.avahi ];
      };

      boot.kernel.sysctl = {
        # IP forwarding for containers/VPN
        "net.ipv4.conf.all.forwarding" = 1;
      };
    };
}
