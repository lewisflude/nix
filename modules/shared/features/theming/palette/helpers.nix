# Helper functions for color manipulation and conversion
# These functions are used to create color definitions with OKLCH, hex, and RGB

rec {
  # Helper to convert a single hex digit (0-9, a-f, A-F) to integer (0-15)
  hexDigitToInt =
    c:
    if c == "0" then
      0
    else if c == "1" then
      1
    else if c == "2" then
      2
    else if c == "3" then
      3
    else if c == "4" then
      4
    else if c == "5" then
      5
    else if c == "6" then
      6
    else if c == "7" then
      7
    else if c == "8" then
      8
    else if c == "9" then
      9
    else if c == "a" || c == "A" then
      10
    else if c == "b" || c == "B" then
      11
    else if c == "c" || c == "C" then
      12
    else if c == "d" || c == "D" then
      13
    else if c == "e" || c == "E" then
      14
    else if c == "f" || c == "F" then
      15
    else
      throw "Invalid hex digit: ${c}";

  # Helper to convert a hex pair (e.g., "a3") to integer (0-255)
  hexPairToInt =
    pair:
    (hexDigitToInt (builtins.substring 0 1 pair)) * 16 + (hexDigitToInt (builtins.substring 1 1 pair));

  # Helper to create color definitions with OKLCH, hex, and RGB
  # This is the single source of truth for all colors in the Signal theme
  # Signal: Perception, engineered.
  # Signal is a scientific, dual-theme color system where every color is the calculated
  # solution to a functional problem. Built on the principles of perceptual uniformity (Oklch)
  # and accessibility (APCA), its purpose is to create a clear, effortless, and predictable
  # user experience. It is a framework for engineering clarity.
  # Each color includes: l (lightness 0.0-1.0), c (chroma 0.0+), h (hue 0-360 degrees),
  # hex (with and without #), and rgb (0-255 integers)
  mkColor =
    {
      l,
      c,
      h,
      hex, # hex without # prefix (raw format: RRGGBB)
    }:
    {
      inherit
        l
        c
        h
        ;
      # Store raw hex without # prefix (for internal use)
      hexRaw = hex;
      # Store hex with # prefix (for CSS/configs that need it)
      hex = "#${hex}";
      # Parse hex to RGB (format: RRGGBB)
      rgb = {
        r = hexPairToInt (builtins.substring 0 2 hex);
        g = hexPairToInt (builtins.substring 2 2 hex);
        b = hexPairToInt (builtins.substring 4 2 hex);
      };
    };
}
