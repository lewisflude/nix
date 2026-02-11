# FlareSolverr Service Module
# Cloudflare bypass for Prowlarr and *arr stack
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.flaresolverr =
    _:
    {
      services.flaresolverr = {
        enable = true;
        openFirewall = true;
        port = constants.ports.services.flaresolverr;
      };

      systemd.services.flaresolverr.environment = {
        TZ = constants.defaults.timezone;
        LOG_LEVEL = "info";
      };
    };
}
