# FileBrowser - Web-based file manager
# Serves storage and music directories via web interface
{ config, ... }:
let
  inherit (config) constants username;
  port = constants.ports.services.filebrowser;
  musicDir = "/home/${username}/Music";
in
{
  flake.modules.nixos.filebrowser = {
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
      "d /mnt/storage/Music 0770 root media -"
      "A+ /mnt/storage - - - - g:media:rX"
    ];

    systemd.services.filebrowser = {
      after = [ "mnt-storage.mount" ];
      serviceConfig.BindPaths = [ "${musicDir}:/mnt/storage/Music" ];
    };
  };
}
