{
  themeLib,
  ...
}:
let
  # Generate dark mode theme using shared themeLib
  theme = themeLib.generateTheme "dark" { };

  # Extract colors from theme
  inherit (theme) colors;
in
{
  niri.colors = {
    focus-ring = {
      active = colors."accent-focus".hex;
      inactive = colors."text-tertiary".hex;
    };
    border = {
      active = colors."accent-special".hex;
      inactive = colors."divider-secondary".hex;
      urgent = colors."accent-danger".hex;
    };
    shadow = "${colors."surface-base".hex}aa";
    tab-indicator = {
      active = colors."accent-special".hex;
      inactive = colors."text-tertiary".hex;
    };
  };
}
