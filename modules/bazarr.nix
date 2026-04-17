{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.bazarr =
    { config, lib, ... }:
    let
      inherit (lib) mkDefault mkForce optional;
      user = "media";
      group = "media";
    in
    {
      services.bazarr = {
        enable = true;
        listenPort = constants.ports.services.bazarr;
        inherit user group;
      };

      networking.firewall.allowedTCPPorts = mkDefault [
        constants.ports.services.bazarr
      ];

      systemd.services.bazarr = {
        environment.TZ = mkDefault constants.defaults.timezone;
        after =
          optional config.services.sonarr.enable "sonarr.service"
          ++ optional config.services.radarr.enable "radarr.service";
        serviceConfig.UMask = mkForce "0002";
      };
    };
}
