# *arr Stack Services Virtual Hosts
# Sonarr, Radarr, Lidarr, Readarr, Prowlarr, etc.
{
  lib,
  ...
}:
let
  helpers = import ../helpers.nix { inherit lib; };
  inherit (helpers) mkReverseProxy;
in
{
  "prowlarr.blmt.io" = mkReverseProxy "127.0.0.1:9696";

  "sonarr.blmt.io" = mkReverseProxy "127.0.0.1:8989";

  "radarr.blmt.io" = mkReverseProxy "127.0.0.1:7878";

  "lidarr.blmt.io" = mkReverseProxy "127.0.0.1:8686";

  "readarr.blmt.io" = mkReverseProxy "127.0.0.1:8787";

  "listenarr.blmt.io" = mkReverseProxy "127.0.0.1:5000";

  "jellyseer.blmt.io" = mkReverseProxy "127.0.0.1:5055";

  "flaresolverr.blmt.io" = mkReverseProxy "127.0.0.1:8191";

  "cleanuparr.blmt.io" = mkReverseProxy "127.0.0.1:11011";
}
