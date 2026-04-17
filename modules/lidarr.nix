{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.lidarr =
    { config, lib, ... }:
    let
      inherit (lib) mkDefault mkForce optional;
      user = "media";
      group = "media";
    in
    {
      systemd.tmpfiles.rules = [
        "d '/mnt/storage/media' 0770 ${user} ${group} - -"
        "d '/mnt/storage/media/music' 0770 ${user} ${group} - -"
      ];

      services.lidarr = {
        enable = true;
        inherit user group;
      };

      networking.firewall.allowedTCPPorts = mkDefault [
        constants.ports.services.lidarr
      ];

      systemd.services.lidarr = {
        environment.TZ = mkDefault constants.defaults.timezone;
        after = [ "mnt-storage.mount" ] ++ optional config.services.prowlarr.enable "prowlarr.service";
        requires = [ "mnt-storage.mount" ];
        serviceConfig.UMask = mkForce "0002";
      };
    };
}
