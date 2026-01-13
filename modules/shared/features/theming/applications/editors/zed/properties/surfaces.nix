# Surface properties for Zed theme
{
  colors,
  withAlpha,
  ...
}:
{
  "elevated_surface.background" = colors."surface-emphasis".hex + "ff";
  "surface.background" = colors."surface-base".hex + "ff";
  background = colors."surface-subtle".hex + "ff";
  "background.appearance" = null; # Optional: "opaque", "transparent", or "blurred"
  "element.background" = colors."surface-base".hex + "ff";
  "element.hover" = colors."surface-subtle".hex + "ff";
  "element.active" = colors."surface-emphasis".hex + "ff";
  "element.selected" = colors."surface-emphasis".hex + "ff";
  "element.disabled" = withAlpha colors."surface-base" "80";
  "drop_target.background" = withAlpha colors."accent-focus" "80";

  # Ghost element properties
  "ghost_element.background" = colors."transparent".hex;
  "ghost_element.hover" = colors."surface-subtle".hex + "ff";
  "ghost_element.active" = colors."surface-emphasis".hex + "ff";
  "ghost_element.selected" = colors."surface-emphasis".hex + "ff";
  "ghost_element.disabled" = withAlpha colors."surface-base" "80";
}
