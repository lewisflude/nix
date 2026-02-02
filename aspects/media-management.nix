# Media Management Aspect
#
# Bridge module: Forwards host.features.mediaManagement to host.services.mediaManagement
# Reads options from config.host.features.mediaManagement
#
# Platform support:
# - NixOS: Full media management stack (Prowlarr, Radarr, Sonarr, etc.)
# - Darwin: Not supported (services require systemd)
#
# TODO: Consolidate feature and service options to eliminate this indirection
# See docs/reference/REFACTORING_EXAMPLES.md for the recommended pattern
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
  cfg = config.host.features.mediaManagement;
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  config = mkMerge [
    # ================================================================
    # NixOS Configuration
    # ================================================================
    (mkIf (cfg.enable && isLinux) {
      host.services.mediaManagement = {
        enable = true;
        inherit (cfg)
          dataPath
          timezone
          prowlarr
          radarr
          sonarr
          lidarr
          readarr
          listenarr
          sabnzbd
          qbittorrent
          transmission
          jellyfin
          jellyseerr
          flaresolverr
          unpackerr
          navidrome
          ;
      };
    })

    # ================================================================
    # Darwin Configuration
    # ================================================================
    (mkIf (cfg.enable && isDarwin) {
      # Media management services require systemd and are not available on macOS
      # Use Docker containers or native apps instead
    })

    # ================================================================
    # Assertions (both platforms)
    # ================================================================
    {
      assertions = [
        {
          assertion = !(cfg.enable && isDarwin);
          message = "Media management services are not available on macOS (requires systemd)";
        }
      ];
    }
  ];
}
