# Categorical Palette - For data visualization and syntax highlighting
# These colors are designed to be distinguishable from each other
{
  mkColor,
  ...
}:
{
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
}
