# Shared media user/group for arr stack services
# Centralises the user declaration used by sonarr, radarr, lidarr, bazarr, readarr, prowlarr
_: {
  flake.modules.nixos.mediaUser = _: {
    users.users.media = {
      isSystemUser = true;
      group = "media";
      description = "Media management user";
    };
    users.groups.media = { };
  };
}
