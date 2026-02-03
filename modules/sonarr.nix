# Sonarr Service Module - Dendritic Pattern
# TV show management for *arr stack
# Usage: Import config.flake.modules.nixos.sonarr in host definition
{ config, ... }:
let
  constants = config.constants;
in
{
  flake.modules.nixos.sonarr = { lib, ... }:
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

    services.sonarr = {
      enable = true;
      openFirewall = false;
      inherit user group;
      dataDir = "/var/lib/sonarr/.config/Sonarr";
    };

    networking.firewall.allowedTCPPorts = mkDefault [
      constants.ports.services.sonarr
    ];

    systemd.services.sonarr = {
      environment.TZ = mkDefault constants.defaults.timezone;
      after = mkAfter (optional (config.services.prowlarr.enable or false) "prowlarr.service");
    };
  };
}
