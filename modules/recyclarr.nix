# Recyclarr Service Module - Dendritic Pattern
# TRaSH Guides sync for Sonarr/Radarr.
#
# Config is declarative via services.recyclarr.configuration (rendered to YAML and
# secret-substituted with genJqSecretsReplacement). This is the single source of
# truth for custom formats + quality profiles — Profilarr must NOT also be pointed
# at these instances or the two will fight over the same profiles. See [[user_private_trackers]].
#
# Uses guide-backed quality profiles (referenced by TRaSH `trash_id`), which auto-import
# the profile's qualities, score sets, custom formats and default CF groups — no `include`
# or explicit custom_formats block needed. (The `include:` directive is NOT usable here:
# this recyclarr/TRaSH version ships an empty includes manifest; the on-disk `templates/`
# files are for `recyclarr config create`, not inclusion.) Profiles chosen to match what
# this box actually grabs: UHD HDR/DV + HD movies, 2160p + 1080p WEB series.
{ config, ... }:
let
  inherit (config) constants;
  media = config.mediaLib;
  ports = constants.ports.services;
in
{
  flake.modules.nixos.recyclarr = nixosArgs: {
    services.recyclarr = {
      enable = true;
      # Run weekly to sync TRaSH guide profiles
      schedule = "Mon *-*-* 03:00:00";
      # See: https://recyclarr.dev/wiki/yaml/configuration-reference/
      configuration = {
        radarr.movies = {
          base_url = "http://localhost:${toString ports.radarr}";
          # Radarr API key (shared with janitorr; secret declared in podman-containers.nix).
          api_key._secret = nixosArgs.config.sops.secrets."janitorr-radarr-api-key".path;
          # Remove custom formats recyclarr previously created but no longer manages.
          delete_old_custom_formats = true;
          quality_definition.type = "movie";
          quality_profiles = [
            {
              trash_id = "d1d67249d3890e49bc12e275d989a7e9"; # HD Bluray + WEB
              reset_unmatched_scores.enabled = true;
            }
            {
              trash_id = "64fb5f9858489bdac2af690e27c8f42f"; # UHD Bluray + WEB
              reset_unmatched_scores.enabled = true;
            }
          ];
        };
        sonarr.series = {
          base_url = "http://localhost:${toString ports.sonarr}";
          # Sonarr API key (shared with janitorr; secret declared in podman-containers.nix).
          api_key._secret = nixosArgs.config.sops.secrets."janitorr-sonarr-api-key".path;
          delete_old_custom_formats = true;
          quality_definition.type = "series";
          quality_profiles = [
            {
              trash_id = "72dae194fc92bf828f32cde7744e51a1"; # WEB-1080p
              reset_unmatched_scores.enabled = true;
            }
            {
              trash_id = "d1498e7d189fbe6c7110ceaabb7473e6"; # WEB-2160p
              reset_unmatched_scores.enabled = true;
            }
          ];
        };
      };
    };

    # serviceDefaults supplies TZ and the shared network ordering; recyclarr
    # keeps its own upstream User/Group. The storage-mount dependency is
    # dropped: recyclarr only talks to the *arr APIs over HTTP and never reads
    # /mnt/storage, so it stays useful while the array is down.
    systemd.services.recyclarr = media.serviceDefaults // {
      after = builtins.filter (unit: unit != "mnt-storage.mount") media.serviceDefaults.after;
      requires = builtins.filter (unit: unit != "mnt-storage.mount") media.serviceDefaults.requires;
    };

    # Rotating either API key restarts recyclarr too (concatenates with the
    # podman-janitorr.service restart unit set in podman-containers.nix).
    sops.secrets."janitorr-radarr-api-key".restartUnits = [ "recyclarr.service" ];
    sops.secrets."janitorr-sonarr-api-key".restartUnits = [ "recyclarr.service" ];
  };
}
