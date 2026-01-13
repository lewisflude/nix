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
  "home.blmt.io" = mkReverseProxy "localhost:8123"; # Home Assistant

  "cal.blmt.io" = {
    extraConfig = ''
      reverse_proxy localhost:3000 {
        header_up Host {host}
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
        header_up X-Forwarded-Host {host}
      }
      encode zstd gzip
    '';
  };

  "dockge.blmt.io" = mkReverseProxy "localhost:5001";

  "termix.blmt.io" = mkReverseProxy "localhost:8083"; # SSH Management

  "checkrr.blmt.io" = mkReverseProxy "localhost:8585";

  "time.blmt.io" = mkReverseProxy "localhost:8001"; # Time tracking

  "invite.blmt.io" = mkReverseProxy "localhost:5690"; # Wizarr
}
