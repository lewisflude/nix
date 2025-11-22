{
  lib,
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
      active = lib.mkDefault colors."accent-focus".hex;
      inactive = lib.mkDefault colors."text-tertiary".hex;
    };
    border = {
      active = lib.mkDefault colors."accent-special".hex;
      inactive = lib.mkDefault colors."divider-secondary".hex;
      urgent = lib.mkDefault colors."accent-danger".hex;
    };
    shadow = lib.mkDefault "${colors."surface-base".hex}aa";
    tab-indicator = {
      active = lib.mkDefault colors."accent-special".hex;
      inactive = lib.mkDefault colors."text-tertiary".hex;
    };
  };
}
