# Jellyfin Service Module - Dendritic Pattern
# Media server with hardware transcoding.
# User/group declared centrally in media-user.nix (with render/video extraGroups).
{ config, ... }:
let
  inherit (config) constants;
  media = config.mediaLib;
in
{
  flake.modules.nixos.jellyfin =
    { pkgs, ... }:
    {
      services.jellyfin = {
        enable = true;
        openFirewall = false;
        inherit (media) user group;
      };

      # Jellyfin 10.11 defaults its EF-Core SQLite layer to NoLock (no write
      # synchronization), which segfaults in native SQLite under concurrent DB
      # access (library monitor + Trakt + playback) — observed as a cluster of
      # SIGSEGV core dumps in sqlite3BtreeIndexMoveto. Force `Optimistic` locking
      # (try-and-retry) per upstream guidance. Idempotent: only rewrites when the
      # value isn't already correct, so it doesn't churn Jellyfin-owned state.
      # See https://jellyfin.org/posts/SQLite-locking/ and jellyfin/jellyfin#14047.
      systemd.services.jellyfin = media.serviceDefaults // {
        preStart = ''
          db="/var/lib/jellyfin/config/database.xml"
          if [ -f "$db" ]; then
            count=$(${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v 'count(/*/LockingBehavior)' "$db" 2>/dev/null || echo 0)
            current=$(${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v '/*/LockingBehavior' "$db" 2>/dev/null || true)
            if [ "$current" != "Optimistic" ]; then
              if [ "$count" -gt 0 ]; then
                ${pkgs.xmlstarlet}/bin/xmlstarlet ed -L -u '/*/LockingBehavior' -v 'Optimistic' "$db"
              else
                ${pkgs.xmlstarlet}/bin/xmlstarlet ed -L -s '/*' -t elem -n 'LockingBehavior' -v 'Optimistic' "$db"
              fi
            fi
          fi
        '';
      };

      # Deliberately not mkDefault: firewall port lists only concat-merge at equal
      # priority, and networking.nix defines allowedTCPPorts at normal priority, so
      # a mkDefault list here is discarded wholesale rather than merged.
      networking.firewall = {
        allowedTCPPorts = [
          constants.ports.services.jellyfin # 8096 - HTTP
          8920 # HTTPS
        ];
        allowedUDPPorts = [
          1900 # DLNA discovery
          7359 # Client discovery
        ];
      };
    };
}
