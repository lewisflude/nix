# Mount jupiter's `music` SMB share on mercury via a launchd user agent.
#
# Replaces the previous autofs-based setup: macOS autofs mounts SMB as guest,
# which made the share unbrowsable. The user-agent approach mounts as the
# logged-in user via the Keychain — the Keychain entry is seeded declaratively
# from the sops secret so the workflow stays fully Nix-managed.
{ config, ... }:
let
  inherit (config) constants username;
  jupiterIp = constants.hosts.jupiter.ipv4;
  shareName = "music";
  mountPoint = "/Volumes/${shareName}";
  mountUrl = "smb://${jupiterIp}/${shareName}";
in
{
  flake.modules.darwin.jupiter-music =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) escapeShellArg;
      passwordPath = config.sops.secrets."samba/lewisflude-password".path;

      provisionKeychain = pkgs.writeShellScript "provision-jupiter-smb-keychain" ''
        set -euo pipefail

        password_path=${escapeShellArg passwordPath}
        if [ ! -f "$password_path" ]; then
          echo "provision-jupiter-smb-keychain: missing $password_path" >&2
          exit 1
        fi

        password="$(/usr/bin/tr -d '\r\n' < "$password_path")"

        # -U updates the existing entry if present, otherwise creates one.
        # -r "smb " is the four-character protocol code expected by macOS for
        # SMB Internet password items. NetAuthAgent must be trusted to read
        # the entry non-interactively at mount time.
        /usr/bin/security add-internet-password -U \
          -a ${escapeShellArg username} \
          -s ${escapeShellArg jupiterIp} \
          -P 445 \
          -r "smb " \
          -D "Network Password" \
          -T /System/Library/CoreServices/NetAuthAgent.app \
          -T /usr/bin/security \
          -w "$password" \
          "$HOME/Library/Keychains/login.keychain-db"
      '';

      mountScript = pkgs.writeShellScript "mount-jupiter-music" ''
        set -euo pipefail

        if /sbin/mount | /usr/bin/grep -q " on ${mountPoint} (smbfs"; then
          exit 0
        fi

        # Finder's "mount volume" goes through the same Keychain auth path as
        # `open smb://...`, but without surfacing a Finder window each time.
        /usr/bin/osascript -e 'tell application "Finder" to mount volume "${mountUrl}"' \
          >/dev/null
      '';
    in
    {
      # Tear down the old autofs map + any leftover custom launchd agents from
      # previous iterations of this module.
      system.activationScripts.jupiterMusicCleanupAutofs.text = ''
        set -euo pipefail

        uid="$(/usr/bin/id -u ${escapeShellArg username})"
        for label in \
          com.lewisflude.mount-jupiter-music \
          com.lewisflude.provision-jupiter-smb-keychain
        do
          /bin/launchctl bootout "gui/$uid/$label" 2>/dev/null || true
          /bin/rm -f "/Users/${username}/Library/LaunchAgents/$label.plist"
        done

        # Unmount any existing autofs/SMB mount on the legacy path so the new
        # /Volumes/${shareName} mount can take over cleanly.
        legacy_mount="/Users/${username}/mnt/jupiter-music"
        if /sbin/mount | /usr/bin/grep -q " on $legacy_mount "; then
          /sbin/umount -f "$legacy_mount" 2>/dev/null || true
        fi

        if [ -f /etc/auto_jupiter_music ]; then
          /bin/rm -f /etc/auto_jupiter_music
        fi
        if [ -f /etc/auto_master ] && /usr/bin/grep -q "BEGIN nix-darwin jupiter-music" /etc/auto_master; then
          /usr/bin/sed -i ''' '/# BEGIN nix-darwin jupiter-music/,/# END nix-darwin jupiter-music/d' /etc/auto_master
          /usr/sbin/automount -vc || true
        fi
      '';

      launchd.user.agents.provision-jupiter-smb-keychain = {
        serviceConfig = {
          LowPriorityIO = true;
          ProcessType = "Background";
          ProgramArguments = [ "${provisionKeychain}" ];
          RunAtLoad = true;
          StandardErrorPath = "/tmp/provision-jupiter-smb-keychain.log";
        };
      };

      launchd.user.agents.mount-jupiter-music = {
        serviceConfig = {
          LowPriorityIO = true;
          ProcessType = "Background";
          ProgramArguments = [ "${mountScript}" ];
          RunAtLoad = true;
          # Watchdog: re-mounts after sleep/wake or network changes drop the
          # share. The script is a no-op when the mount is already healthy.
          StartInterval = 60;
          StandardErrorPath = "/tmp/mount-jupiter-music.log";
        };
      };
    };

  flake.modules.homeManager.jupiter-music =
    { config, ... }:
    {
      home.file."Music-Jupiter".source = config.lib.file.mkOutOfStoreSymlink mountPoint;
      home.file."Samples-Jupiter".source = config.lib.file.mkOutOfStoreSymlink "${mountPoint}/samples";
    };
}
