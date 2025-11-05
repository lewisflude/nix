{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  containersLib = import ../lib.nix { inherit lib; };
  inherit (containersLib) mkResourceOptions mkResourceFlags;

  cfg = config.host.services.containersSupplemental;

  commonEnv = {
    PUID = toString cfg.uid;
    PGID = toString cfg.gid;
    TZ = cfg.timezone;
  };
in
{
  options.host.services.containersSupplemental.doplarr = {
    enable = mkEnableOption "Doplarr Discord bot" // {
      default = false;
    };

    resources = mkResourceOptions {
      memory = "128m";
      cpus = "0.25";
    };

    discordToken = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Discord bot token - REQUIRED for Doplarr.
        Create a bot at https://discord.com/developers/applications
        WARNING: Never commit secrets to git. Use sops-nix for production deployments.
      '';
    };

    sonarrApiKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Sonarr API key - REQUIRED for Doplarr.
        Find in Sonarr: Settings → General → Security → API Key
      '';
    };

    radarrApiKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Radarr API key - REQUIRED for Doplarr.
        Find in Radarr: Settings → General → Security → API Key
      '';
    };
  };

  config = mkIf (cfg.enable && cfg.doplarr.enable) {
    virtualisation.oci-containers.containers.doplarr = {
      image = "ghcr.io/hotio/doplarr:release-3.7.0";
      environment = commonEnv // {
        DISCORD_TOKEN = cfg.doplarr.discordToken;
        SONARR_API_KEY = cfg.doplarr.sonarrApiKey;
        RADARR_API_KEY = cfg.doplarr.radarrApiKey;
        SONARR_URL = "http://localhost:8989";
        RADARR_URL = "http://localhost:7878";
      };
      volumes = [ "${cfg.configPath}/doplarr:/config" ];
      extraOptions = [
        "--network=host"
      ]
      ++ mkResourceFlags cfg.doplarr.resources;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.configPath}/doplarr 0755 ${toString cfg.uid} ${toString cfg.gid} -"
    ];
  };
}
