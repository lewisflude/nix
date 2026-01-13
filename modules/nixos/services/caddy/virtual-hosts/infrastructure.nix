# Infrastructure Services Virtual Hosts
# Pi-hole, Cockpit, UniFi Controller, etc.
{
  lib,
  ...
}:
let
  helpers = import ../helpers.nix { inherit lib; };
  inherit (helpers) mkReverseProxy;
in
{
  "pihole.blmt.io" = {
    extraConfig = ''
      reverse_proxy 192.168.10.10:8080 {
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
      }
      encode zstd gzip
      redir / /admin{uri}
    '';
  };

  "cockpit.blmt.io" = mkReverseProxy "localhost:9090";

  "unifi.blmt.io" = mkReverseProxy "192.168.10.1:443";

  "blmt.io" = mkReverseProxy "localhost:7575"; # Homarr Dashboard
}
