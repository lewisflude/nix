# Caddy Reverse Proxy Service
# Web server with automatic HTTPS and virtual hosts
{ config, ... }:
let
  constants = config.constants;

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
in
{
  flake.modules.nixos.caddy =
    {
      pkgs,
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
        email = cfg.email;
        virtualHosts = {
          # Infrastructure
          "cockpit.blmt.io" = mkReverseProxy "127.0.0.1:${toString constants.ports.services.cockpit}";
          "ha.blmt.io" = mkReverseProxy "127.0.0.1:${toString constants.ports.services.homeAssistant}";
          "assistant.blmt.io" =
            mkReverseProxy "127.0.0.1:${toString constants.ports.services.musicAssistant}";

          # Media
          "jellyfin.blmt.io" = mkReverseProxy "127.0.0.1:${toString constants.ports.services.jellyfin}";
          "jellyseerr.blmt.io" = mkReverseProxy "127.0.0.1:${toString constants.ports.services.jellyseerr}";
          "homarr.blmt.io" = mkReverseProxy "127.0.0.1:${toString constants.ports.services.homarr}";
          "wizarr.blmt.io" = mkReverseProxy "127.0.0.1:${toString constants.ports.services.wizarr}";

          # Arr Stack
          "prowlarr.blmt.io" = mkReverseProxy "127.0.0.1:${toString constants.ports.services.prowlarr}";
          "sonarr.blmt.io" = mkReverseProxy "127.0.0.1:${toString constants.ports.services.sonarr}";
          "radarr.blmt.io" = mkReverseProxy "127.0.0.1:${toString constants.ports.services.radarr}";
          "lidarr.blmt.io" = mkReverseProxy "127.0.0.1:${toString constants.ports.services.lidarr}";
          "readarr.blmt.io" = mkReverseProxy "127.0.0.1:${toString constants.ports.services.readarr}";
          "bazarr.blmt.io" = mkReverseProxy "127.0.0.1:${toString constants.ports.services.bazarr}";
          "autobrr.blmt.io" = mkReverseProxy "127.0.0.1:${toString constants.ports.services.autobrr}";

          # Downloads
          "torrent.blmt.io" = mkReverseProxy "192.168.15.1:8080";
          "usenet.blmt.io" = mkReverseProxy "127.0.0.1:${toString constants.ports.services.sabnzbd}";

          # AI
          "ollama.blmt.io" = mkReverseProxy "127.0.0.1:${toString constants.ports.services.ollama}";
          "openwebui.blmt.io" = mkReverseProxy "127.0.0.1:${toString constants.ports.services.openWebui}";
          "comfyui.blmt.io" = mkReverseProxy "127.0.0.1:${toString constants.ports.services.comfyui}";
        };
      };

      networking.firewall.allowedTCPPorts = lib.mkIf cfg.enable [
        80
        443
      ];
    };
}
