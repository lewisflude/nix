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
      dataDir = "/var/lib/sonarr";
    };

    # Override ExecStart to add -nobrowser flag and ensure correct data directory
    systemd.services.sonarr = {
      serviceConfig = {
        ExecStart = lib.mkForce "${config.services.sonarr.package}/bin/Sonarr -nobrowser -data=${config.services.sonarr.dataDir}";
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
