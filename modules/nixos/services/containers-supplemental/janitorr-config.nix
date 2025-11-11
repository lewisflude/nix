{
  lib,
  placeholders,
  janitorrCfg,
}:
let
  inherit (lib) optionalAttrs;
in
{
  server = {
    port = janitorrCfg.port or 8090;
  };

  logging = {
    level = {
      "com.github.schaka" = janitorrCfg.loggingLevel;
    };
  }
  // optionalAttrs (janitorrCfg.loggingFile != null) {
    file = {
      name = janitorrCfg.loggingFile;
    };
  };

  clients = {
    sonarr = {
      url = "http://localhost:8989";
      apiKey = placeholders.sonarr;
      enabled = true;
    };
    radarr = {
      url = "http://localhost:7878";
      apiKey = placeholders.radarr;
      enabled = true;
    };
    bazarr = {
      url = "http://localhost:6767";
      apiKey = placeholders.bazarr;
      enabled = false;
    };
    jellyfin = {
      url = "http://localhost:8096";
      apiKey = placeholders.jellyfinApiKey;
      username = "janitorr";
      password = placeholders.jellyfinPassword;
      enabled = true;
    };
    emby = {
      url = "http://localhost:8096";
      apiKey = placeholders.embyApiKey;
      username = "janitorr";
      password = placeholders.embyPassword;
      enabled = false;
    };
    jellyseerr = {
      url = "http://localhost:5055";
      apiKey = placeholders.jellyseerr;
      enabled = true;
    };
    jellystat = {
      url = "http://localhost:3000";
      apiKey = placeholders.jellystat;
      enabled = true;
    };
    streamystats = {
      url = "http://localhost:8080";
      apiKey = placeholders.streamystats;
      enabled = false;
    };
  };

  application = {
    dry-run = true;
    leaving-soon = "21d";
    leaving-soon-dir = janitorrCfg.leavingSoonDir;
    media-server-leaving-soon-dir = janitorrCfg.mediaServerLeavingSoonDir;
    free-space-check-dir = janitorrCfg.freeSpaceCheckDir;

    media-deletion = {
      enabled = true;
      movie-expiration = {
        "5" = "30d";
        "10" = "60d";
        "15" = "120d";
        "20" = "180d";
      };
      season-expiration = {
        "5" = "30d";
        "10" = "45d";
        "15" = "90d";
        "20" = "180d";
      };
    };

    tag-based-deletion = {
      enabled = false;
      minimum-free-disk-percent = 10;
      schedules = [ ];
    };

    episode-deletion = {
      enabled = false;
    };
  };
}
