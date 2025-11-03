# Secrets management for container services
# Handles API keys, passwords, and other sensitive data
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.services.containers;
in {
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

    whisparrApiKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Whisparr API key (use sops for production)";
    };

    discordToken = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Discord bot token for Doplarr (use sops for production)";
    };
  };

  config = mkIf cfg.enable {
    # Example sops-nix integration
    # Uncomment and configure when ready to use secrets
    # sops.secrets = mkIf (config.sops.defaultSopsFile != null) {
    #   "containers/sonarr_api_key" = {
    #     owner = "root";
    #     group = "root";
    #     mode = "0400";
    #   };
    #   "containers/radarr_api_key" = {
    #     owner = "root";
    #     group = "root";
    #     mode = "0400";
    #   };
    #   "containers/discord_token" = {
    #     owner = "root";
    #     group = "root";
    #     mode = "0400";
    #   };
    # };
  };
}
