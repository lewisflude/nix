{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkAfter;
  inherit (lib.lists) optional;
  cfg = config.host.services.mediaManagement;
in
{
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

    systemd.services.sonarr = {
      environment = {
        TZ = cfg.timezone;
      };

      after = mkAfter (optional cfg.prowlarr.enable "prowlarr.service");
    };

    # Handle legacy NzbDrone path migration (Sonarr was previously called NzbDrone)
    # If /var/lib/sonarr/.config/NzbDrone exists as a file or symlink (but not a directory), remove it so tmpfiles can create it as a directory
    system.activationScripts.sonarrNzbDroneMigration = lib.mkIf (cfg.enable && cfg.sonarr.enable) ''
      if [ -e /var/lib/sonarr/.config/NzbDrone ] && [ ! -d /var/lib/sonarr/.config/NzbDrone ]; then
        echo "Removing legacy NzbDrone file/symlink to allow directory creation..."
        rm -f /var/lib/sonarr/.config/NzbDrone
      fi
    '';
  };
}
