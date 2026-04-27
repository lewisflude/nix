# *arr media management stack: prowlarr (indexer), radarr/sonarr/lidarr/readarr
# (downloaders), bazarr (subtitles). Co-located in one module — they share
# user/group, storage mount dependency, and systemd boilerplate.
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.arrStack =
    nixosArgs:
    let
      inherit (nixosArgs) lib;
      cfg = nixosArgs.config;
      inherit (lib) mkDefault mkForce optional;
      user = "media";
      group = "media";
      tz = constants.defaults.timezone;
      mediaDirRule = sub: "d '/mnt/storage/media/${sub}' 0770 ${user} ${group} - -";
      storageBound = {
        environment.TZ = mkDefault tz;
        after = [ "mnt-storage.mount" ] ++ optional cfg.services.prowlarr.enable "prowlarr.service";
        requires = [ "mnt-storage.mount" ];
        serviceConfig.UMask = mkForce "0002";
      };
    in
    {
      systemd.tmpfiles.rules = [
        "d '/mnt/storage/media' 0770 ${user} ${group} - -"
        (mediaDirRule "movies")
        (mediaDirRule "tv")
        (mediaDirRule "music")
        "d '/mnt/storage/books' 0770 ${user} ${group} - -"
      ];

      services.radarr = {
        enable = true;
        inherit user group;
      };
      services.sonarr = {
        enable = true;
        inherit user group;
        dataDir = "/var/lib/sonarr/.config/Sonarr";
      };
      services.lidarr = {
        enable = true;
        inherit user group;
      };
      services.readarr = {
        enable = true;
        inherit user group;
      };
      services.bazarr = {
        enable = true;
        inherit user group;
        listenPort = constants.ports.services.bazarr;
      };
      services.prowlarr.enable = true;

      networking.firewall.allowedTCPPorts = mkDefault [
        constants.ports.services.radarr
        constants.ports.services.sonarr
        constants.ports.services.lidarr
        constants.ports.services.readarr
        constants.ports.services.bazarr
        constants.ports.services.prowlarr
      ];

      systemd.services.radarr = storageBound;
      systemd.services.sonarr = storageBound;
      systemd.services.lidarr = storageBound;
      systemd.services.readarr = storageBound;

      systemd.services.bazarr = {
        environment.TZ = mkDefault tz;
        after =
          optional cfg.services.sonarr.enable "sonarr.service"
          ++ optional cfg.services.radarr.enable "radarr.service";
        serviceConfig.UMask = mkForce "0002";
      };

      systemd.services.prowlarr = {
        environment.TZ = mkDefault tz;
        serviceConfig = {
          User = user;
          Group = group;
          UMask = mkForce "0002";
        };
      };
    };
}
