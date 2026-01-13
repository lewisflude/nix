_: {
  type = "script";
  class = "brightness";
  mode = "poll";
  # UX: Hide percentage by default - icon sufficient for glanceability
  # Percentage appears on hover via CSS
  format = "󰃠";
  cmd = "brightnessctl -m | awk -F '[(),%]' '{print $6}'";
  interval = 2000;
  on_click_left = "brightnessctl set 5%-";
  on_click_right = "brightnessctl set +5%";
  on_click_middle = "brightnessctl set 50%";
  tooltip = "{}% brightness\n󰍽 -5% | 󰍾 +5% | 󰍿 Reset to 50%";
}
