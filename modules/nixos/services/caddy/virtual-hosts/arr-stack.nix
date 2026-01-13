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
  "prowlarr.blmt.io" = mkReverseProxy "localhost:9696";

  "sonarr.blmt.io" = mkReverseProxy "localhost:8989";

  "radarr.blmt.io" = mkReverseProxy "localhost:7878";

  "lidarr.blmt.io" = mkReverseProxy "localhost:8686";

  "readarr.blmt.io" = mkReverseProxy "localhost:8787";

  "listenarr.blmt.io" = mkReverseProxy "localhost:5000";

  "jellyseer.blmt.io" = mkReverseProxy "localhost:5055";

  "flaresolverr.blmt.io" = mkReverseProxy "localhost:8191";

  "cleanuparr.blmt.io" = mkReverseProxy "localhost:11011";
}
