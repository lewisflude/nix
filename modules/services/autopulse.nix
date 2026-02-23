# Autopulse - Triggers Jellyfin library scan immediately on import
# Listens for arr webhook events and notifies Jellyfin to refresh
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.autopulse =
    _:
    let
      configPath = "/var/lib/containers/supplemental";
      inherit (constants.defaults) timezone;
    in
    {
      virtualisation.oci-containers.containers.autopulse = {
        image = "ghcr.io/dan-online/autopulse:latest";
        environment = {
          TZ = timezone;
          AUTOPULSE__APP__DATABASE_URL = "sqlite:///app/config/autopulse.db?mode=rwc";
          AUTOPULSE__APP__LOG_LEVEL = "info";
        };
        volumes = [
          "${configPath}/autopulse:/app/config"
        ];
        ports = [ "127.0.0.1:${toString constants.ports.services.autopulse}:2875" ];
      };

      systemd.tmpfiles.rules = [
        "d ${configPath}/autopulse 0755 root root -"
      ];
    };
}
