# Decluttarr - Auto-removes stalled/slow/failed downloads from arr queues
# Runs headless (no web UI) with host networking to reach arr services
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.decluttarr =
    _:
    let
      inherit (constants.defaults) timezone;
      localhost = "http://localhost";
      port = name: toString constants.ports.services.${name};
    in
    {
      virtualisation.oci-containers.containers.decluttarr = {
        image = "ghcr.io/manimatter/decluttarr:latest";
        extraOptions = [ "--network=host" ];
        environment = {
          TZ = timezone;
          LOG_LEVEL = "INFO";
          REMOVE_TIMER = "10";
          REMOVE_FAILED = "true";
          REMOVE_STALLED = "true";
          REMOVE_METADATA_MISSING = "true";
          REMOVE_ORPHANS = "true";
          REMOVE_UNMONITORED = "false";
          REMOVE_MISSING_FILES = "true";
          REMOVE_SLOW = "true";
          MIN_DOWNLOAD_SPEED = "100";
          PERMITTED_ATTEMPTS = "3";
          NO_STALLED_REMOVAL_QBIT_TAG = "dont_delete";
          SONARR_URL = "${localhost}:${port "sonarr"}";
          SONARR_KEY = "CHANGE_ME";
          RADARR_URL = "${localhost}:${port "radarr"}";
          RADARR_KEY = "CHANGE_ME";
          LIDARR_URL = "${localhost}:${port "lidarr"}";
          LIDARR_KEY = "CHANGE_ME";
          READARR_URL = "${localhost}:${port "readarr"}";
          READARR_KEY = "CHANGE_ME";
          QBITTORRENT_URL = "${localhost}:${port "qbittorrent"}";
        };
      };
    };
}
