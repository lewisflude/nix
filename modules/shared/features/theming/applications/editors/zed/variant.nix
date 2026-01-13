# Generate a single Zed theme variant
# Returns a ThemeContent object matching the schema:
# - appearance: "light" | "dark" (required)
# - name: string (required)
# - style: ThemeStyleContent object (required)
{
  themePalette,
  variantName,
  themeLib,
  rawPalette,
  ...
}:
let
  inherit (themePalette) colors;
  mode = if variantName == "Dark" then "dark" else "light";

  # Helper to get categorical color (for players and syntax)
  # Access categorical palette from themeContext using getPalette
  categoricalPalette = themeLib.getPalette mode rawPalette.categorical;
  cat = name: categoricalPalette.${name};

  # Helper to add alpha channel to hex color
  withAlpha = color: alpha: "${color.hex}${alpha}";

  # Import all property categories
  properties = import ./properties/default.nix {
    inherit colors withAlpha cat;
  };
in
{
  # ThemeContent required fields (must match schema exactly)
  # Note: author is NOT in ThemeContent - it's only in ThemeFamilyContent
  appearance = mode; # "light" or "dark"
  name = "Signal ${variantName}";
  inherit (properties) style;
}
