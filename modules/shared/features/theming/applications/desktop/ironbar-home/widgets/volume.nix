{
  ...
}:
{
  type = "volume";
  class = "volume";
  # UX: Icon-only by default, percentage on hover
  format = "{icon}";
  max_volume = 100;
  icons = {
    volume_high = "󰕾";
    volume_medium = "󰖀";
    volume_low = "󰕿";
    muted = "󰝟";
  };
  tooltip = "{percentage}% volume\nClick to mute | Scroll to adjust";
  on_scroll_up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+";
  on_scroll_down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-";
}
