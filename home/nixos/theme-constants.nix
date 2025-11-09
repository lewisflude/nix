{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
let
  # Function to convert a hex color string to an RGBA set
  hexToRGBA = hexString:
    let
      # Remove '#' prefix
      cleanHex = lib.removePrefix "#" hexString;
      # Extract R, G, B, A components
      rHex = lib.substring 0 2 cleanHex;
      gHex = lib.substring 2 2 cleanHex;
      bHex = lib.substring 4 2 cleanHex;
      aHex = if (lib.stringLength cleanHex) == 8 then lib.substring 6 2 cleanHex else "ff";

      # Convert hex to decimal and then to float (0.0 - 1.0)
      hexToFloat = hex: (lib.strings.fromDigits 16 (lib.strings.stringToCharacters hex)) / 255.0;
    in
    {
      red = hexToFloat rHex;
      green = hexToFloat gHex;
      blue = hexToFloat bHex;
      alpha = hexToFloat aHex;
    };

  # This is a dummy comment to force re-evaluation.
  palette = {
    rosewater = "#f5e0dc";
    flamingo = "#f2cdcd";
    pink = "#f5c2e7";
    mauve = "#cba6f7";
    red = "#f38ba8";
    maroon = "#eba0ac";
    peach = "#fab387";
    yellow = "#f9e2af";
    green = "#a6e3a1";
    teal = "#94e2d5";
    sky = "#89dceb";
    sapphire = "#74c7ec";
    blue = "#89b4fa";
    lavender = "#b4befe";
    text = "#cdd6f4";
    subtext1 = "#bac2de";
    subtext0 = "#a6adc8";
    overlay2 = "#9399b2";
    overlay1 = "#7f849c";
    overlay0 = "#6c7086";
    surface2 = "#585b70";
    surface1 = "#45475a";
    surface0 = "#313244";
    base = "#1e1e2e";
    mantle = "#181825";
    crust = "#11111b";
  };
in
{
  niri.colors = {
    focus-ring = {
      active = lib.mkDefault (hexToRGBA palette.mauve);
      inactive = lib.mkDefault (hexToRGBA palette.overlay1);
    };
    border = {
      active = lib.mkDefault (hexToRGBA palette.lavender);
      inactive = lib.mkDefault (hexToRGBA palette.surface1);
      urgent = lib.mkDefault (hexToRGBA palette.red);
    };
    shadow = lib.mkDefault (hexToRGBA "${palette.base}aa"); # Assuming 'aa' is alpha for shadow
    tab-indicator = {
      active = lib.mkDefault (hexToRGBA palette.mauve);
      inactive = lib.mkDefault (hexToRGBA palette.overlay1);
    };
  };
}
