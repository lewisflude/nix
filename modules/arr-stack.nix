# *arr media management stack: prowlarr (indexer), radarr/sonarr/lidarr
# (downloaders), bazarr (subtitles). Co-located in one module — they share
# user/group, storage mount dependency, and systemd boilerplate.
# Readarr was retired (archived upstream); books are handled by Calibre-Web-Automated
# (ebooks) and Audiobookshelf (audiobooks) instead.
{ config, ... }:
let
  inherit (config) constants;
  media = config.mediaLib;
in
{
  flake.modules.nixos.arrStack =
    nixosArgs:
    let
      inherit (nixosArgs) lib;
      cfg = nixosArgs.config;
      inherit (lib)
        mkForce
        optional
        recursiveUpdate
        ;
      # serviceDefaults provides TZ/after/requires/UMask (the latter as mkDefault).
      # radarr and sonarr are the only servarr modules that pin UMask themselves
      # ("0022", normal priority, in their upstream hardening block) and neither
      # exposes an option for it, so mkForce is the only way past them. bazarr and
      # prowlarr set no UMask at all and inherit the default untouched.
      storageBound = recursiveUpdate media.serviceDefaults {
        after = optional cfg.services.prowlarr.enable "prowlarr.service";
        serviceConfig.UMask = mkForce "0002";
      };
    in
    {
      systemd.tmpfiles.rules = [
        (media.mkDir media.mediaRoot)
        (media.mkDir "${media.mediaRoot}/movies")
        (media.mkDir "${media.mediaRoot}/tv")
        (media.mkDir "${media.mediaRoot}/music")
        (media.mkDir "${media.storageRoot}/books")
      ];

      services.radarr = {
        enable = true;
        inherit (media) user group;
      };
      services.sonarr = {
        enable = true;
        inherit (media) user group;
        dataDir = "/var/lib/sonarr/.config/Sonarr";
      };
      services.lidarr = {
        enable = true;
        inherit (media) user group;
      };
      services.bazarr = {
        enable = true;
        inherit (media) user group;
        listenPort = constants.ports.services.bazarr;
      };
      services.prowlarr.enable = true;

      # Not mkDefault: see the note in jellyfin.nix — mkDefault port lists lose to
      # networking.nix's normal-priority definition instead of merging with it.
      networking.firewall.allowedTCPPorts = [
        constants.ports.services.radarr
        constants.ports.services.sonarr
        constants.ports.services.lidarr
        constants.ports.services.bazarr
        constants.ports.services.prowlarr
      ];

      systemd.services.radarr = storageBound;
      systemd.services.sonarr = storageBound;
      systemd.services.lidarr = storageBound;

      systemd.services.bazarr = recursiveUpdate media.serviceDefaults {
        after =
          optional cfg.services.sonarr.enable "sonarr.service"
          ++ optional cfg.services.radarr.enable "radarr.service";
      };

      systemd.services.prowlarr = recursiveUpdate media.serviceDefaults {
        serviceConfig = {
          User = media.user;
          Group = media.group;
        };
      };
    };
}
