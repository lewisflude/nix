# Signal Ironbar - Status bar with Signal Design System colors
{ config, lib, ... }:
{
  programs.signal-ironbar = {
    enable = true;
    compositor = "niri";

    # Display profile: "compact" (1080p), "relaxed" (1440p), "spacious" (4K)
    profile = "relaxed";

    # DDC-CI bus for external monitor brightness (run `ddcutil detect` to find)
    widgets.brightness.ddc.bus = 17;

    # Niri-specific widgets
    widgets.focused.enable = true;
    widgets.niriLayout.enable = true;
  };
}
