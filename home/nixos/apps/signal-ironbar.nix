# Signal Ironbar Theme Configuration
# Complete ironbar setup with Signal colors
{
  config,
  lib,
  ...
}:
{
  programs.signal-ironbar = {
    enable = true;
    profile = "relaxed"; # compact | relaxed | spacious

    # Enable all available widgets
    widgets = {
      niriLayout.enable = true;
      battery.enable = true;
      brightness.enable = true;
      volume.enable = true;
      clock.enable = true;
      focused.enable = true;
      notifications.enable = true;
      power.enable = true;
      tray.enable = true;
      workspaces.enable = true;
    };
  };
}
