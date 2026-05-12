# SABnzbd Service Module - Dendritic Pattern
# Usenet downloader for automated media retrieval.
# User/group declared centrally in media-user.nix.
{ config, ... }:
let
  inherit (config) constants;
  media = config.mediaLib;
in
{
  flake.modules.nixos.sabnzbd =
    { lib, ... }:
    let
      inherit (lib) mkDefault;
      port = constants.ports.services.sabnzbd;
      downloadDir = "/var/lib/sabnzbd/incomplete";
      completeDir = "/mnt/storage/usenet";
    in
    {
      # Ensure required directories exist (0770 so media group members can write)
      systemd.tmpfiles.rules = [
        (media.mkDir downloadDir)
        (media.mkDir completeDir)
        (media.mkDir "/var/lib/sabnzbd/nzb_backup")
        # Category subdirectories (TRASHguides)
        (media.mkDir "${completeDir}/movies")
        (media.mkDir "${completeDir}/tv")
        (media.mkDir "${completeDir}/music")
      ];

      services.sabnzbd = {
        enable = true;
        inherit (media) user group;
        configFile = null; # use settings instead (default is non-null for stateVersion < 26.05)
        settings = {
          misc = {
            inherit port;
            host_whitelist = mkDefault "usenet.blmt.io";

            # Download paths: NVMe for incomplete (fast I/O), HDD for complete (capacity)
            download_dir = downloadDir;
            complete_dir = completeDir;

            # .nzb backup for dupe detection and retries (TRASHguides)
            nzb_backup_dir = "/var/lib/sabnzbd/nzb_backup";

            # Queue (TRASHguides)
            propagation_delay = 5; # Minutes to wait for post propagation
            fail_hopeless_jobs = true; # Abort uncomplectable downloads
            direct_unpack = true; # Unpack during download to speed up post-processing

            # Duplicate handling: 0=off, 1=tag, 2=pause, 3=fail (TRASHguides: tag)
            no_dupes = 1;

            # Post-processing (TRASHguides)
            sfv_check = true;
            safe_postproc = true; # Only process verified jobs
            enable_recursive = true; # Unpack nested archives (rar-in-rar)
            flat_unpack = false; # Keep subfolders (for subtitles)
            ignore_samples = false; # Let Starr apps handle sample detection
            deobfuscate_final_filenames = true; # Fix obfuscated filenames
            enable_all_par = false; # Don't download all par2 files

            # Sorting — disable all, let Sonarr/Radarr handle it (TRASHguides)
            enable_tv_sorting = false;
            enable_movie_sorting = false;
            enable_date_sorting = false;
          };

          # Categories for Starr apps (TRASHguides)
          # dir paths are relative to complete_dir (/mnt/storage/usenet)
          categories = {
            "*" = {
              name = "*";
              dir = "";
            };
            radarr = {
              name = "radarr";
              dir = "movies";
            };
            sonarr = {
              name = "sonarr";
              dir = "tv";
            };
            lidarr = {
              name = "lidarr";
              dir = "music";
            };
          };
        };
      };

      # serviceDefaults supplies TZ/after/requires/UMask; nice priorities are sabnzbd-specific.
      systemd.services.sabnzbd = lib.recursiveUpdate media.serviceDefaults {
        serviceConfig = {
          # Nice priority: 19 = lowest CPU priority (background process)
          Nice = 19;
          # I/O priority: best-effort class 7 = lowest I/O priority
          IOSchedulingClass = "best-effort";
          IOSchedulingPriority = 7;
        };
      };

      networking.firewall.allowedTCPPorts = mkDefault [ port ];
    };
}
