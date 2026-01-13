# Accent Palette - Semantic colors for UI actions and states
# These colors convey meaning: success, error, warning, info, focus, special
{
  mkColor,
  ...
}:
{
  light = {
    # Primary/Success (Green) - h130
    "Lc75-h130" = mkColor {
      l = 0.71;
      c = 0.20;
      h = 130.0;
      hex = "4db368";
    };
    "Lc60-h130" = mkColor {
      l = 0.56;
      c = 0.18;
      h = 130.0;
      hex = "2d8f47";
    };
    "Lc45-h130" = mkColor {
      l = 0.41;
      c = 0.15;
      h = 130.0;
      hex = "1b6a2f";
    };

    # Danger/Error (Red) - h040
    "Lc75-h040" = mkColor {
      l = 0.64;
      c = 0.23;
      h = 40.0;
      hex = "d9574a";
    };
    "Lc60-h040" = mkColor {
      l = 0.49;
      c = 0.21;
      h = 40.0;
      hex = "a93a2e";
    };
    "Lc45-h040" = mkColor {
      l = 0.34;
      c = 0.18;
      h = 40.0;
      hex = "7a2419";
    };

    # Warning/Attention (Yellow-Orange) - h090
    "Lc75-h090" = mkColor {
      l = 0.79;
      c = 0.15;
      h = 90.0;
      hex = "c9a93a";
    };
    "Lc60-h090" = mkColor {
      l = 0.64;
      c = 0.13;
      h = 90.0;
      hex = "9d8221";
    };
    "Lc45-h090" = mkColor {
      l = 0.49;
      c = 0.11;
      h = 90.0;
      hex = "715e0e";
    };

    # Info (Cyan) - h190
    "Lc75-h190" = mkColor {
      l = 0.73;
      c = 0.12;
      h = 190.0;
      hex = "5aabb9";
    };
    "Lc60-h190" = mkColor {
      l = 0.58;
      c = 0.11;
      h = 190.0;
      hex = "3d8592";
    };
    "Lc45-h190" = mkColor {
      l = 0.43;
      c = 0.09;
      h = 190.0;
      hex = "25606b";
    };

    # Focus (Blue) - h240
    "Lc75-h240" = mkColor {
      l = 0.68;
      c = 0.18;
      h = 240.0;
      hex = "5a7dcf";
    };
    "Lc60-h240" = mkColor {
      l = 0.53;
      c = 0.16;
      h = 240.0;
      hex = "3a5da3";
    };
    "Lc45-h240" = mkColor {
      l = 0.38;
      c = 0.14;
      h = 240.0;
      hex = "1f4077";
    };

    # Special (Purple) - h290
    "Lc75-h290" = mkColor {
      l = 0.68;
      c = 0.16;
      h = 290.0;
      hex = "a368cf";
    };
    "Lc60-h290" = mkColor {
      l = 0.53;
      c = 0.14;
      h = 290.0;
      hex = "7d49a3";
    };
    "Lc45-h290" = mkColor {
      l = 0.38;
      c = 0.12;
      h = 290.0;
      hex = "592e77";
    };
  };

  dark = {
    # Primary/Success (Green) - h130
    "Lc75-h130" = mkColor {
      l = 0.71;
      c = 0.20;
      h = 130.0;
      hex = "4db368";
    };
    "Lc60-h130" = mkColor {
      l = 0.56;
      c = 0.18;
      h = 130.0;
      hex = "2d8f47";
    };
    "Lc45-h130" = mkColor {
      l = 0.41;
      c = 0.15;
      h = 130.0;
      hex = "1b6a2f";
    };

    # Danger/Error (Red) - h040
    "Lc75-h040" = mkColor {
      l = 0.64;
      c = 0.23;
      h = 40.0;
      hex = "d9574a";
    };
    "Lc60-h040" = mkColor {
      l = 0.49;
      c = 0.21;
      h = 40.0;
      hex = "a93a2e";
    };
    "Lc45-h040" = mkColor {
      l = 0.34;
      c = 0.18;
      h = 40.0;
      hex = "7a2419";
    };

    # Warning/Attention (Yellow-Orange) - h090
    "Lc75-h090" = mkColor {
      l = 0.79;
      c = 0.15;
      h = 90.0;
      hex = "c9a93a";
    };
    "Lc60-h090" = mkColor {
      l = 0.64;
      c = 0.13;
      h = 90.0;
      hex = "9d8221";
    };
    "Lc45-h090" = mkColor {
      l = 0.49;
      c = 0.11;
      h = 90.0;
      hex = "715e0e";
    };

    # Info (Cyan) - h190
    "Lc75-h190" = mkColor {
      l = 0.73;
      c = 0.12;
      h = 190.0;
      hex = "5aabb9";
    };
    "Lc60-h190" = mkColor {
      l = 0.58;
      c = 0.11;
      h = 190.0;
      hex = "3d8592";
    };
    "Lc45-h190" = mkColor {
      l = 0.43;
      c = 0.09;
      h = 190.0;
      hex = "25606b";
    };

    # Focus (Blue) - h240
    "Lc75-h240" = mkColor {
      l = 0.68;
      c = 0.18;
      h = 240.0;
      hex = "5a7dcf";
    };
    "Lc60-h240" = mkColor {
      l = 0.53;
      c = 0.16;
      h = 240.0;
      hex = "3a5da3";
    };
    "Lc45-h240" = mkColor {
      l = 0.38;
      c = 0.14;
      h = 240.0;
      hex = "1f4077";
    };

    # Special (Purple) - h290
    "Lc75-h290" = mkColor {
      l = 0.68;
      c = 0.16;
      h = 290.0;
      hex = "a368cf";
    };
    "Lc60-h290" = mkColor {
      l = 0.53;
      c = 0.14;
      h = 290.0;
      hex = "7d49a3";
    };
    "Lc45-h290" = mkColor {
      l = 0.38;
      c = 0.12;
      h = 290.0;
      hex = "592e77";
    };
  };
}
