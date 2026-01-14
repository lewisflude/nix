_: {
  type = "volume";
  class = "volume";
  # Clean format: icon + subtle value (no % clutter)
  format = "{icon} {percentage}";
  max_volume = 100;
  icons = {
    volume_high = "󰕾";
    volume_medium = "󰖀";
    volume_low = "󰕿";
    muted = "󰝟";
  };
  tooltip = "Volume: {percentage}%\nClick to mute | Scroll to adjust";
  on_scroll_up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+";
  on_scroll_down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-";
}
