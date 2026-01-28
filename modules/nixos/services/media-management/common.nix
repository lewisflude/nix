{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf concatMap;
  cfg = config.host.services.mediaManagement;

  mkDir = path: mode: "d ${path} ${mode} ${cfg.user} ${cfg.group} -";
in
{
  config = mkIf cfg.enable {
    users = {
      users.${cfg.user} = {
        isSystemUser = true;
        inherit (cfg) group;
        description = "Media services user";
        home = "/var/lib/${cfg.user}";
        createHome = true;
      };

      groups.${cfg.group} = { };
    };

    systemd.tmpfiles.rules = [
      (mkDir "/var/lib/${cfg.user}" "0755")
      (mkDir cfg.dataPath "0775")
    ] ++ concatMap (subdir: [ (mkDir "${cfg.dataPath}/${subdir}" "0775") ]) [
      "media"
      "media/movies"
      "media/tv"
      "media/books"
      "torrents"
      "usenet"
      "usenet/complete"
      "usenet/incomplete"
      "usenet/complete/tv"
      "usenet/complete/movies"
      "usenet/complete/music"
      "usenet/complete/books"
      "usenet/complete/audiobooks"
    ];
  };
}
