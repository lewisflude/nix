# FileBrowser - Web-based file manager
# Serves storage and music directories via web interface
{ config, ... }:
let
  inherit (config) constants username;
  port = constants.ports.services.filebrowser;
  musicDir = "/home/${username}/Music";
in
{
  flake.modules.nixos.filebrowser = { pkgs, ... }: {
    services.filebrowser = {
      enable = true;
      group = "media";
      settings = {
        address = "127.0.0.1";
        inherit port;
        root = "/mnt/storage";
      };
    };

    users.groups.media = { };

    systemd.tmpfiles.rules = [
      "d /mnt/storage 0770 root media -"
      # Traverse home dir so /mnt/storage/Music symlink resolves
      "a /home/${username} - - - - u:filebrowser:x"
      # Recursive ACL on storage contents (A+ doesn't follow symlinks,
      # so ~/Music is handled separately below)
      "A+ /mnt/storage - - - - g:media:rX"
      # Recursive ACL on the real Music path (symlink target)
      "A+ ${musicDir} - - - - g:media:rX"
    ];

    # Set default ACLs so newly added files inherit media group access.
    # Uses setfacl instead of tmpfiles A+ with d: prefix to work around
    # systemd bug #9545 (d: entries fail on files during recursion).
    systemd.services.filebrowser.serviceConfig.ExecStartPre = "+${pkgs.acl}/bin/setfacl -R -d -m g:media:rX ${musicDir}";

    systemd.services.filebrowser.after = [ "mnt-storage.mount" ];
  };
}
