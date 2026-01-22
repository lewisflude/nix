{
  ...
}:
{
  programs.mangohud = {
    enable = true;
    # Note: Theming removed - should come from signal-nix when MangoHud support is added
    # Using MangoHud defaults for now
    settings = {
      # FPS settings
      fps_limit = 0;
      show_fps = true;
      fps_size = 24;
      fps_position = "top-right";

      # GPU stats
      gpu_stats = true;
      gpu_temp = true;
      gpu_core_clock = true;
      gpu_mem_clock = true;
      gpu_power = true;

      # CPU stats
      cpu_stats = true;
      cpu_temp = true;

      # RAM stats
      ram = true;

      # Frame timing
      frame_timing = true;

      # Media player
      media_player = true;

      # Appearance
      background_alpha = "0.8";
      position = "top-right";
      width = 300;
      height = 200;
      font_size = 24;
      font_scale = "1.0";
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
