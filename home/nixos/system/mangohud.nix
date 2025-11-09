{
  lib,
  ...
}:
let
  # Scientific Theme - Dark Mode Palette
  # Based on OKLCH color space for perceptually uniform colors
  palette = {
    # Base and surfaces
    base = "#1e1f26"; # base-L015
    surface = "#25262f"; # surface-Lc05
    surfaceEmph = "#2d2e39"; # surface-Lc10
    divider = "#454759"; # divider-Lc30

    # Text colors
    text = "#c0c3d1"; # text-Lc75
    textSecondary = "#9498ab"; # text-Lc60
    textTertiary = "#6b6f82"; # text-Lc45

    # Accent colors
    blue = "#5a7dcf"; # Lc75-h240 (Focus)
    purple = "#a368cf"; # Lc75-h290 (Special)
    green = "#4db368"; # Lc75-h130 (Success)
    red = "#d9574a"; # Lc75-h040 (Danger)
    yellow = "#c9a93a"; # Lc75-h090 (Warning)
    cyan = "#5aabb9"; # Lc75-h190 (Info)
    orange = "#d59857"; # GA06 (Orange)
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
    base = hexToRgb palette.base;
    surface = hexToRgb palette.surface;
    surfaceEmph = hexToRgb palette.surfaceEmph;
    divider = hexToRgb palette.divider;
    text = hexToRgb palette.text;
    textSecondary = hexToRgb palette.textSecondary;
    textTertiary = hexToRgb palette.textTertiary;
    blue = hexToRgb palette.blue;
    purple = hexToRgb palette.purple;
    green = hexToRgb palette.green;
    red = hexToRgb palette.red;
    yellow = hexToRgb palette.yellow;
    cyan = hexToRgb palette.cyan;
    orange = hexToRgb palette.orange;
  };
in
{
  home.file.".config/MangoHud/MangoHud.conf" = {
    text = ''
      fps_limit=0
      show_fps=1
      fps_color=${colors.purple},1
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
      ram_color=${colors.orange},1
      ram_text_color=${colors.text},1
      frame_timing=1
      frame_timing_color=${colors.cyan},1
      media_player=1
      media_player_color=${colors.purple},1
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
