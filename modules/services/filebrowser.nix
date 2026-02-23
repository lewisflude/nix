# FileBrowser - Web-based file manager
# Serves music directory via web interface
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
        root = musicDir;
      };
    };

    users.groups.media = { };

    systemd.services.filebrowser.serviceConfig.ReadWritePaths = [ musicDir ];
  };
}
