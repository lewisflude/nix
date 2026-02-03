# Radarr Service Module - Dendritic Pattern
# Movie management for *arr stack
# Usage: Import config.flake.modules.nixos.radarr in host definition
{ config, ... }:
let
  constants = config.constants;
in
{
  flake.modules.nixos.radarr = { lib, ... }:
  let
    inherit (lib) mkDefault mkAfter optional;
    user = "media";
    group = "media";
  in
  {
    users.users.${user} = {
      isSystemUser = true;
      group = group;
      description = "Media management user";
    };
    users.groups.${group} = { };

    services.radarr = {
      enable = true;
      openFirewall = false;
      inherit user group;
    };

    networking.firewall.allowedTCPPorts = mkDefault [
      constants.ports.services.radarr
    ];

    systemd.services.radarr = {
      environment.TZ = mkDefault constants.defaults.timezone;
      # Start after prowlarr if it exists
      after = mkAfter (optional (config.services.prowlarr.enable or false) "prowlarr.service");
    };
  };
}
