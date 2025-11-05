# Janitorr base configuration
# Extracted to separate file for lazy loading to improve evaluation performance
{
  lib,
  placeholders,
  janitorrCfg,
  ...
}: {
  logging =
    {
      level = {
        "com.github.schaka" = janitorrCfg.loggingLevel;
      };
    }
    // lib.optionalAttrs (janitorrCfg.loggingFile != null) {
      file = {
        name = janitorrCfg.loggingFile;
      };
    };

  "file-system" = {
    access = true;
    "validate-seeding" = true;
    "leaving-soon-dir" = janitorrCfg.leavingSoonDir;
    "media-server-leaving-soon-dir" = janitorrCfg.mediaServerLeavingSoonDir;
    "from-scratch" = true;
    "free-space-check-dir" = janitorrCfg.freeSpaceCheckDir;
  };

  application = {
    "dry-run" = true;
    "run-once" = false;
    "whole-tv-show" = false;
    "whole-show-seeding-check" = false;
    "leaving-soon" = "14d";
    "exclusion-tags" = [
      "janitorr_keep"
      "janitorr_keep_too"
    ];
    "media-deletion" = {
      enabled = true;
      "movie-expiration" = {
        "5" = "15d";
        "10" = "30d";
        "15" = "60d";
        "20" = "90d";
      };
      "season-expiration" = {
        "5" = "15d";
        "10" = "20d";
        "15" = "60d";
        "20" = "120d";
      };
    };
    "tag-based-deletion" = {
      enabled = true;
      "minimum-free-disk-percent" = 100;
      schedules = [
        {
          tag = "5 - demo";
          expiration = "30d";
        }
        {
          tag = "10 - demo";
          expiration = "7d";
        }
      ];
    };
    "episode-deletion" = {
      enabled = true;
      tag = "janitorr_daily";
      "max-episodes" = 10;
      "max-age" = "30d";
    };
  };

  clients = {
    sonarr = {
      enabled = true;
      url = "http://localhost:8989";
      "api-key" = placeholders.sonarr;
      "delete-empty-shows" = true;
      "determine-age-by" = "MOST_RECENT";
      "import-exclusions" = false;
    };
    radarr = {
      enabled = true;
      url = "http://localhost:7878";
      "api-key" = placeholders.radarr;
      "only-delete-files" = false;
      "determine-age-by" = "most_recent";
      "import-exclusions" = false;
    };
    bazarr = {
      enabled = false;
      url = "http://localhost:6767";
      "api-key" = placeholders.bazarr;
    };
    jellyfin = {
      enabled = true;
      url = "http://localhost:8096";
      "api-key" = placeholders.jellyfinApiKey;
      username = "janitorr";
      password = placeholders.jellyfinPassword;
      delete = true;
      "leaving-soon-tv" = "Shows (Leaving Soon)";
      "leaving-soon-movies" = "Movies (Leaving Soon)";
      "leaving-soon-type" = "MOVIES_AND_TV";
    };
    emby = {
      enabled = false;
      url = "http://localhost:8096";
      "api-key" = placeholders.embyApiKey;
      username = "Janitorr";
      password = placeholders.embyPassword;
      delete = true;
      "leaving-soon-tv" = "Shows (Leaving Soon)";
      "leaving-soon-movies" = "Movies (Leaving Soon)";
      "leaving-soon-type" = "MOVIES_AND_TV";
    };
    jellyseerr = {
      enabled = true;
      url = "http://localhost:5055";
      "api-key" = placeholders.jellyseerr;
      "match-server" = false;
    };
    jellystat = {
      enabled = false;
      "whole-tv-show" = false;
      url = "http://jellystat:3000";
      "api-key" = placeholders.jellystat;
    };
    streamystats = {
      enabled = false;
      "whole-tv-show" = false;
      url = "http://streamystats:3000";
      "api-key" = placeholders.streamystats;
    };
  };
}
