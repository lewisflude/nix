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
    users.users.${cfg.user} = {
      isSystemUser = true;
      inherit (cfg) group;
      description = "Media services user";
      # Set home directory to a writable location for services that need it (e.g., qBittorrent)
      home = "/var/lib/${cfg.user}";
      createHome = true;
    };

    users.groups.${cfg.group} = { };

    systemd.tmpfiles.rules = [
      # Create user home directory with proper permissions
      (mkDirRule {
        path = "/var/lib/${cfg.user}";
        mode = "0755";
        inherit (cfg) user;
        inherit (cfg) group;
      })
      (mkDirRule {
        path = cfg.dataPath;
        mode = "0775";
        inherit (cfg) user;
        inherit (cfg) group;
      })
      (mkDirRule {
        path = "${cfg.dataPath}/media";
        mode = "0775";
        inherit (cfg) user;
        inherit (cfg) group;
      })
      (mkDirRule {
        path = "${cfg.dataPath}/media/movies";
        mode = "0775";
        inherit (cfg) user;
        inherit (cfg) group;
      })
      (mkDirRule {
        path = "${cfg.dataPath}/media/tv";
        mode = "0775";
        inherit (cfg) user;
        inherit (cfg) group;
      })
      (mkDirRule {
        path = "${cfg.dataPath}/media/music";
        mode = "0775";
        inherit (cfg) user;
        inherit (cfg) group;
      })
      (mkDirRule {
        path = "${cfg.dataPath}/media/books";
        mode = "0775";
        inherit (cfg) user;
        inherit (cfg) group;
      })
      (mkDirRule {
        path = "${cfg.dataPath}/torrents";
        mode = "0775";
        inherit (cfg) user;
        inherit (cfg) group;
      })
      (mkDirRule {
        path = "${cfg.dataPath}/usenet";
        mode = "0775";
        inherit (cfg) user;
        inherit (cfg) group;
      })
      (mkDirRule {
        path = "${cfg.dataPath}/usenet/complete";
        mode = "0775";
        inherit (cfg) user;
        inherit (cfg) group;
      })
      (mkDirRule {
        path = "${cfg.dataPath}/usenet/incomplete";
        mode = "0775";
        inherit (cfg) user;
        inherit (cfg) group;
      })
    ];
  };
}
