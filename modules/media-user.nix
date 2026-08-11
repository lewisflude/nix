# Shared media user/group for arr stack, jellyfin, sabnzbd, qbittorrent, podman containers.
# Centralised with explicit uid/gid so containers (e.g. janitorr) can derive `--user`
# from `config.users.users.media.uid` instead of hardcoded numbers.
# uid/gid match what NixOS already allocated on Jupiter — NixOS preserves existing
# user numbers, so changing these would not renumber the user, it would only mislead
# anything (like janitorr) that reads the config values literally.
{ config, ... }:
let
  inherit (config) username;
  media = config.mediaLib;
in
{
  flake.modules.nixos.mediaUser = _: {
    users.users.${media.user} = {
      isSystemUser = true;
      inherit (media) group;
      description = "Media management user";
      uid = 985;
      # render/video for jellyfin hardware acceleration (formerly declared in jellyfin.nix)
      extraGroups = [
        "render"
        "video"
      ];
    };
    users.groups.${media.group}.gid = 976;

    # Sole declaration of the primary user's media membership. It lets the user
    # read/write files created by the media services (qbittorrent, *arr,
    # filebrowser) which are all owned by <service>:media with UMask 0002.
    users.users.${username}.extraGroups = [ media.group ];
  };
}
