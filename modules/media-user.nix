# Shared media user/group for arr stack, jellyfin, sabnzbd, qbittorrent, podman containers.
# Centralised with explicit uid/gid so containers (e.g. janitorr) can derive `--user`
# from `config.users.users.media.uid` instead of hardcoded numbers.
# uid/gid match what NixOS already allocated on Jupiter — NixOS preserves existing
# user numbers, so changing these would not renumber the user, it would only mislead
# anything (like janitorr) that reads the config values literally.
_: {
  flake.modules.nixos.mediaUser = _: {
    users.users.media = {
      isSystemUser = true;
      group = "media";
      description = "Media management user";
      uid = 985;
      # render/video for jellyfin hardware acceleration (formerly declared in jellyfin.nix)
      extraGroups = [
        "render"
        "video"
      ];
    };
    users.groups.media.gid = 976;
  };
}
