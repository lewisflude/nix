{
  lib,
  config,
  ...
}: let
  cfg = config.host.features.dockPreferences;
in {
  options.host.features.dockPreferences = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable enhanced dock preferences";
    };
  };

  config = lib.mkIf cfg.enable {
    system.defaults.dock = {
      # Auto-hide behavior for more screen space
      autohide = true;
      autohide-delay = 0.0; # No delay before showing
      autohide-time-modifier = 0.5; # Faster animation

      # Hot corners for productivity
      # Values: 1=Disabled, 2=Mission Control, 3=Application Windows, 4=Desktop,
      # 5=Start Screen Saver, 6=Disable Screen Saver, 10=Put Display to Sleep,
      # 11=Launchpad, 12=Notification Center, 13=Lock Screen, 14=Quick Note
      wvous-bl-corner = 4; # Bottom left: Show Desktop
      wvous-br-corner = 2; # Bottom right: Mission Control
      wvous-tl-corner = 11; # Top left: Launchpad
      wvous-tr-corner = 12; # Top right: Notification Center

      # App management
      show-recents = false; # Don't show recently used apps in dock
      show-process-indicators = true; # Show dots for running apps
      static-only = false; # Show both static and running apps
      showhidden = true; # Make hidden app icons translucent

      # Mission Control and Spaces
      mru-spaces = false; # Don't rearrange spaces based on use
      expose-group-apps = true; # Group windows by app in Mission Control
      expose-animation-duration = 0.5; # Faster Mission Control animation
      appswitcher-all-displays = false; # Show app switcher on main display only

      # Visual preferences
      magnification = true; # Magnify icons on hover
      largesize = 80; # Size when magnified (16-128)
      tilesize = 48; # Default icon size
      minimize-to-application = false; # Don't minimize to app icon
      mineffect = "scale"; # Minimize effect: "genie", "suck", or "scale"

      # Animation and behavior
      launchanim = false; # Don't animate opening applications
      enable-spring-load-actions-on-all-items = true; # Spring loading for all items
      mouse-over-hilite-stack = true; # Highlight stack items on hover
      scroll-to-open = false; # Don't use scroll gesture to open stacks

      # Position and layout
      orientation = "bottom"; # Dock position: "bottom", "left", or "right"

      # Dashboard (legacy, but set for completeness)
      dashboard-in-overlay = false; # Don't show Dashboard as overlay
    };

    # LaunchServices preferences
    system.defaults.LaunchServices = {
      LSQuarantine = false; # Disable quarantine for downloaded apps
    };
  };
}
