# Tailscale mesh VPN for cross-network access to Jupiter's services
# Enables remote Sunshine/Moonlight streaming, SSH, and service access
_: {
  flake.modules.nixos.tailscale = _: {
    services.tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "server";
    };

    networking.firewall.trustedInterfaces = [ "tailscale0" ];
  };

  flake.modules.darwin.tailscale =
    { lib, pkgs, ... }:
    {
      services.tailscale.enable = true;

      # Advertise this daemon as an exit node (needs admin console approval).
      # The explicit socket avoids the GUI app, which is a separate node.
      launchd.daemons.tailscale-exit-node = {
        script = ''
          until [ -S /var/run/tailscaled.socket ]; do sleep 1; done
          exec ${lib.getExe pkgs.tailscale} --socket=/var/run/tailscaled.socket \
            set --advertise-exit-node
        '';
        serviceConfig = {
          RunAtLoad = true;
          KeepAlive.SuccessfulExit = false;
        };
      };
    };
}
