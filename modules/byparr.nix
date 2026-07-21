# Byparr container module
# Cloudflare / anti-bot bypass for Prowlarr and the *arr stack.
# Drop-in replacement for FlareSolverr (Camoufox + FastAPI): listens on the same
# port 8191, so Prowlarr's existing FlareSolverr indexer proxy keeps working with
# no config change. FlareSolverr is increasingly broken against Cloudflare Turnstile
# in 2026; Byparr tracks new detection signals with a fast release cadence.
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.byparr = _: {
    virtualisation.podman.enable = true;
    virtualisation.oci-containers.backend = "podman";

    virtualisation.oci-containers.containers.byparr = {
      # Pinned to digest of :latest as of 2026-07-21 (upstream ships frequent releases).
      image = "ghcr.io/thephaseless/byparr@sha256:01a46a2865d9a6db5eb8ead04ec0dd33b8fbe233e8565ae70b50d4cc0af4cfb0";
      ports = [ "127.0.0.1:${toString constants.ports.services.byparr}:8191" ];
      environment = {
        TZ = constants.defaults.timezone;
        LOG_LEVEL = "info";
      };
      # Camoufox launches a headless Firefox; the default /dev/shm is too small and
      # causes browser crashes under load.
      extraOptions = [ "--shm-size=1g" ];
    };
  };
}
