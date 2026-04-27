# Seerr Service Module
# Media request management for Jellyfin
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.seerr =
    { lib, ... }:
    {
      services.seerr = {
        enable = true;
        openFirewall = true;
        port = constants.ports.services.seerr;
      };

      systemd.services.seerr = {
        after = lib.mkAfter [ "jellyfin.service" ];
        environment = {
          TZ = constants.defaults.timezone;
          LOG_LEVEL = "info";
        };
        serviceConfig = {
          User = "media";
          Group = "media";
        };
      };
    };
}
