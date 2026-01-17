_: {
  type = "script";
  class = "brightness";
  mode = "poll";
  # Clean, minimal format: icon + subtle value (no % clutter)
  format = "󰃠 {}";
  cmd = "brightnessctl -m | awk -F '[(),%]' '{print $6}'";
  interval = 2000;
  on_click_left = "brightnessctl set 5%-";
  on_click_right = "brightnessctl set +5%";
  on_click_middle = "brightnessctl set 50%";
  tooltip = "Brightness: {}%\nLeft click: -5% | Right click: +5% | Middle: Reset to 50%";
}
