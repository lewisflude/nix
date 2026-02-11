# Sonarr Service Module - Dendritic Pattern
# TV show management for *arr stack
# Usage: Import config.flake.modules.nixos.sonarr in host definition
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.sonarr =
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
        "d '/mnt/storage/media/tv' 0770 ${user} ${group} - -"
      ];

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
        after = [
          "mnt-storage.mount"
        ]
        ++ (optional (config.services.prowlarr.enable or false) "prowlarr.service");
        requires = [ "mnt-storage.mount" ];
        serviceConfig.UMask = "0002";
      };
    };
}
