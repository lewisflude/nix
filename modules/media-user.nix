# Shared media user/group for arr stack services, jellyfin, sabnzbd, qbittorrent, podman containers.
# Centralises declaration with explicit uid/gid so containers can derive `--user`.
_: {
  flake.modules.nixos.mediaUser = _: {
    users.users.media = {
      isSystemUser = true;
      group = "media";
      description = "Media management user";
      uid = 994;
      # render/video for jellyfin hardware acceleration
      extraGroups = [
        "render"
        "video"
      ];
    };
    users.groups.media.gid = 994;
  };
}
