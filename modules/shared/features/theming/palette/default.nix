# Signal Theme Palette
# This is the single source of truth for all colors in the Signal theme
# Signal: Perception, engineered.
# Signal is a scientific, dual-theme color system where every color is the calculated
# solution to a functional problem. Built on the principles of perceptual uniformity (Oklch)
# and accessibility (APCA), its purpose is to create a clear, effortless, and predictable
# user experience. It is a framework for engineering clarity.
_:
let
  # Import helpers
  helpers = import ./helpers.nix;
  inherit (helpers) mkColor;

  # Import palette sections
  tonal = import ./tonal.nix { inherit mkColor; };
  accent = import ./accent.nix { inherit mkColor; };
  categorical = import ./categorical.nix { inherit mkColor; };
in
{
  # Tonal Palette - Neutral colors for backgrounds, surfaces, and text
  inherit tonal;

  # Accent Palette - Semantic colors for UI actions and states
  inherit accent;

  # Categorical Palette - For data visualization and syntax highlighting
  inherit categorical;
}
