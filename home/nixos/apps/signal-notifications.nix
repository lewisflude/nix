# Signal Notifications Configuration
# Complete notification styling with Signal colors + padding + spacing + animations

{ ... }:
{
  programs.signal-notifications = {
    enable = true;
    profile = "relaxed"; # compact, relaxed, or spacious

    # Enable for SwayNC (you have this configured)
    swaync.enable = true;

    # Enable for Mako (you also have this configured)
    # Note: Only one should be active at a time
    # mako.enable = true;
  };
}
