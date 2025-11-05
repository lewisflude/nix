{ pkgs, ... }:
{
  home.packages = with pkgs; [
    swaynotificationcenter
  ];
  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";
      control-center-margin-top = 10;
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
