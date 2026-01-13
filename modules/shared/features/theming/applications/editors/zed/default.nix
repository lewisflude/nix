{
  config,
  lib,
  themeContext ? null,
  ...
}:
let
  inherit (lib) mkIf mkOption types;
  cfg = config.theming.signal;

  # Get author name from config if available, otherwise default to "Lewis Flude"
  # Check config.theming.signal.author first, then fall back to default
  authorName = config.theming.signal.author or "Lewis Flude";

  # Safely access themeContext attributes only when available
  themeLib = if themeContext != null then themeContext.lib else null;
  rawPalette = if themeContext != null then themeContext.palette else null;

  # Generate a single theme family in ThemeFamilyContent format
  # This matches the schema from v0.2.0.json exactly:
  # - author: string (required)
  # - name: string (required)
  # - themes: array of ThemeContent objects (required)
  # Each ThemeContent has: appearance, name, style
  themeFamily =
    if themeContext != null then
      let
        # Generate both light and dark palettes
        darkPalette = themeLib.generateTheme "dark" { };
        lightPalette = themeLib.generateTheme "light" { };

        # Generate both theme variants (dark and light)
        darkTheme = import ./variant.nix {
          themePalette = darkPalette;
          variantName = "Dark";
          inherit themeLib rawPalette;
        };
        lightTheme = import ./variant.nix {
          themePalette = lightPalette;
          variantName = "Light";
          inherit themeLib rawPalette;
        };
      in
      {
        # ThemeFamilyContent required fields (must match schema exactly)
        author = authorName;
        name = "Signal";
        # Array containing both dark and light ThemeContent objects
        themes = [
          darkTheme
          lightTheme
        ];
      }
    else
      null;
in
{
  options.theming.signal.applications.zed.themes = mkOption {
    type = types.nullOr (
      types.submodule {
        options = {
          author = mkOption {
            type = types.str;
            description = "Theme author name";
          };
          name = mkOption {
            type = types.str;
            description = "Theme family name";
          };
          themes = mkOption {
            type = types.listOf types.attrs;
            description = "Array of theme objects";
          };
        };
      }
    );
    default = null;
    description = "Zed editor theme family in ThemeFamilyContent format";
    internal = true; # Mark as internal since it's generated, not user-configured
  };

  config = mkIf (cfg.enable && cfg.applications.zed.enable && themeContext != null) {
    # Export theme family for use in home-manager
    theming.signal.applications.zed.themes = themeFamily;
  };
}
