# Simple OCI container services — one container each, no bespoke wiring.
# Everything here is declared as data and turned into containers, state dirs and
# firewall ports by `config.containerLib.mkContainers`.
{ config, ... }:
let
  inherit (config) constants containerLib;
in
{
  flake.modules.nixos.containers = _: {
    imports = [
      (containerLib.mkContainers {
        # Autopulse — media-server scan trigger. Localhost-only; state dir stays
        # root-owned because the image runs as root.
        # Pinned to digest of :latest as of 2026-04-30
        autopulse = {
          image = "ghcr.io/dan-online/autopulse@sha256:383b63d25a30ea3945b23462aba0864094c3f76614854bce19edaca26a34b160";
          port = constants.ports.services.autopulse;
          internalPort = 2875;
          localhost = true;
          uid = "root";
          gid = "root";
          extraEnv = {
            AUTOPULSE__APP__DATABASE_URL = "sqlite:///app/config/autopulse.db?mode=rwc";
            AUTOPULSE__APP__LOG_LEVEL = "info";
          };
        };

        # Byparr — Cloudflare / anti-bot bypass for Prowlarr and the *arr stack.
        # Drop-in replacement for FlareSolverr (Camoufox + FastAPI): listens on the
        # same port 8191, so Prowlarr's existing FlareSolverr indexer proxy keeps
        # working with no config change. FlareSolverr is increasingly broken against
        # Cloudflare Turnstile in 2026; Byparr tracks new detection signals with a
        # fast release cadence. Stateless, so no config dir.
        # Pinned to digest of :latest as of 2026-07-21 (upstream ships frequent releases).
        byparr = {
          image = "ghcr.io/thephaseless/byparr@sha256:01a46a2865d9a6db5eb8ead04ec0dd33b8fbe233e8565ae70b50d4cc0af4cfb0";
          port = constants.ports.services.byparr;
          internalPort = 8191;
          localhost = true;
          configDir = false;
          extraEnv = {
            LOG_LEVEL = "info";
          };
          # Camoufox launches a headless Firefox; the default /dev/shm is too small
          # and causes browser crashes under load.
          extraOptions = [ "--shm-size=1g" ];
        };
      })
    ];

    virtualisation.podman.enable = true;
    virtualisation.oci-containers.backend = "podman";
  };
}
