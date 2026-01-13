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
  "jellyfin.blmt.io" = mkReverseProxy "127.0.0.1:8096";

  "music.blmt.io" = mkReverseProxy "127.0.0.1:8095";

  "comics.blmt.io" = mkReverseProxy "127.0.0.1:5656"; # Komga
}
