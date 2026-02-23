# Huntarr - Aggressively searches for missing/cutoff-unmet media
# Periodically triggers searches in Sonarr/Radarr/Lidarr for wanted items
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.huntarr =
    _:
    let
      configPath = "/var/lib/containers/supplemental";
      inherit (constants.defaults) timezone;
    in
    {
      virtualisation.oci-containers.containers.huntarr = {
        image = "ghcr.io/plexguide/huntarr:latest";
        environment = {
          TZ = timezone;
        };
        volumes = [
          "${configPath}/huntarr:/config"
        ];
        ports = [ "127.0.0.1:${toString constants.ports.services.huntarr}:9705" ];
      };

      systemd.tmpfiles.rules = [
        "d ${configPath}/huntarr 0755 root root -"
      ];
    };
}
