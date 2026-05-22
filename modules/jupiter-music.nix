# Mount jupiter's music share over SMB into the user session on mercury.
#
# Runs in user context (LaunchAgents, not LaunchDaemons) so the mount belongs
# to the logged-in macOS user session.
{ config, ... }:
let
  inherit (config) constants username;
  jupiterIp = constants.hosts.jupiter.ipv4;
  mountPoint = "/Users/${username}/mnt/jupiter-music";
in
{
  flake.modules.darwin.jupiter-music =
    { config, pkgs, ... }:
    let
      passwordPath = config.sops.secrets."samba/lewisflude-password".path;
    in
    {
      launchd.agents.mount-jupiter-music = {
        serviceConfig = {
          Label = "com.lewisflude.mount-jupiter-music";
          RunAtLoad = true;
          KeepAlive = {
            NetworkState = true;
            SuccessfulExit = false;
          };
          ThrottleInterval = 60;
          StandardOutPath = "/Users/${username}/Library/Logs/mount-jupiter-music.log";
          StandardErrorPath = "/Users/${username}/Library/Logs/mount-jupiter-music.log";
        };
        script = ''
          set -eu

          log() {
            printf '%s %s\n' "$(${pkgs.coreutils}/bin/date -Is)" "$*"
          }

          /bin/wait4path ${passwordPath}

          password=$(${pkgs.coreutils}/bin/tr -d '\r\n' < ${passwordPath})
          encoded_password=$(${pkgs.python3}/bin/python3 -c \
            'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' \
            "$password")

          mount_line=$(/sbin/mount | ${pkgs.gnugrep}/bin/grep " on ${mountPoint} " || true)
          if [ -n "$mount_line" ]; then
            if printf '%s\n' "$mount_line" | ${pkgs.gnugrep}/bin/grep -q '(smbfs,'; then
              log "${mountPoint} is already mounted via SMB"
              exit 0
            fi

            log "stale non-SMB mount, unmounting: $mount_line"
            if ! /sbin/umount -f ${mountPoint}; then
              log "failed to unmount stale mount at ${mountPoint}"
              exit 1
            fi
          fi

          ${pkgs.coreutils}/bin/mkdir -p ${mountPoint}

          log "mounting //${username}@${jupiterIp}/music at ${mountPoint}"
          if ! /sbin/mount -t smbfs -o soft,nobrowse "//${username}:$encoded_password@${jupiterIp}/music" ${mountPoint}; then
            log "mount failed"
            exit 1
          fi

          log "mounted //${username}@${jupiterIp}/music at ${mountPoint}"
        '';
      };
    };

  flake.modules.homeManager.jupiter-music =
    { config, ... }:
    {
      home.file."Music-Jupiter".source = config.lib.file.mkOutOfStoreSymlink mountPoint;
      home.file."Samples-Jupiter".source = config.lib.file.mkOutOfStoreSymlink "${mountPoint}/samples";
    };
}
