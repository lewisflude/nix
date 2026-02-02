# Miscellaneous Services Virtual Hosts
# Home Assistant, Dockge, Termix, Checkrr, Time tracking, Wizarr
{
  lib,
  ...
}:
let
  helpers = import ../helpers.nix { inherit lib; };
  inherit (helpers) mkReverseProxy;
in
{
  # NOTE: home.blmt.io moved to infrastructure.nix

  # TODO: dockge service not configured - remove or enable service
  # "dockge.blmt.io" = mkReverseProxy "127.0.0.1:5001";

  "termix.blmt.io" = mkReverseProxy "127.0.0.1:8083"; # SSH Management

  "checkrr.blmt.io" = mkReverseProxy "127.0.0.1:8585";

  "time.blmt.io" = mkReverseProxy "127.0.0.1:8001"; # Time tracking

  "invite.blmt.io" = mkReverseProxy "127.0.0.1:5690"; # Wizarr
}
