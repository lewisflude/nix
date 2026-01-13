# Niri Startup Commands Configuration
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
    {
      command = [
        "${inputs.awww.packages.${system}.awww}/bin/awww-daemon"
      ];
    }
    # Create all workspaces on startup for consistent ironbar display
    {
      command = [
        "${config.home.homeDirectory}/.local/bin/create-niri-workspaces"
      ];
    }

    {
      command = [
        "${pkgs.argyllcms}/bin/dispwin"
        "-d"
        "1"
        "${config.home.homeDirectory}/.local/share/icc/aw3423dwf.icc"
      ];
    }
    # Gamma correction for better display quality
    # Adjust gamma values if needed (default: 1.0 for all channels)
    # For OLED displays, slight gamma adjustment can improve perceived contrast
    {
      command = [
        "${pkgs.wl-gammactl}/bin/wl-gammactl"
        "--gamma"
        "1.0"
        "--brightness"
        "1.0"
      ];
    }
    # Enable HDMI-A-4 at startup so Sunshine can detect it as Monitor 1
    # This display is used for streaming and should always be enabled
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
