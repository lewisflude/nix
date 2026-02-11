# Jellyseerr Service Module
# Media request management for Jellyfin
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.jellyseerr =
    { lib, ... }:
    {
      services.jellyseerr = {
        enable = true;
        openFirewall = true;
        port = constants.ports.services.jellyseerr;
      };

      systemd.services.jellyseerr = {
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
