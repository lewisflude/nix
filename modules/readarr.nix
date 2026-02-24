{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.readarr =
    { config, lib, ... }:
    let
      inherit (lib) mkDefault mkForce optional;
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

      systemd.tmpfiles.rules = [
        "d '/mnt/storage/books' 0770 ${user} ${group} - -"
      ];

      services.readarr = {
        enable = true;
        inherit user group;
      };

      networking.firewall.allowedTCPPorts = mkDefault [
        constants.ports.services.readarr
      ];

      systemd.services.readarr = {
        environment.TZ = mkDefault constants.defaults.timezone;
        after = [ "mnt-storage.mount" ] ++ optional config.services.prowlarr.enable "prowlarr.service";
        requires = [ "mnt-storage.mount" ];
        serviceConfig.UMask = mkForce "0002";
      };
    };
}
