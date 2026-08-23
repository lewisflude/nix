# Networking configuration module
# Provides systemd-networkd, resolved, avahi, and firewall
_: {
  flake.modules.nixos.networking =
    {
      pkgs,
      lib,
      config,
      ...
    }:
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

      # Enabling NetworkManager alongside networkd is a silent conflict: nixpkgs
      # has no assertion for it, NM does not populate `unmanaged-devices` from
      # networkd's .network units, and the one warning that would fire
      # (network-interfaces.nix) is gated on `useDHCP = true` — which the
      # NetworkManager module itself sets to false. The result is two DHCP
      # clients, two default routes and duplicate SLAAC addresses on one link,
      # with resolved logging `LinkBusy` on every boot. Make it loud instead.
      assertions = [
        {
          assertion = !(config.networking.useNetworkd && config.networking.networkmanager.enable);
          message = ''
            Both systemd-networkd and NetworkManager are enabled. They will both
            claim the same links. Pick one backend; for wifi alongside networkd
            use networking.wireless.iwd instead of NetworkManager.
          '';
        }
      ];

      systemd.network = {
        enable = true;
        wait-online = {
          timeout = 10;
          anyInterface = true;
        };
        # No networks."<name>" here: interface names are host hardware facts.
        # See modules/hosts/jupiter/hardware.nix for Jupiter's eno2 unit.
      };

      # Don't drop the uplink across a rebuild — restart rather than stop+start.
      # Matches nix-community/srvos and Mic92/dotfiles.
      systemd.services = {
        systemd-networkd.stopIfChanged = false;
        systemd-resolved.stopIfChanged = false;
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
