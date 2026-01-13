# Media Services Virtual Hosts
# Jellyfin, Navidrome, etc.
{
  lib,
  ...
}:
let
  helpers = import ../helpers.nix { inherit lib; };
  inherit (helpers) mkReverseProxy;
in
{
  "jellyfin.blmt.io" = mkReverseProxy "localhost:8096";

  "music.blmt.io" = mkReverseProxy "localhost:8095";

  "comics.blmt.io" = mkReverseProxy "localhost:5656"; # Komga
}
