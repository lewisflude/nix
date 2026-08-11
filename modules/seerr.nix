# Seerr Service Module
# Media request management for Jellyfin
{ config, ... }:
let
  inherit (config) constants;
  media = config.mediaLib;
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

      # serviceDefaults supplies TZ/after/requires/UMask — seerr reads the same
      # library paths as Jellyfin, so it needs the mnt-storage ordering the other
      # media units already have. jellyfin.service is appended to that ordering
      # rather than replacing it.
      systemd.services.seerr = lib.recursiveUpdate media.serviceDefaults {
        after = media.serviceDefaults.after ++ [ "jellyfin.service" ];
        environment.LOG_LEVEL = "info";
        serviceConfig = {
          User = media.user;
          Group = media.group;
        };
      };
    };
}
