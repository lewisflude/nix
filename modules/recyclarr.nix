# Recyclarr Service Module - Dendritic Pattern
# TRaSH Guides sync for Sonarr/Radarr
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.recyclarr = _: {
    services.recyclarr = {
      enable = true;
      # Run weekly to sync TRaSH guide profiles
      schedule = "Mon *-*-* 03:00:00";
      # Configuration is managed via recyclarr.yml in /var/lib/recyclarr/configs
      # See: https://recyclarr.dev/wiki/yaml/configuration-reference/
    };

    systemd.services.recyclarr.environment = {
      TZ = constants.defaults.timezone;
    };
  };
}
