# Tonal Palette - Neutral colors for backgrounds, surfaces, and text
# These are the foundation colors used throughout the Signal theme
{
  mkColor,
  ...
}:
{
  light = {
    # Base colors (lightest to darkest for light mode)
    "base-L100" = mkColor {
      l = 1.0;
      c = 0.0;
      h = 0.0;
      hex = "ffffff";
    };
    "base-L095" = mkColor {
      l = 0.95;
      c = 0.01;
      h = 240.0;
      hex = "f2f3f7";
    };

    # Surface colors
    "surface-Lc05" = mkColor {
      l = 0.91;
      c = 0.01;
      h = 240.0;
      hex = "e7e8ed";
    };
    "surface-Lc10" = mkColor {
      l = 0.87;
      c = 0.02;
      h = 240.0;
      hex = "dcdee6";
    };

    # Divider colors
    "divider-Lc15" = mkColor {
      l = 0.83;
      c = 0.02;
      h = 240.0;
      hex = "d1d3dd";
    };
    "divider-Lc30" = mkColor {
      l = 0.75;
      c = 0.03;
      h = 240.0;
      hex = "b9bcc9";
    };

    # Text colors
    "text-Lc45" = mkColor {
      l = 0.60;
      c = 0.04;
      h = 240.0;
      hex = "8b8fa1";
    };
    "text-Lc60" = mkColor {
      l = 0.45;
      c = 0.05;
      h = 240.0;
      hex = "5f6378";
    };
    "text-Lc75" = mkColor {
      l = 0.30;
      c = 0.05;
      h = 240.0;
      hex = "373b4e";
    };
  };

  dark = {
    # Base colors (darkest to lightest for dark mode)
    "base-L000" = mkColor {
      l = 0.0;
      c = 0.0;
      h = 0.0;
      hex = "000000";
    };
    "base-L015" = mkColor {
      l = 0.15;
      c = 0.01;
      h = 240.0;
      hex = "1e1f26";
    };

    # Surface colors
    "surface-Lc05" = mkColor {
      l = 0.19;
      c = 0.01;
      h = 240.0;
      hex = "25262f";
    };
    "surface-Lc10" = mkColor {
      l = 0.23;
      c = 0.02;
      h = 240.0;
      hex = "2d2e39";
    };

    # Divider colors
    "divider-Lc15" = mkColor {
      l = 0.27;
      c = 0.02;
      h = 240.0;
      hex = "353642";
    };
    "divider-Lc30" = mkColor {
      l = 0.35;
      c = 0.03;
      h = 240.0;
      hex = "454759";
    };

    # Text colors
    "text-Lc45" = mkColor {
      l = 0.50;
      c = 0.04;
      h = 240.0;
      hex = "6b6f82";
    };
    "text-Lc60" = mkColor {
      l = 0.65;
      c = 0.05;
      h = 240.0;
      hex = "9498ab";
    };
    "text-Lc75" = mkColor {
      l = 0.80;
      c = 0.05;
      h = 240.0;
      hex = "c0c3d1";
    };
  };
}
