# Miscellaneous Services Virtual Hosts
# Home Assistant, Cal.com, Dockge, Termix, Checkrr, Time tracking, Wizarr
{
  lib,
  ...
}:
let
  helpers = import ../helpers.nix { inherit lib; };
  inherit (helpers) mkReverseProxy;
in
{
  "home.blmt.io" = mkReverseProxy "127.0.0.1:8123"; # Home Assistant

  "cal.blmt.io" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:3000 {
        header_up Host {host}
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
        header_up X-Forwarded-Host {host}
      }
      encode zstd gzip
    '';
  };

  "dockge.blmt.io" = mkReverseProxy "127.0.0.1:5001";

  "termix.blmt.io" = mkReverseProxy "127.0.0.1:8083"; # SSH Management

  "checkrr.blmt.io" = mkReverseProxy "127.0.0.1:8585";

  "time.blmt.io" = mkReverseProxy "127.0.0.1:8001"; # Time tracking

  "invite.blmt.io" = mkReverseProxy "127.0.0.1:5690"; # Wizarr
}
