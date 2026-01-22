# Niri Output/Display Configuration
_: {
  outputs = {
    # Primary ultrawide monitor (AW3423DWF)
    "DP-3" = {
      # 1.25x scaling for comfortable text size on 34" 3440x1440 ultrawide
      scale = 1.25;

      # Origin position (top-left of global coordinate space)
      position = {
        x = 0;
        y = 0;
      };

      # Native resolution and max refresh rate
      mode = {
        width = 3440;
        height = 1440;
        refresh = 164.90;
      };

      # Enable VRR only on-demand (for games/video) to avoid VRR bugs
      # Requires window rule with variable-refresh-rate to activate
      variable-refresh-rate = "on-demand";

      # Focus this output when niri starts
      focus-at-startup = true;
    };

    # Dummy HDMI plug (HDMI-A-4) - used for Sunshine game streaming
    # Positioned to the right of DP-3 for proper Sunshine capture
    # DP-3 is turned off during streaming via Sunshine prep-cmd
    "HDMI-A-4" = {
      position = {
        # 3440px ÷ 1.25 scale = 2752 logical pixels (DP-3 width in logical space)
        x = 2752;
        y = 0;
      };
      mode = {
        width = 1920;
        height = 1080;
        refresh = 60.0;
      };
      scale = 1.0;
    };
  };
}
