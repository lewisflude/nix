# Unified theme imports for niri configuration
# Note: Colors removed - should come from signal-nix when Niri support is added
{
  lib,
}:
let
  # Ironbar design tokens for Niri synchronization
  # Hardcoded geometric values only (not colors)
  ironbarTokens = {
    niriSync = {
      windowRadius = 12; # Border radius (px)
      windowGap = 12; # Gap between windows, synced with bar.margin (px)
    };
  };

  # Extract niriSync for convenience
  inherit (ironbarTokens) niriSync;
in
{
  inherit ironbarTokens niriSync;

  # Convenience helpers for geometric values only
  cornerRadius = niriSync.windowRadius * 1.0; # Convert to float for Niri config
  windowGap = niriSync.windowGap;

  # Empty placeholders for features that were using colors
  # These will be populated by signal-nix when support is added
  colors = { };
  shadowColor = null;
  inactiveShadowColor = null;
  floatingShadowColor = null;
  screencastColors = null;
  themeConstants = null;
}
