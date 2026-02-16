# SABnzbd Service Module - Dendritic Pattern
# Usenet downloader for automated media retrieval
# Usage: Import flake.modules.nixos.sabnzbd in host definition
{ config, ... }:
let
  inherit (config) constants;
in
{
  # ==========================================================================
  # NixOS System Configuration
  # ==========================================================================
  flake.modules.nixos.sabnzbd =
    { lib, ... }:
    let
      inherit (lib) mkDefault;

      # Default configuration (can be overridden by hosts)
      user = "media";
      group = "media";
      port = constants.ports.services.sabnzbd;
      downloadDir = "/var/lib/sabnzbd/incomplete";
      completeDir = "/mnt/storage/usenet";
    in
    {
      # Ensure media user/group exist
      users.users.${user} = mkDefault {
        isSystemUser = true;
        inherit group;
        description = "Media management user";
      };
      users.groups.${group} = mkDefault { };

      # Ensure required directories exist (0770 so media group members can write)
      systemd.tmpfiles.rules = [
        "d '${downloadDir}' 0770 ${user} ${group} - -"
        "d '${completeDir}' 0770 ${user} ${group} - -"
        "d '/var/lib/sabnzbd/nzb_backup' 0770 ${user} ${group} - -"
        # Category subdirectories (TRASHguides)
        "d '${completeDir}/movies' 0770 ${user} ${group} - -"
        "d '${completeDir}/tv' 0770 ${user} ${group} - -"
        "d '${completeDir}/music' 0770 ${user} ${group} - -"
      ];

      services.sabnzbd = {
        enable = true;
        inherit user group;
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

      # I/O and CPU nice priorities to prevent starving compositor
      systemd.services.sabnzbd = {
        after = [ "mnt-storage.mount" ];
        requires = [ "mnt-storage.mount" ];
        serviceConfig = {
          # Match qBittorrent's UMask so files are group-writable (0664/0775)
          # Without this, SABnzbd uses default 0022 → files are 0644 → Sonarr/Radarr can't write
          UMask = "0002";
          # Nice priority: 19 = lowest CPU priority (background process)
          Nice = 19;
          # I/O priority: best-effort class 7 = lowest I/O priority
          IOSchedulingClass = "best-effort";
          IOSchedulingPriority = 7;
        };
      };

      networking.firewall.allowedTCPPorts = mkDefault [
        port
      ];
    };
}
