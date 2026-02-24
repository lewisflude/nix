{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.prowlarr =
    { lib, ... }:
    let
      inherit (lib) mkDefault mkForce;
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

      services.prowlarr.enable = true;

      networking.firewall.allowedTCPPorts = mkDefault [
        constants.ports.services.prowlarr
      ];

      systemd.services.prowlarr = {
        environment.TZ = mkDefault constants.defaults.timezone;
        serviceConfig = {
          User = user;
          Group = group;
          UMask = mkForce "0002";
        };
      };
    };
}
