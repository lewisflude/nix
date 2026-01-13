# Border properties for Zed theme
{
  colors,
  withAlpha,
  ...
}:
{
  border = colors."divider-primary".hex + "ff";
  "border.variant" = colors."divider-secondary".hex + "ff";
  "border.focused" = colors."accent-focus".hex + "ff";
  "border.selected" = colors."accent-primary".hex + "ff";
  "border.transparent" = colors."transparent".hex;
  "border.disabled" = withAlpha colors."divider-primary" "80";
}
