{
  lib,
  ...
}:
let
  # Import shared palette (single source of truth)
  themeHelpers = import ../../modules/shared/features/theming/helpers.nix { inherit lib; };
  themeImport = themeHelpers.importTheme {
    repoRootPath = ../..;
  };

  # Generate dark mode theme
  theme = themeImport.generateTheme "dark";

  # Extract colors from theme
  colors = theme.colors;
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
