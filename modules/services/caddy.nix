# Caddy Reverse Proxy Service
# Web server with automatic HTTPS and virtual hosts
{ config, ... }:
let
  inherit (config) constants;

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
    inherit (constants.ports.services) jellyseerr;
    inherit (constants.ports.services) homarr;
    inherit (constants.ports.services) wizarr;

    # Arr Stack
    inherit (constants.ports.services) prowlarr;
    inherit (constants.ports.services) sonarr;
    inherit (constants.ports.services) radarr;
    inherit (constants.ports.services) lidarr;
    inherit (constants.ports.services) readarr;
    inherit (constants.ports.services) bazarr;
    inherit (constants.ports.services) autobrr;

    # Downloads
    usenet = constants.ports.services.sabnzbd;

    # AI
    inherit (constants.ports.services) ollama;
    openwebui = constants.ports.services.openWebui;
    inherit (constants.ports.services) comfyui;
  };
in
{
  flake.modules.nixos.caddy =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.host.services.caddy;
    in
    {
      services.caddy = lib.mkIf cfg.enable {
        enable = true;
        inherit (cfg) email;
        virtualHosts =
          (lib.mapAttrs' (
            subdomain: port:
            lib.nameValuePair "${subdomain}.${constants.baseDomain}" (
              mkReverseProxy "127.0.0.1:${toString port}"
            )
          ) localServices)
          // {
            # VPN namespace — different IP, not localhost
            "torrent.${constants.baseDomain}" = mkReverseProxy "192.168.15.1:8080";
          };
      };

      networking.firewall.allowedTCPPorts = lib.mkIf cfg.enable [
        80
        443
      ];
    };
}
