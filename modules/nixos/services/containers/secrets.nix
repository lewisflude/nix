{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption types mkIf;
  cfg = config.host.services.containers;
in
{
  options.host.services.containers.secrets = {
    sonarrApiKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Sonarr API key (use sops for production)";
    };

    radarrApiKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Radarr API key (use sops for production)";
    };

    lidarrApiKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Lidarr API key (use sops for production)";
    };

    discordToken = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Discord bot token for Doplarr (use sops for production)";
    };
  };

  config = mkIf cfg.enable {

  };
}
