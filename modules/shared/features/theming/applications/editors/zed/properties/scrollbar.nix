# Scrollbar properties for Zed theme
{
  colors,
  withAlpha,
  ...
}:
{
  "scrollbar.thumb.background" = withAlpha colors."divider-primary" "4c";
  "scrollbar.thumb.hover_background" = colors."surface-subtle".hex + "ff";
  "scrollbar.thumb.border" = colors."surface-subtle".hex + "ff";
  "scrollbar.track.background" = colors."transparent".hex;
  "scrollbar.track.border" = colors."divider-primary".hex + "ff";
}
