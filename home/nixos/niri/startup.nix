# Niri Startup Commands Configuration
#
# Note: Keep spawn-at-startup minimal. Background services should be systemd user services:
# - Notification daemon (mako/swaync) - handled by home-manager service
# - Status bar (ironbar) - handled by home-manager service
# - Authentication agent (polkit) - handled by home-manager service
# - Portal daemons - auto-started by systemd
#
# spawn-at-startup is best for:
# - One-off initialization commands
# - Display configuration
# - Workspace setup
{
  config,
  pkgs,
  inputs,
  system,
  ...
}:
{
  spawn-at-startup = [
    # xwayland-satellite is automatically managed by niri >= 25.08
    # It spawns on-demand when X11 clients connect and auto-restarts if it crashes
    # No need to spawn it manually here

    # awww wallpaper daemon
    # "An Answer to your Wayland Wallpaper Woes"
    # Set wallpapers with: awww img /path/to/image.png
    {
      command = [
        "${inputs.awww.packages.${system}.awww}/bin/awww-daemon"
      ];
    }

    # Apply ICC color profile for AW3423DWF monitor
    # ArgyllCMS dispwin loads the calibrated color profile
    # Note: If this fails, displays might not be ready yet (rare race condition)
    {
      command = [
        "${pkgs.argyllcms}/bin/dispwin"
        "-d"
        "1"
        "${config.home.homeDirectory}/.local/share/icc/aw3423dwf.icc"
      ];
    }

    # Gamma and brightness correction for display quality
    # For OLED displays (AW3423DWF), gamma 1.0 provides accurate color reproduction
    # Adjust if needed: gamma >1.0 brightens, <1.0 darkens
    {
      command = [
        "${pkgs.wl-gammactl}/bin/wl-gammactl"
        "--gamma"
        "1.0"
        "--brightness"
        "1.0"
      ];
    }

    # Enable dummy HDMI output for Sunshine game streaming
    # This ensures HDMI-A-4 is always available as Monitor 1 for streaming
    # Alternative: Could be handled via output config, but explicit enable ensures reliability
    {
      command = [
        "${pkgs.niri}/bin/niri"
        "msg"
        "output"
        "HDMI-A-4"
        "on"
      ];
    }
  ];
}
