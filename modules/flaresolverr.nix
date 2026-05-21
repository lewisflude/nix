# FlareSolverr container module
# Cloudflare bypass for Prowlarr and *arr stack
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.flaresolverr = _: {
    virtualisation.podman.enable = true;
    virtualisation.oci-containers.backend = "podman";

    virtualisation.oci-containers.containers.flaresolverr = {
      image = "ghcr.io/flaresolverr/flaresolverr:latest";
      ports = [ "127.0.0.1:${toString constants.ports.services.flaresolverr}:8191" ];
      environment = {
        TZ = constants.defaults.timezone;
        LOG_LEVEL = "info";
        LOG_HTML = "false";
        CAPTCHA_SOLVER = "none";
      };
    };
  };
}
