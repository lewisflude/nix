{ ... }: {
  home.file.".config/MangoHud/MangoHud.conf" = {
    text = ''
      # MangoHud configuration
      # FPS
      fps_limit=0
      show_fps=1
      fps_color=0,1,0,1
      fps_size=24
      fps_position=top-right

      # GPU
      gpu_stats=1
      gpu_temp=1
      gpu_core_clock=1
      gpu_mem_clock=1
      gpu_power=1
      gpu_color=0,0,1,1
      gpu_text_color=1,1,1,1

      # CPU
      cpu_stats=1
      cpu_temp=1
      cpu_color=1,0,0,1
      cpu_text_color=1,1,1,1

      # Memory
      ram=1
      ram_color=1,1,0,1
      ram_text_color=1,1,1,1

      # Frame timing
      frame_timing=1
      frame_timing_color=1,1,1,1

      # Media player
      media_player=1
      media_player_color=1,1,1,1

      # Background
      background_alpha=0.5
      background_color=0,0,0,1

      # Position and size
      position=top-right
      width=300
      height=200

      # Font
      font_size=24
      font_scale=1.0
      font_color=1,1,1,1

      # Layout
      layout=0
      no_small_font=0

      # Other
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