# Readarr Service Module - Dendritic Pattern
# Ebook/audiobook management for *arr stack
# Usage: Import config.flake.modules.nixos.readarr in host definition
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.readarr =
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

      # Ensure library directory exists
      systemd.tmpfiles.rules = [
        "d '/mnt/storage/books' 0770 ${user} ${group} - -"
      ];

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
        after = [
          "mnt-storage.mount"
        ]
        ++ (optional (config.services.prowlarr.enable or false) "prowlarr.service");
        requires = [ "mnt-storage.mount" ];
        serviceConfig.UMask = "0002";
      };
    };
}
