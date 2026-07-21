# Audiobookshelf Service Module - Dendritic Pattern
# Self-hosted audiobook and podcast server. Replaces the audiobook side of the
# retired Readarr. Runs as the shared media user so it can read the book library;
# exposed only via Caddy (openFirewall = false). Point its library at
# /mnt/storage/books and /mnt/storage/media/audiobooks from the web UI on first run.
{ config, ... }:
let
  inherit (config) constants;
  media = config.mediaLib;
in
{
  flake.modules.nixos.audiobookshelf = _: {
    systemd.tmpfiles.rules = [
      (media.mkDir "${media.mediaRoot}/audiobooks")
    ];

    services.audiobookshelf = {
      enable = true;
      inherit (media) user group;
      host = "127.0.0.1";
      port = constants.ports.services.audiobookshelf;
      openFirewall = false;
    };

    systemd.services.audiobookshelf = media.serviceDefaults;
  };
}
