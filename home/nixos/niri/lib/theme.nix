# Unified theme imports for niri configuration
# Consolidates theme constants and Ironbar token imports
{ lib, themeLib }:
let
  themeConstants = import ../../theme-constants.nix {
    inherit lib themeLib;
  };

  # Import Ironbar design tokens for Niri synchronization
  # This ensures Niri windows use the same gaps and radii as Ironbar islands
  ironbarTokens =
    import ../../../../modules/shared/features/theming/applications/desktop/ironbar-home/tokens.nix
      { };

  # Generate theme to access raw colors
  theme = themeLib.generateTheme "dark" { };

  # Extract niriSync from Ironbar tokens
  inherit (ironbarTokens) niriSync;
in
{
  inherit themeConstants ironbarTokens theme;
  inherit (theme) colors;
  inherit niriSync;

  # Convenience helpers for common theme values
  cornerRadius = niriSync.windowRadius * 1.0; # Convert to float for Niri config
  windowGap = niriSync.windowGap;

  # Shadow colors with different opacity levels
  shadowColor = lib.mkDefault "${theme.colors."surface-base".hex}aa"; # 66% opacity
  inactiveShadowColor = "${theme.colors."surface-base".hex}66"; # 40% opacity

  # Floating window shadow color
  floatingShadowColor = "${theme.colors."surface-base".hex}aa";

  # Screencast indicator colors
  screencastColors = {
    active = theme.colors."accent-danger".hex;
    inactive = theme._internal.accent.Lc45-h040.hex; # Darker variant of danger
    shadow = theme.withAlpha theme._internal.accent.Lc45-h040 0.44; # ~70/255 opacity
  };
}
