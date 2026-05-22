# Mount jupiter's music share over SMB into the user session on mercury.
#
# Runs in user context (LaunchAgents, not LaunchDaemons) so mount_smbfs can
# read credentials from the user's login.keychain. This is the macOS-native
# pattern that Finder + "Connect to Server" uses.
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

          /usr/bin/security delete-internet-password \
            -a ${username} -s ${jupiterIp} -r 'smb ' \
            >/dev/null 2>&1 || true

          if ! /usr/bin/security add-internet-password \
            -a ${username} -s ${jupiterIp} -r 'smb ' \
            -w "$password" \
            -T /sbin/mount_smbfs -T /usr/bin/security; then
            log "failed to add jupiter SMB credentials to login.keychain"
            exit 1
          fi

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
          if ! /sbin/mount -t smbfs -o soft,nobrowse "//${username}@${jupiterIp}/music" ${mountPoint}; then
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
