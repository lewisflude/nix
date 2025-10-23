# Sonarr - TV show management
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.services.mediaManagement;
in {
  options.host.services.mediaManagement.sonarr.enable =
    mkEnableOption "Sonarr TV show management"
    // {
      default = true;
    };

  config = mkIf (cfg.enable && cfg.sonarr.enable) {
    services.sonarr = {
      enable = true;
      openFirewall = true;
      inherit (cfg) user;
      inherit (cfg) group;
    };

    # Override the systemd service to use the correct data directory
    systemd.services.sonarr = {
      serviceConfig = {
        ExecStart = lib.mkForce "/nix/store/1k260qq28mzdzm576k33y2kdlxcqbkki-sonarr-4.0.15.2941/bin/Sonarr -nobrowser -data=/var/lib/sonarr";
      };

      # Set timezone
      environment = {
        TZ = cfg.timezone;
      };

      # Soft dependency on prowlarr for startup order
      after = mkAfter (optional cfg.prowlarr.enable "prowlarr.service");
    };
  };
}
