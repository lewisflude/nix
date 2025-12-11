_: {
  # Note: swaynotificationcenter is automatically installed by services.swaync.enable
  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";
      cssPriority = "user"; # Ensure our CSS overrides GTK theme backgrounds
      # Position below ironbar: bar height (42px) + gap (10px) = 52px
      control-center-margin-top = 52;
      control-center-margin-bottom = 0;
      control-center-margin-right = 10;
      control-center-margin-left = 0;
      notification-2fa-action = true;
      notification-inline-replies = false;
      notification-icon-size = 64;
      notification-body-image-height = 100;
      notification-body-image-width = 200;
      fit-to-screen = true;
      control-center-width = 500;
      control-center-height = 600;
      timeout = 10;
      timeout-low = 5;
      timeout-critical = 0;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      transition-time = 200;
      hide-on-clear = false;
      hide-on-action = true;
      script-fail-notify = true;
      widgets = [
        "title"
        "dnd"
        "notifications"
      ];
      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear All";
        };
        dnd = {
          text = "Do Not Disturb";
        };
        notifications = {
          clear-all-button = true;
        };
      };
    };
  };
}
