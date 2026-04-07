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
}
