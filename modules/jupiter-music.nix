# Mount jupiter's music share on mercury with macOS autofs.
{ config, ... }:
let
  inherit (config) constants username;
  jupiterIp = constants.hosts.jupiter.ipv4;
  mountPoint = "/Users/${username}/mnt/jupiter-music";
  mountRoot = "/Users/${username}/mnt";
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
      updateAutoMaster = pkgs.writeText "update-auto-master.py" ''
        import pathlib
        import sys

        source, target, begin, end, entry = sys.argv[1:]
        path = pathlib.Path(source)
        text = path.read_text() if path.exists() else ""
        lines = text.splitlines()

        out = []
        in_block = False
        for line in lines:
            if line == begin:
                in_block = True
                continue
            if in_block and line == end:
                in_block = False
                continue
            if not in_block:
                out.append(line)

        if out and out[-1] != "":
            out.append("")

        if in_block:
            raise SystemExit(f"unterminated managed block in {source}")

        out.extend([begin, entry, end])
        pathlib.Path(target).write_text("\n".join(out) + "\n")
      '';
    in
    {
      system.activationScripts.jupiterMusicAutofs.text = ''
        set -euo pipefail

        password_path=${escapeShellArg passwordPath}
        mount_root=${escapeShellArg mountRoot}
        mount_point=${escapeShellArg mountPoint}
        auto_map=/etc/auto_jupiter_music
        auto_master=/etc/auto_master
        begin_marker="# BEGIN nix-darwin jupiter-music"
        end_marker="# END nix-darwin jupiter-music"

        if [ ! -f "$password_path" ]; then
          echo "jupiter-music-autofs: missing Samba password secret: $password_path" >&2
          exit 1
        fi

        uid="$(/usr/bin/id -u ${escapeShellArg username})"
        for label in \
          com.lewisflude.mount-jupiter-music \
          com.lewisflude.provision-jupiter-smb-keychain
        do
          /bin/launchctl bootout "gui/$uid/$label" 2>/dev/null || true
          /bin/rm -f "/Users/${username}/Library/LaunchAgents/$label.plist"
        done

        mount_line="$(/sbin/mount | ${pkgs.gnugrep}/bin/grep " on $mount_point " || true)"
        if [ -n "$mount_line" ] && printf '%s\n' "$mount_line" | ${pkgs.gnugrep}/bin/grep -q '(smbfs,'; then
          /sbin/umount -f "$mount_point" 2>/dev/null || true
        fi

        /bin/mkdir -p "$mount_root"

        password="$(${pkgs.coreutils}/bin/tr -d '\r\n' < "$password_path")"
        encoded_password="$(${pkgs.python3}/bin/python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$password")"

        tmp_map="$(${pkgs.coreutils}/bin/mktemp)"
        ${pkgs.coreutils}/bin/chmod 0600 "$tmp_map"
        printf '%s\n' \
          "jupiter-music -fstype=smbfs,soft,nobrowse,noowners,nosuid,rw smb://${username}:$encoded_password@${jupiterIp}/music" \
          > "$tmp_map"
        /usr/sbin/chown root:wheel "$tmp_map"
        /usr/bin/install -m 0600 -o root -g wheel "$tmp_map" "$auto_map"
        /bin/rm -f "$tmp_map"

        tmp_master="$(${pkgs.coreutils}/bin/mktemp)"
        ${pkgs.python3}/bin/python3 ${updateAutoMaster} "$auto_master" "$tmp_master" "$begin_marker" "$end_marker" "$mount_root $auto_map"
        /usr/bin/install -m 0644 -o root -g wheel "$tmp_master" "$auto_master"
        /bin/rm -f "$tmp_master"

        /usr/sbin/automount -vc
      '';
    };

  flake.modules.homeManager.jupiter-music =
    { config, ... }:
    {
      home.file."Music-Jupiter".source = config.lib.file.mkOutOfStoreSymlink mountPoint;
      home.file."Samples-Jupiter".source = config.lib.file.mkOutOfStoreSymlink "${mountPoint}/samples";
    };
}
