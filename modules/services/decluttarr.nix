# Decluttarr - Auto-removes stalled/slow/failed downloads from arr queues
# Runs headless (no web UI) with host networking to reach arr services
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.decluttarr =
    nixosArgs:
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
          RADARR_URL = "${localhost}:${port "radarr"}";
          LIDARR_URL = "${localhost}:${port "lidarr"}";
          READARR_URL = "${localhost}:${port "readarr"}";
          QBITTORRENT_URL = "${localhost}:${port "qbittorrent"}";
        };
        environmentFiles = [
          nixosArgs.config.sops.templates."decluttarr.env".path
        ];
      };

      sops.secrets."decluttarr-sonarr-api-key" = {
        restartUnits = [ "podman-decluttarr.service" ];
      };
      sops.secrets."decluttarr-radarr-api-key" = {
        restartUnits = [ "podman-decluttarr.service" ];
      };
      sops.secrets."decluttarr-lidarr-api-key" = {
        restartUnits = [ "podman-decluttarr.service" ];
      };
      sops.secrets."decluttarr-readarr-api-key" = {
        restartUnits = [ "podman-decluttarr.service" ];
      };

      sops.templates."decluttarr.env".content = ''
        SONARR_KEY=${nixosArgs.config.sops.placeholder."decluttarr-sonarr-api-key"}
        RADARR_KEY=${nixosArgs.config.sops.placeholder."decluttarr-radarr-api-key"}
        LIDARR_KEY=${nixosArgs.config.sops.placeholder."decluttarr-lidarr-api-key"}
        READARR_KEY=${nixosArgs.config.sops.placeholder."decluttarr-readarr-api-key"}
      '';
    };
}
