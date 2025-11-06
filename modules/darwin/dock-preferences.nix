{
  lib,
  config,
  ...
}:
let
  cfg = config.host.features.dockPreferences;
in
{
  options.host.features.dockPreferences = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable enhanced dock preferences";
    };
  };

  config = lib.mkIf cfg.enable {
    system.defaults.dock = {

      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.5;

      wvous-bl-corner = 4;
      wvous-br-corner = 2;
      wvous-tl-corner = 11;
      wvous-tr-corner = 12;

      show-recents = false;
      show-process-indicators = true;
      static-only = false;
      showhidden = true;

      mru-spaces = false;
      expose-group-apps = true;
      expose-animation-duration = 0.5;
      appswitcher-all-displays = false;

      magnification = true;
      largesize = 80;
      tilesize = 48;
      minimize-to-application = false;
      mineffect = "scale";

      launchanim = false;
      enable-spring-load-actions-on-all-items = true;
      mouse-over-hilite-stack = true;
      scroll-to-open = false;

      orientation = "bottom";

      dashboard-in-overlay = false;
    };

    system.defaults.LaunchServices = {
      LSQuarantine = false;
    };
  };
}
