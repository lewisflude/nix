{
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
  programs.mangohud = {
    enable = true;
    settings = {
      # FPS settings
      fps_limit = 0;
      show_fps = true;
      fps_color = "${colors.purple},1";
      fps_size = 24;
      fps_position = "top-right";

      # GPU stats
      gpu_stats = true;
      gpu_temp = true;
      gpu_core_clock = true;
      gpu_mem_clock = true;
      gpu_power = true;
      gpu_color = "${colors.blue},1";
      gpu_text_color = "${colors.text},1";

      # CPU stats
      cpu_stats = true;
      cpu_temp = true;
      cpu_color = "${colors.red},1";
      cpu_text_color = "${colors.text},1";

      # RAM stats
      ram = true;
      ram_color = "${colors.orange},1";
      ram_text_color = "${colors.text},1";

      # Frame timing
      frame_timing = true;
      frame_timing_color = "${colors.cyan},1";

      # Media player
      media_player = true;
      media_player_color = "${colors.purple},1";

      # Appearance
      background_alpha = "0.8";
      background_color = "${colors.base},1";
      position = "top-right";
      width = 300;
      height = 200;
      font_size = 24;
      font_scale = "1.0";
      font_color = "${colors.text},1";
      layout = 0;
      no_small_font = false;

      # Keyboard shortcuts
      toggle_hud = "Shift_R+F12";
      toggle_logging = "Shift_R+F11";
      toggle_fps_limit = "Shift_R+F10";
      toggle_fps = "Shift_R+F9";
      toggle_gpu = "Shift_R+F8";
      toggle_cpu = "Shift_R+F7";
      toggle_ram = "Shift_R+F6";
      toggle_frame_timing = "Shift_R+F5";
      toggle_media_player = "Shift_R+F4";
    };
  };
}
