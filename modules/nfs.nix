# Jupiter audio sharing for Mercury.
#
# The module attributes keep the historical "nfs" names so existing host imports
# do not need to churn, but the Mercury client now uses SMB. SMB is the primary
# Mac-facing transport; NFS is intentionally not exported for this workflow.
{ config, ... }:
let
  inherit (config) constants username;
  jupiterIp = constants.hosts.jupiter.ipv4;
  musicMount = "/System/Volumes/Data/mnt/music";
in
{
  flake.modules.nixos.nfs = _: { };

  flake.modules.darwin.nfs =
    { config, pkgs, ... }:
    let
      passwordPath = config.sops.secrets."samba/lewisflude-password".path;
      keychainReady = "/var/run/jupiter-smb-keychain.ready";
    in
    {
      launchd.daemons.provision-jupiter-smb-keychain = {
        serviceConfig = {
          Label = "com.lewisflude.provision-jupiter-smb-keychain";
          RunAtLoad = true;
          StandardOutPath = "/var/log/provision-jupiter-smb-keychain.log";
          StandardErrorPath = "/var/log/provision-jupiter-smb-keychain.log";
        };
        script = ''
          set -eu

          log() {
            printf '%s %s\n' "$(${pkgs.coreutils}/bin/date -Is)" "$*"
          }

          ${pkgs.coreutils}/bin/rm -f ${keychainReady}

          if [ ! -f ${passwordPath} ]; then
            log "secret ${passwordPath} not present yet, skipping keychain provision"
            exit 0
          fi

          password=$(${pkgs.coreutils}/bin/tr -d '\r\n' < ${passwordPath})

          /usr/bin/security delete-internet-password \
            -a ${username} -s ${jupiterIp} -r 'smb ' \
            /Library/Keychains/System.keychain >/dev/null 2>&1 || true

          if ! /usr/bin/security add-internet-password \
            -a ${username} -s ${jupiterIp} -r 'smb ' \
            -w "$password" \
            -T /sbin/mount_smbfs -T /usr/bin/security \
            /Library/Keychains/System.keychain; then
            log "failed to add jupiter SMB credentials to System.keychain"
            exit 1
          fi

          ${pkgs.coreutils}/bin/touch ${keychainReady}
          log "provisioned jupiter SMB credentials in System.keychain"
        '';
      };

      launchd.daemons.mount-jupiter-music = {
        serviceConfig = {
          Label = "com.lewisflude.mount-jupiter-music";
          RunAtLoad = true;
          KeepAlive = {
            NetworkState = true;
            SuccessfulExit = false;
          };
          StandardOutPath = "/var/log/mount-jupiter-music.log";
          StandardErrorPath = "/var/log/mount-jupiter-music.log";
        };
        script = ''
          set -eu

          log() {
            printf '%s %s\n' "$(${pkgs.coreutils}/bin/date -Is)" "$*"
          }

          /bin/wait4path ${keychainReady}

          mount_line=$(/sbin/mount | ${pkgs.gnugrep}/bin/grep " on ${musicMount} " || true)
          if [ -n "$mount_line" ]; then
            if printf '%s\n' "$mount_line" | ${pkgs.gnugrep}/bin/grep -q '(smbfs,'; then
              log "${musicMount} is already mounted via SMB"
              exit 0
            fi

            log "${musicMount} is mounted with the wrong filesystem: $mount_line"
            log "unmounting stale mount before SMB remount"
            if ! /sbin/umount -f ${musicMount}; then
              log "failed to unmount stale mount at ${musicMount}"
              exit 1
            fi
          fi

          ${pkgs.coreutils}/bin/mkdir -p ${musicMount}

          log "mounting //${username}@${jupiterIp}/music at ${musicMount}"
          if ! /sbin/mount -t smbfs -o soft,nobrowse "//${username}@${jupiterIp}/music" ${musicMount}; then
            log "failed to mount //${username}@${jupiterIp}/music"
            exit 1
          fi

          if ! /sbin/mount | ${pkgs.gnugrep}/bin/grep " on ${musicMount} " | ${pkgs.gnugrep}/bin/grep -q '(smbfs,'; then
            log "mount command returned success but ${musicMount} is not mounted"
            exit 1
          fi

          log "mounted //${username}@${jupiterIp}/music at ${musicMount}"
        '';
      };
    };

  flake.modules.homeManager.nfs =
    { config, ... }:
    {
      home.file."Music-Jupiter".source = config.lib.file.mkOutOfStoreSymlink musicMount;
      home.file."Samples-Jupiter".source = config.lib.file.mkOutOfStoreSymlink "${musicMount}/samples";
    };
}
