{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  mediaLib = import ./lib.nix { inherit lib; };
  inherit (mediaLib) mkDirRule;
  cfg = config.host.services.mediaManagement;
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

    # Use native systemd.tmpfiles.rules format (standard NixOS pattern)
    # Format: "d <path> <mode> <user> <group> -"
    systemd.tmpfiles.rules =
      let
        mediaDirs = [
          {
            path = "/var/lib/${cfg.user}";
            mode = "0755";
          }
          {
            path = cfg.dataPath;
            mode = "0775";
          }
          {
            path = "${cfg.dataPath}/media";
            mode = "0775";
          }
          {
            path = "${cfg.dataPath}/media/movies";
            mode = "0775";
          }
          {
            path = "${cfg.dataPath}/media/tv";
            mode = "0775";
          }
          # Note: ${cfg.dataPath}/media/music is handled by navidrome service tmpfiles
          {
            path = "${cfg.dataPath}/media/books";
            mode = "0775";
          }
          {
            path = "${cfg.dataPath}/torrents";
            mode = "0775";
          }
          {
            path = "${cfg.dataPath}/usenet";
            mode = "0775";
          }
          {
            path = "${cfg.dataPath}/usenet/complete";
            mode = "0775";
          }
          {
            path = "${cfg.dataPath}/usenet/incomplete";
            mode = "0775";
          }
          # SABnzbd category subdirectories (matches qBittorrent pattern)
          {
            path = "${cfg.dataPath}/usenet/complete/tv";
            mode = "0775";
          }
          {
            path = "${cfg.dataPath}/usenet/complete/movies";
            mode = "0775";
          }
          {
            path = "${cfg.dataPath}/usenet/complete/music";
            mode = "0775";
          }
          {
            path = "${cfg.dataPath}/usenet/complete/books";
            mode = "0775";
          }
          {
            path = "${cfg.dataPath}/usenet/complete/audiobooks";
            mode = "0775";
          }
        ];
        mediaTmpfiles = map (dir: mkDirRule (dir // { inherit (cfg) user group; })) mediaDirs;
      in
      mediaTmpfiles;
  };
}
