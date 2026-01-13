# Text properties for Zed theme
{
  colors,
  ...
}:
{
  text = colors."text-primary".hex + "ff";
  "text.muted" = colors."text-secondary".hex + "ff";
  "text.placeholder" = colors."text-tertiary".hex + "ff";
  "text.disabled" = colors."text-tertiary".hex + "ff";
  "text.accent" = colors."accent-primary".hex + "ff";
}
