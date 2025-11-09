{ ... }:
let
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
in
{
  # Tonal Palette - Neutral colors for backgrounds, surfaces, and text
  tonal = {
    light = {
      # Base colors (lightest to darkest for light mode)
      base-L100 = mkColor {
        l = 1.0;
        c = 0.0;
        h = 0.0;
        hex = "ffffff";
      };
      base-L095 = mkColor {
        l = 0.95;
        c = 0.01;
        h = 240.0;
        hex = "f2f3f7";
      };

      # Surface colors
      surface-Lc05 = mkColor {
        l = 0.91;
        c = 0.01;
        h = 240.0;
        hex = "e7e8ed";
      };
      surface-Lc10 = mkColor {
        l = 0.87;
        c = 0.02;
        h = 240.0;
        hex = "dcdee6";
      };

      # Divider colors
      divider-Lc15 = mkColor {
        l = 0.83;
        c = 0.02;
        h = 240.0;
        hex = "d1d3dd";
      };
      divider-Lc30 = mkColor {
        l = 0.75;
        c = 0.03;
        h = 240.0;
        hex = "b9bcc9";
      };

      # Text colors
      text-Lc45 = mkColor {
        l = 0.60;
        c = 0.04;
        h = 240.0;
        hex = "8b8fa1";
      };
      text-Lc60 = mkColor {
        l = 0.45;
        c = 0.05;
        h = 240.0;
        hex = "5f6378";
      };
      text-Lc75 = mkColor {
        l = 0.30;
        c = 0.05;
        h = 240.0;
        hex = "373b4e";
      };
    };

    dark = {
      # Base colors (darkest to lightest for dark mode)
      base-L000 = mkColor {
        l = 0.0;
        c = 0.0;
        h = 0.0;
        hex = "000000";
      };
      base-L015 = mkColor {
        l = 0.15;
        c = 0.01;
        h = 240.0;
        hex = "1e1f26";
      };

      # Surface colors
      surface-Lc05 = mkColor {
        l = 0.19;
        c = 0.01;
        h = 240.0;
        hex = "25262f";
      };
      surface-Lc10 = mkColor {
        l = 0.23;
        c = 0.02;
        h = 240.0;
        hex = "2d2e39";
      };

      # Divider colors
      divider-Lc15 = mkColor {
        l = 0.27;
        c = 0.02;
        h = 240.0;
        hex = "353642";
      };
      divider-Lc30 = mkColor {
        l = 0.35;
        c = 0.03;
        h = 240.0;
        hex = "454759";
      };

      # Text colors
      text-Lc45 = mkColor {
        l = 0.50;
        c = 0.04;
        h = 240.0;
        hex = "6b6f82";
      };
      text-Lc60 = mkColor {
        l = 0.65;
        c = 0.05;
        h = 240.0;
        hex = "9498ab";
      };
      text-Lc75 = mkColor {
        l = 0.80;
        c = 0.05;
        h = 240.0;
        hex = "c0c3d1";
      };
    };
  };

  # Accent Palette - Semantic colors for UI actions and states
  accent = {
    light = {
      # Primary/Success (Green) - h130
      Lc75-h130 = mkColor {
        l = 0.71;
        c = 0.20;
        h = 130.0;
        hex = "4db368";
      };
      Lc60-h130 = mkColor {
        l = 0.56;
        c = 0.18;
        h = 130.0;
        hex = "2d8f47";
      };
      Lc45-h130 = mkColor {
        l = 0.41;
        c = 0.15;
        h = 130.0;
        hex = "1b6a2f";
      };

      # Danger/Error (Red) - h040
      Lc75-h040 = mkColor {
        l = 0.64;
        c = 0.23;
        h = 40.0;
        hex = "d9574a";
      };
      Lc60-h040 = mkColor {
        l = 0.49;
        c = 0.21;
        h = 40.0;
        hex = "a93a2e";
      };
      Lc45-h040 = mkColor {
        l = 0.34;
        c = 0.18;
        h = 40.0;
        hex = "7a2419";
      };

      # Warning/Attention (Yellow-Orange) - h090
      Lc75-h090 = mkColor {
        l = 0.79;
        c = 0.15;
        h = 90.0;
        hex = "c9a93a";
      };
      Lc60-h090 = mkColor {
        l = 0.64;
        c = 0.13;
        h = 90.0;
        hex = "9d8221";
      };
      Lc45-h090 = mkColor {
        l = 0.49;
        c = 0.11;
        h = 90.0;
        hex = "715e0e";
      };

      # Info (Cyan) - h190
      Lc75-h190 = mkColor {
        l = 0.73;
        c = 0.12;
        h = 190.0;
        hex = "5aabb9";
      };
      Lc60-h190 = mkColor {
        l = 0.58;
        c = 0.11;
        h = 190.0;
        hex = "3d8592";
      };
      Lc45-h190 = mkColor {
        l = 0.43;
        c = 0.09;
        h = 190.0;
        hex = "25606b";
      };

      # Focus (Blue) - h240
      Lc75-h240 = mkColor {
        l = 0.68;
        c = 0.18;
        h = 240.0;
        hex = "5a7dcf";
      };
      Lc60-h240 = mkColor {
        l = 0.53;
        c = 0.16;
        h = 240.0;
        hex = "3a5da3";
      };
      Lc45-h240 = mkColor {
        l = 0.38;
        c = 0.14;
        h = 240.0;
        hex = "1f4077";
      };

      # Special (Purple) - h290
      Lc75-h290 = mkColor {
        l = 0.68;
        c = 0.16;
        h = 290.0;
        hex = "a368cf";
      };
      Lc60-h290 = mkColor {
        l = 0.53;
        c = 0.14;
        h = 290.0;
        hex = "7d49a3";
      };
      Lc45-h290 = mkColor {
        l = 0.38;
        c = 0.12;
        h = 290.0;
        hex = "592e77";
      };
    };

    dark = {
      # Primary/Success (Green) - h130
      Lc75-h130 = mkColor {
        l = 0.71;
        c = 0.20;
        h = 130.0;
        hex = "4db368";
      };
      Lc60-h130 = mkColor {
        l = 0.56;
        c = 0.18;
        h = 130.0;
        hex = "2d8f47";
      };
      Lc45-h130 = mkColor {
        l = 0.41;
        c = 0.15;
        h = 130.0;
        hex = "1b6a2f";
      };

      # Danger/Error (Red) - h040
      Lc75-h040 = mkColor {
        l = 0.64;
        c = 0.23;
        h = 40.0;
        hex = "d9574a";
      };
      Lc60-h040 = mkColor {
        l = 0.49;
        c = 0.21;
        h = 40.0;
        hex = "a93a2e";
      };
      Lc45-h040 = mkColor {
        l = 0.34;
        c = 0.18;
        h = 40.0;
        hex = "7a2419";
      };

      # Warning/Attention (Yellow-Orange) - h090
      Lc75-h090 = mkColor {
        l = 0.79;
        c = 0.15;
        h = 90.0;
        hex = "c9a93a";
      };
      Lc60-h090 = mkColor {
        l = 0.64;
        c = 0.13;
        h = 90.0;
        hex = "9d8221";
      };
      Lc45-h090 = mkColor {
        l = 0.49;
        c = 0.11;
        h = 90.0;
        hex = "715e0e";
      };

      # Info (Cyan) - h190
      Lc75-h190 = mkColor {
        l = 0.73;
        c = 0.12;
        h = 190.0;
        hex = "5aabb9";
      };
      Lc60-h190 = mkColor {
        l = 0.58;
        c = 0.11;
        h = 190.0;
        hex = "3d8592";
      };
      Lc45-h190 = mkColor {
        l = 0.43;
        c = 0.09;
        h = 190.0;
        hex = "25606b";
      };

      # Focus (Blue) - h240
      Lc75-h240 = mkColor {
        l = 0.68;
        c = 0.18;
        h = 240.0;
        hex = "5a7dcf";
      };
      Lc60-h240 = mkColor {
        l = 0.53;
        c = 0.16;
        h = 240.0;
        hex = "3a5da3";
      };
      Lc45-h240 = mkColor {
        l = 0.38;
        c = 0.14;
        h = 240.0;
        hex = "1f4077";
      };

      # Special (Purple) - h290
      Lc75-h290 = mkColor {
        l = 0.68;
        c = 0.16;
        h = 290.0;
        hex = "a368cf";
      };
      Lc60-h290 = mkColor {
        l = 0.53;
        c = 0.14;
        h = 290.0;
        hex = "7d49a3";
      };
      Lc45-h290 = mkColor {
        l = 0.38;
        c = 0.12;
        h = 290.0;
        hex = "592e77";
      };
    };
  };

  # Categorical Palette - For data visualization and syntax highlighting
  categorical = {
    light = {
      # GA01 - Red-Orange
      GA01 = mkColor {
        l = 0.75;
        c = 0.15;
        h = 40.0;
        hex = "d17a5f";
      };

      # GA02 - Green
      GA02 = mkColor {
        l = 0.75;
        c = 0.15;
        h = 177.5;
        hex = "5dc7a8";
      };

      # GA03 - Magenta
      GA03 = mkColor {
        l = 0.75;
        c = 0.15;
        h = 315.0;
        hex = "d985c2";
      };

      # GA04 - Yellow-Green
      GA04 = mkColor {
        l = 0.75;
        c = 0.15;
        h = 92.5;
        hex = "a7b855";
      };

      # GA05 - Blue
      GA05 = mkColor {
        l = 0.75;
        c = 0.15;
        h = 230.0;
        hex = "7a96e0";
      };

      # GA06 - Orange
      GA06 = mkColor {
        l = 0.75;
        c = 0.15;
        h = 67.5;
        hex = "d59857";
      };

      # GA07 - Cyan
      GA07 = mkColor {
        l = 0.75;
        c = 0.15;
        h = 205.0;
        hex = "65b4d9";
      };

      # GA08 - Pink
      GA08 = mkColor {
        l = 0.75;
        c = 0.15;
        h = 342.5;
        hex = "e07596";
      };
    };

    dark = {
      # GA01 - Red-Orange (adjusted lightness for dark mode)
      GA01 = mkColor {
        l = 0.65;
        c = 0.15;
        h = 40.0;
        hex = "b8664a";
      };

      # GA02 - Green
      GA02 = mkColor {
        l = 0.65;
        c = 0.15;
        h = 177.5;
        hex = "49a88d";
      };

      # GA03 - Magenta
      GA03 = mkColor {
        l = 0.65;
        c = 0.15;
        h = 315.0;
        hex = "b86da7";
      };

      # GA04 - Yellow-Green
      GA04 = mkColor {
        l = 0.65;
        c = 0.15;
        h = 92.5;
        hex = "8c9942";
      };

      # GA05 - Blue
      GA05 = mkColor {
        l = 0.65;
        c = 0.15;
        h = 230.0;
        hex = "6179be";
      };

      # GA06 - Orange
      GA06 = mkColor {
        l = 0.65;
        c = 0.15;
        h = 67.5;
        hex = "b97d43";
      };

      # GA07 - Cyan
      GA07 = mkColor {
        l = 0.65;
        c = 0.15;
        h = 205.0;
        hex = "5296b8";
      };

      # GA08 - Pink
      GA08 = mkColor {
        l = 0.65;
        c = 0.15;
        h = 342.5;
        hex = "be5f7c";
      };
    };
  };
}
