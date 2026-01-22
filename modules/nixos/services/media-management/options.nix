{
  lib,
  constants,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.host.services.mediaManagement = {
    enable = mkEnableOption "native media management stack";

    user = mkOption {
      type = types.str;
      default = "media";
      description = "User to run media services as.";
    };

    group = mkOption {
      type = types.str;
      default = "media";
      description = "Group to run media services as.";
    };

    dataPath = mkOption {
      type = types.str;
      default = "/mnt/storage";
      description = "Path to the media storage directory.";
    };

    timezone = mkOption {
      type = types.str;
      default = constants.defaults.timezone;
      description = "Timezone for all media services.";
    };
  };
}
