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
      # Per-monitor configuration
      monitors = {
        "DP-3" = {
          position = "top";
          height = 40; # 10x4
          layer = "top";
          exclusive_zone = true;
          popup_gap = 8; # 2x4 # Increased gap for floating feel
          popup_autohide = false;
          start_hidden = false;
          icon_theme = "Papirus"; # Ensure good icons

          # Floating margins
          margin = {
            top = 8; # 2x4
            bottom = 0;
            left = 16; # 4x4
            right = 16; # 4x4
          };

          # Left: Context
          start = [
            {
              type = "workspaces";
              class = "workspaces";
              name_map = {
                "1" = "1";
                "2" = "2";
                "3" = "3";
                "4" = "4";
                "5" = "5";
              };
            }
            {
              type = "focused";
              class = "label";
              truncate = "end";
              length = 40; # Limit length to maintain minimalism
            }
          ];

          # Center: Time
          center = [
            {
              type = "clock";
              class = "clock";
              format = "%H:%M";
              format_popup = "%A, %B %d, %Y";
            }
          ];

          # Right: System Status
          end = [
            {
              type = "sys_info";
              class = "sys-info";
              format = [
                "  {cpu_percent}%"
                "  {memory_percent}%"
              ];
            }
            {
              type = "script";
              class = "brightness";
              mode = "poll";
              format = "󰃠 {}%";
              cmd = "brightnessctl -m | awk -F '[(),%]' '{print $6}'";
              interval = 1000;
              on_click_left = "brightnessctl set 10%-";
              on_click_right = "brightnessctl set +10%";
              tooltip = "Brightness: {}%";
            }
            {
              type = "volume";
              class = "volume";
              format = "{icon} {percentage}%";
              max_volume = 100;
              icons = {
                volume_high = " ";
                volume_medium = " ";
                volume_low = " ";
                muted = "󰝟 ";
              };
            }
            {
              type = "tray";
              class = "tray";
              icon_size = 16; # Match font icon size for consistency
            }
            {
              type = "notifications";
              class = "notifications";
              icon_size = 16; # Match tray icon size for consistency
            }
          ];
        };
      };
    };
  };
}
