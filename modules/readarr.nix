# Readarr Service Module - Dendritic Pattern
# Book management for *arr stack
# Usage: Import config.flake.modules.nixos.readarr in host definition
{ config, ... }:
let
  constants = config.constants;
in
{
  flake.modules.nixos.readarr = { lib, ... }:
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

    services.readarr = {
      enable = true;
      openFirewall = false;
      inherit user group;
    };

    networking.firewall.allowedTCPPorts = mkDefault [
      constants.ports.services.readarr
    ];

    systemd.services.readarr = {
      environment.TZ = mkDefault constants.defaults.timezone;
      after = mkAfter (optional (config.services.prowlarr.enable or false) "prowlarr.service");
    };
  };
}
