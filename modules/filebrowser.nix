# FileBrowser - Web-based file manager
# Serves music directory via web interface
{ config, ... }:
let
  inherit (config) constants username;
  media = config.mediaLib;
  port = constants.ports.services.filebrowser;
  musicDir = "/home/${username}/Music";
in
{
  # The media group and the primary user's membership of it are declared once,
  # in media-user.nix.
  flake.modules.nixos.filebrowser = _: {
    services.filebrowser = {
      enable = true;
      user = username;
      inherit (media) group;
      settings = {
        inherit port;
        root = musicDir;
      };
    };
  };
}
