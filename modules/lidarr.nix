# Lidarr Service Module - Dendritic Pattern
# Music management for *arr stack
# Usage: Import config.flake.modules.nixos.lidarr in host definition
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.lidarr =
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

      # Ensure library directories exist (TRASHguides: /mnt/storage/media/<type>)
      systemd.tmpfiles.rules = [
        "d '/mnt/storage/media' 0770 ${user} ${group} - -"
        "d '/mnt/storage/media/music' 0770 ${user} ${group} - -"
      ];

      services.lidarr = {
        enable = true;
        openFirewall = false;
        inherit user group;
      };

      networking.firewall.allowedTCPPorts = mkDefault [
        constants.ports.services.lidarr
      ];

      systemd.services.lidarr = {
        environment.TZ = mkDefault constants.defaults.timezone;
        after = [
          "mnt-storage.mount"
        ]
        ++ (optional (config.services.prowlarr.enable or false) "prowlarr.service");
        requires = [ "mnt-storage.mount" ];
        serviceConfig.UMask = "0002";
      };
    };
}
