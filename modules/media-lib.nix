{ config, lib, ... }:
let
  inherit (config) constants;
  user = "media";
  group = "media";
  tz = constants.defaults.timezone;
  storageRoot = "/mnt/storage";
  mediaRoot = "${storageRoot}/media";

  media = {
    inherit
      user
      group
      tz
      storageRoot
      mediaRoot
      ;

    serviceDefaults = {
      environment.TZ = lib.mkDefault tz;
      after = [ "mnt-storage.mount" ];
      requires = [ "mnt-storage.mount" ];
      serviceConfig.UMask = lib.mkDefault "0002";
    };

    mkDir = path: "d '${path}' 0770 ${user} ${group} - -";

    mkContainerDir =
      path: uid: gid:
      "d '${path}' 0755 ${toString uid} ${toString gid} - -";

    restartUnits =
      units: names:
      lib.genAttrs names (_: {
        restartUnits = units;
      });
  };
in
{
  options.lib.media = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = media;
    description = "Shared media stack helpers (user/group, paths, systemd defaults, tmpfiles, sops restart).";
  };
}
