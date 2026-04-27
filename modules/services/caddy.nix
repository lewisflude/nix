# Caddy Reverse Proxy Service
# Web server with automatic HTTPS and virtual hosts.
# Hosts opt in by importing nixos.caddy; ACME email comes from top-level config.useremail.
{ config, ... }:
let
  inherit (config) constants useremail;

  # Helper functions for Caddy configuration
  standardHeaders = ''
    header_up X-Real-IP {remote_host}
    header_up X-Forwarded-For {remote_host}
    header_up X-Forwarded-Proto {scheme}
  '';

  mkReverseProxy = target: {
    extraConfig = ''
      reverse_proxy ${target} {
        ${standardHeaders}
      }
      encode zstd gzip
    '';
  };

  # subdomain -> port for all services proxied via 127.0.0.1
  localServices = {
    # Infrastructure
    inherit (constants.ports.services) cockpit;
    ha = constants.ports.services.homeAssistant;
    assistant = constants.ports.services.musicAssistant;

    # Media
    inherit (constants.ports.services) jellyfin;
    inherit (constants.ports.services) seerr;
    inherit (constants.ports.services) homarr;
    inherit (constants.ports.services) wizarr;

    # Arr Stack
    inherit (constants.ports.services) prowlarr;
    inherit (constants.ports.services) sonarr;
    inherit (constants.ports.services) radarr;
    inherit (constants.ports.services) lidarr;
    inherit (constants.ports.services) readarr;
    inherit (constants.ports.services) bazarr;
    inherit (constants.ports.services) notifiarr;
    inherit (constants.ports.services) huntarr;
    inherit (constants.ports.services) autopulse;
    inherit (constants.ports.services) jellystat;
    inherit (constants.ports.services) flaresolverr;

    inherit (constants.ports.services) janitorr;

    # Supplemental
    inherit (constants.ports.services) termix;
    inherit (constants.ports.services) profilarr;
    inherit (constants.ports.services) listenarr;

    # Downloads
    usenet = constants.ports.services.sabnzbd;
    inherit (constants.ports.services) transmission;
    inherit (constants.ports.services) navidrome;

    # Streaming
    syncthing = constants.ports.services.syncthing.webUi;

    # AI
    inherit (constants.ports.services) ollama;
    openwebui = constants.ports.services.openWebui;
    inherit (constants.ports.services) comfyui;

    # File sharing
    files = constants.ports.services.filebrowser;
  };
in
{
  flake.modules.nixos.caddy =
    { lib, ... }:
    {
      services.caddy = {
        enable = true;
        email = useremail;
        virtualHosts =
          (lib.mapAttrs' (
            subdomain: port:
            lib.nameValuePair "${subdomain}.${constants.baseDomain}" (
              mkReverseProxy "127.0.0.1:${toString port}"
            )
          ) localServices)
          // {
            # Sunshine — admin panel serves HTTPS with self-signed cert
            "sunshine.${constants.baseDomain}" = {
              extraConfig = ''
                reverse_proxy https://127.0.0.1:${toString constants.ports.services.sunshine.https} {
                  transport http {
                    tls_insecure_skip_verify
                  }
                  ${standardHeaders}
                }
                encode zstd gzip
              '';
            };

            # VPN namespace — qBittorrent runs inside a network namespace, accessed via its gateway
            "torrent.${constants.baseDomain}" =
              mkReverseProxy "${constants.networks.vpnNamespace.gateway}:${toString constants.ports.services.qbittorrent}";

          };
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
    };
}
