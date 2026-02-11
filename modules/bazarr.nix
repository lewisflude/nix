# Bazarr Service Module - Dendritic Pattern
# Subtitle management for Sonarr/Radarr
# Usage: Import config.flake.modules.nixos.bazarr in host definition
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.bazarr =
    { lib, ... }:
    let
      inherit (lib) mkDefault optional;
      user = "media";
      group = "media";
    in
    {
      users.users.${user} = {
        isSystemUser = true;
        inherit group;
        description = "Media management user";
      };
      users.groups.${group} = { };

      services.bazarr = {
        enable = true;
        openFirewall = false;
        listenPort = constants.ports.services.bazarr;
        inherit user group;
      };

      networking.firewall.allowedTCPPorts = mkDefault [
        constants.ports.services.bazarr
      ];

      systemd.services.bazarr = {
        environment.TZ = mkDefault constants.defaults.timezone;
        after =
          (optional (config.services.sonarr.enable or false) "sonarr.service")
          ++ (optional (config.services.radarr.enable or false) "radarr.service");
        serviceConfig.UMask = "0002";
      };
    };
}
