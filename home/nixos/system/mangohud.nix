{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
let
  # Get Catppuccin palette colors
  catppuccinPalette =
    if lib.hasAttrByPath [ "catppuccin" "sources" "palette" ] config then
      (pkgs.lib.importJSON (config.catppuccin.sources.palette + "/palette.json"))
      .${config.catppuccin.flavor}.colors
    else if inputs ? catppuccin then
      let
        catppuccinSrc = inputs.catppuccin.src or inputs.catppuccin.outPath or null;
      in
      if catppuccinSrc != null then
        (pkgs.lib.importJSON (catppuccinSrc + "/palette.json")).mocha.colors
      else
        throw "Cannot find catppuccin source (input exists but src/outPath not found)"
    else
      throw "Cannot find catppuccin: input not available and config.catppuccin.sources.palette not set";

  # Convert hex color to RGB (0-1 range) for Mangohud
  hexToRgb =
    hex:
    let
      # Remove # or 0x prefix if present
      hexClean = lib.removePrefix "#" (lib.removePrefix "0x" hex);
      # Convert hex digits to decimal manually
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
      hexPairToInt =
        pair: (hexDigitToInt (lib.substring 0 1 pair)) * 16 + (hexDigitToInt (lib.substring 1 1 pair));
      r = (hexPairToInt (lib.substring 0 2 hexClean)) / 255.0;
      g = (hexPairToInt (lib.substring 2 2 hexClean)) / 255.0;
      b = (hexPairToInt (lib.substring 4 2 hexClean)) / 255.0;
    in
    "${toString r},${toString g},${toString b}";

  # Catppuccin Mocha colors (RGB format for Mangohud)
  colors = {
    base = hexToRgb catppuccinPalette.base.hex;
    mantle = hexToRgb catppuccinPalette.mantle.hex;
    crust = hexToRgb catppuccinPalette.crust.hex;
    text = hexToRgb catppuccinPalette.text.hex;
    subtext0 = hexToRgb catppuccinPalette.subtext0.hex;
    subtext1 = hexToRgb catppuccinPalette.subtext1.hex;
    overlay0 = hexToRgb catppuccinPalette.overlay0.hex;
    overlay1 = hexToRgb catppuccinPalette.overlay1.hex;
    overlay2 = hexToRgb catppuccinPalette.overlay2.hex;
    surface0 = hexToRgb catppuccinPalette.surface0.hex;
    surface1 = hexToRgb catppuccinPalette.surface1.hex;
    surface2 = hexToRgb catppuccinPalette.surface2.hex;
    blue = hexToRgb catppuccinPalette.blue.hex;
    lavender = hexToRgb catppuccinPalette.lavender.hex;
    sapphire = hexToRgb catppuccinPalette.sapphire.hex;
    sky = hexToRgb catppuccinPalette.sky.hex;
    teal = hexToRgb catppuccinPalette.teal.hex;
    green = hexToRgb catppuccinPalette.green.hex;
    yellow = hexToRgb catppuccinPalette.yellow.hex;
    peach = hexToRgb catppuccinPalette.peach.hex;
    maroon = hexToRgb catppuccinPalette.maroon.hex;
    red = hexToRgb catppuccinPalette.red.hex;
    mauve = hexToRgb catppuccinPalette.mauve.hex;
    pink = hexToRgb catppuccinPalette.pink.hex;
    flamingo = hexToRgb catppuccinPalette.flamingo.hex;
    rosewater = hexToRgb catppuccinPalette.rosewater.hex;
  };
in
{
  home.file.".config/MangoHud/MangoHud.conf" = {
    text = ''
      fps_limit=0
      show_fps=1
      fps_color=${colors.mauve},1
      fps_size=24
      fps_position=top-right
      gpu_stats=1
      gpu_temp=1
      gpu_core_clock=1
      gpu_mem_clock=1
      gpu_power=1
      gpu_color=${colors.blue},1
      gpu_text_color=${colors.text},1
      cpu_stats=1
      cpu_temp=1
      cpu_color=${colors.red},1
      cpu_text_color=${colors.text},1
      ram=1
      ram_color=${colors.peach},1
      ram_text_color=${colors.text},1
      frame_timing=1
      frame_timing_color=${colors.lavender},1
      media_player=1
      media_player_color=${colors.mauve},1
      background_alpha=0.8
      background_color=${colors.base},1
      position=top-right
      width=300
      height=200
      font_size=24
      font_scale=1.0
      font_color=${colors.text},1
      layout=0
      no_small_font=0
      toggle_hud=Shift_R+F12
      toggle_logging=Shift_R+F11
      toggle_fps_limit=Shift_R+F10
      toggle_fps=Shift_R+F9
      toggle_gpu=Shift_R+F8
      toggle_cpu=Shift_R+F7
      toggle_ram=Shift_R+F6
      toggle_frame_timing=Shift_R+F5
      toggle_media_player=Shift_R+F4
    '';
  };
}
