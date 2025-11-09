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

  # Extract colors from semantic mappings
  semantic = theme.semantic;
in
{
  niri.colors = {
    focus-ring = {
      active = lib.mkDefault semantic."accent-focus".hex;
      inactive = lib.mkDefault semantic."text-tertiary".hex;
    };
    border = {
      active = lib.mkDefault semantic."accent-special".hex;
      inactive = lib.mkDefault semantic."divider-secondary".hex;
      urgent = lib.mkDefault semantic."accent-danger".hex;
    };
    shadow = lib.mkDefault "${semantic."surface-base".hex}aa";
    tab-indicator = {
      active = lib.mkDefault semantic."accent-special".hex;
      inactive = lib.mkDefault semantic."text-tertiary".hex;
    };
  };
}
