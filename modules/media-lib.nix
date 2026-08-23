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
      # Order after DNS/network is up as well as the storage mount. Prowlarr in
      # particular hits its metadata endpoints (indexers.prowlarr.com,
      # prowlarr.servarr.com) on startup and threw "Name or service not known" at
      # boot when it raced ahead of network-online. `wants` pulls the target into
      # the boot; radarr/sonarr/bazarr inherit the ordering transitively via their
      # own after=[prowlarr/sonarr/radarr] chains even though they override `after`.
      after = [
        "mnt-storage.mount"
        "network-online.target"
      ];
      wants = [ "network-online.target" ];
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
  options.mediaLib = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    # Repo plumbing; see NIX_PRACTICES.md section 3.5.
    internal = true;
    visible = false;
    default = media;
    description = "Shared media stack helpers (user/group, paths, systemd defaults, tmpfiles, sops restart).";
  };
}
