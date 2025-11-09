{ lib }:
let
  # Helper to import the shared palette and theme library
  # This reduces duplication across modules that need to import the theme
  #
  # Usage:
  #   themeHelpers = import ../../modules/shared/features/theming/helpers.nix { inherit lib; };
  #   themeImport = themeHelpers.importTheme {
  #     repoRootPath = ../..;
  #     nix-colorizer = config._module.args.nix-colorizer or null;
  #   };
  #   theme = themeImport.generateTheme "dark";
  importTheme =
    {
      # Relative path from current file to repo root (e.g., ../../.. for home/common/theming/)
      repoRootPath,
      # Optional: nix-colorizer for advanced color manipulation
      nix-colorizer ? null,
    }:
    let
      # Use builtins.path to get an absolute path, then construct the module paths
      repoRoot = builtins.path {
        path = repoRootPath;
        filter = _: _: true;
      };
      palette = import (repoRoot + "/modules/shared/features/theming/palette.nix") { };
      themeLib = import (repoRoot + "/modules/shared/features/theming/lib.nix") {
        inherit lib palette nix-colorizer;
      };
    in
    {
      inherit palette themeLib;
      # Convenience: generate a theme for a specific mode
      # Valid modes: "light", "dark"
      # Pass empty set {} to disable validation (backward compatible)
      generateTheme = mode: themeLib.generateTheme mode { };
    };
in
{
  inherit importTheme;
}
