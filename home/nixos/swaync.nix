{pkgs, ...}: {
  # Install swaync package
  home.packages = with pkgs; [
    swaynotificationcenter
  ];

  # SwayNotificationCenter configuration
  services.swaync = {
    enable = true;
    settings = {
      # Position and appearance
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";
      control-center-margin-top = 10;
      control-center-margin-bottom = 0;
      control-center-margin-right = 10;
      control-center-margin-left = 0;

      # Notification settings
      notification-2fa-action = true;
      notification-inline-replies = false;
      notification-icon-size = 64;
      notification-body-image-height = 100;
      notification-body-image-width = 200;
      fit-to-screen = true;

      # Control center
      control-center-width = 500;
      control-center-height = 600;

      # Timeout settings
      timeout = 10;
      timeout-low = 5;
      timeout-critical = 0;

      # Keyboard shortcuts
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      transition-time = 200;

      # Hide on action
      hide-on-clear = false;
      hide-on-action = true;

      # Script for actions
      script-fail-notify = true;

      # Widget configuration
      widgets = [
        "title"
        "dnd"
        "notifications"
      ];

      # Widget settings
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
