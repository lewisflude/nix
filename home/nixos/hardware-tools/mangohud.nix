{
  lib,
  themeLib,
  ...
}:
let
  # Generate dark mode theme using shared themeLib
  theme = themeLib.generateTheme "dark" { };

  # Extract colors from theme and convert to MangoHud format
  themeColors = theme.colors;

  # Use format conversion utility for normalized RGB strings (MangoHud format)
  colors = {
    base = theme.formats.rgbNormalizedString themeColors."surface-base";
    surface = theme.formats.rgbNormalizedString themeColors."surface-subtle";
    surfaceEmph = theme.formats.rgbNormalizedString themeColors."surface-emphasis";
    divider = theme.formats.rgbNormalizedString themeColors."divider-secondary";
    text = theme.formats.rgbNormalizedString themeColors."text-primary";
    textSecondary = theme.formats.rgbNormalizedString themeColors."text-secondary";
    textTertiary = theme.formats.rgbNormalizedString themeColors."text-tertiary";
    blue = theme.formats.rgbNormalizedString themeColors."accent-focus";
    purple = theme.formats.rgbNormalizedString themeColors."accent-special";
    green = theme.formats.rgbNormalizedString themeColors."accent-primary";
    red = theme.formats.rgbNormalizedString themeColors."accent-danger";
    yellow = theme.formats.rgbNormalizedString themeColors."accent-warning";
    cyan = theme.formats.rgbNormalizedString themeColors."accent-info";
    orange = theme.formats.rgbNormalizedString themeColors."syntax-type";
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
