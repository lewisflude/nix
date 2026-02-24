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
      user = username;
      group = "media";
      settings = {
        inherit port;
        root = musicDir;
      };
    };

    users.groups.media = { };
    users.users.${username}.extraGroups = [ "media" ];
  };
}
