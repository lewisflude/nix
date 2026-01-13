# Niri Output/Display Configuration
{
  ...
}:
{
  outputs = {
    "DP-3" = {
      scale = 1.25;
      position = {
        x = 0;
        y = 0;
      };
      mode = {
        width = 3440;
        height = 1440;
        refresh = 164.90;
      };
      variable-refresh-rate = true;
    };
    # Dummy HDMI plug (HDMI-A-4) - used for Sunshine streaming
    # Positioned next to DP-3 (ultrawide) for Sunshine to capture properly
    # DP-3 will be turned off during streaming via Sunshine prep-cmd
    "HDMI-A-4" = {
      position = {
        x = 2752; # Position to the right of DP-3 (which is 2752 logical pixels wide)
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
