{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
let
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

  hexToRgb =
    hex:
    let

      hexClean = lib.removePrefix "#" hex;

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

  colors = {
    base = hexToRgb palette.base.hex;
    mantle = hexToRgb palette.mantle.hex;
    crust = hexToRgb palette.crust.hex;
    text = hexToRgb palette.text.hex;
    subtext0 = hexToRgb palette.subtext0.hex;
    subtext1 = hexToRgb palette.subtext1.hex;
    overlay0 = hexToRgb palette.overlay0.hex;
    overlay1 = hexToRgb palette.overlay1.hex;
    overlay2 = hexToRgb palette.overlay2.hex;
    surface0 = hexToRgb palette.surface0.hex;
    surface1 = hexToRgb palette.surface1.hex;
    surface2 = hexToRgb palette.surface2.hex;
    blue = hexToRgb palette.blue.hex;
    lavender = hexToRgb palette.lavender.hex;
    sapphire = hexToRgb palette.sapphire.hex;
    sky = hexToRgb palette.sky.hex;
    teal = hexToRgb palette.teal.hex;
    green = hexToRgb palette.green.hex;
    yellow = hexToRgb palette.yellow.hex;
    peach = hexToRgb palette.peach.hex;
    maroon = hexToRgb palette.maroon.hex;
    red = hexToRgb palette.red.hex;
    mauve = hexToRgb palette.mauve.hex;
    pink = hexToRgb palette.pink.hex;
    flamingo = hexToRgb palette.flamingo.hex;
    rosewater = hexToRgb palette.rosewater.hex;
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
