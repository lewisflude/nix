{
  pkgs,
  ...
}:
{
  programs.ironbar = {
    enable = true;
    systemd = true;
    package = pkgs.ironbar;

    config = {
      # Monitor-specific configuration
      # Using monitors map for per-monitor configuration (use-case 2b from guide)
      monitors = {
        "DP-1" = {
          # Bar-level options
          name = "bar-dp1";
          position = "top";
          height = 42;
          layer = "top";
          exclusive_zone = true;
          popup_gap = 5;
          popup_autohide = false;
          start_hidden = false;

          # Margins
          margin = {
            top = 0;
            bottom = 0;
            left = 0;
            right = 0;
          };

          # Start modules (left/top side)
          start = [
            {
              type = "workspaces";
              class = "workspaces";
              tooltip = "Workspaces";
            }
            {
              type = "window";
              class = "label";
              tooltip = "Active window";
            }
          ];

          # Center modules
          center = [
            {
              type = "clock";
              class = "clock";
              format = "%H:%M:%S";
              tooltip = "{{date +'%A, %B %d, %Y'}}";
            }
          ];

          # End modules (right/bottom side)
          end = [
            {
              type = "sys-info";
              class = "sys-info";
              tooltip = "System information";
              format = "{{cpu}}% {{memory}}% {{temp}}?C";
            }
            {
              type = "brightness";
              class = "brightness";
              tooltip = "Brightness: {{brightness}}%";
              on_click_left = "brightnessctl set 10%-";
              on_click_right = "brightnessctl set +10%";
            }
            {
              type = "volume";
              class = "volume";
              tooltip = "Volume: {{volume}}%";
              on_click_left = "pactl set-sink-volume @DEFAULT_SINK@ -5%";
              on_click_right = "pactl set-sink-volume @DEFAULT_SINK@ +5%";
              on_click_middle = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
            }
            {
              type = "notifications";
              class = "notifications";
              tooltip = "Notifications";
            }
            {
              type = "tray";
              class = "tray";
              icon_size = 16;
              tooltip = "System tray";
            }
          ];
        };
      };
    };
  };
}
