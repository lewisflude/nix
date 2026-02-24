{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.sonarr =
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
        "d '/mnt/storage/media' 0770 ${user} ${group} - -"
        "d '/mnt/storage/media/tv' 0770 ${user} ${group} - -"
      ];

      services.sonarr = {
        enable = true;
        inherit user group;
        dataDir = "/var/lib/sonarr/.config/Sonarr";
      };

      networking.firewall.allowedTCPPorts = mkDefault [
        constants.ports.services.sonarr
      ];

      systemd.services.sonarr = {
        environment.TZ = mkDefault constants.defaults.timezone;
        after = [ "mnt-storage.mount" ] ++ optional config.services.prowlarr.enable "prowlarr.service";
        requires = [ "mnt-storage.mount" ];
        serviceConfig.UMask = mkForce "0002";
      };
    };
}
