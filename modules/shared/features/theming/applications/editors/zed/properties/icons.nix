# Icon properties for Zed theme
{
  colors,
  ...
}:
{
  icon = colors."text-primary".hex + "ff";
  "icon.muted" = colors."text-secondary".hex + "ff";
  "icon.disabled" = colors."text-tertiary".hex + "ff";
  "icon.placeholder" = colors."text-secondary".hex + "ff";
  "icon.accent" = colors."accent-primary".hex + "ff";
}
