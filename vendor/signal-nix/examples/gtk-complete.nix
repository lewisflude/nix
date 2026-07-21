# Complete GTK Theming Example
# Shows both visual theming and behavioral dconf settings
# This is a partial Home Manager configuration
# Assumes the Signal module is already imported in your flake

{ pkgs, ... }:
{
  # Enable GTK programs (Signal will theme them automatically)
  gtk.enable = true;

  # Signal GTK theming configuration
  theming.signal = {
    enable = true;
    autoEnable = true; # Automatically theme all enabled GTK apps
    mode = "dark"; # "light", "dark", or "auto"

    # GTK visual + behavioral theming
    gtk = {
      enable = true; # Visual theming (colors, CSS, Adwaita palette)

      # Behavioral settings via dconf (enabled by default)
      dconf = {
        enable = true;

        # Clock settings
        clockFormat = "24h"; # 24-hour time format
        clockShowWeekday = false; # Don't show weekday

        # Interface
        enableAnimations = true; # Enable smooth animations

        # Font rendering (optimized for LCD monitors)
        fontAntialiasing = "rgba"; # Subpixel antialiasing
        fontHinting = "slight"; # Subtle hinting for modern fonts

        # Touchpad settings (for laptops)
        touchpad = {
          tapToClick = true; # Tap to click
          clickMethod = "fingers"; # Two-finger right-click
          naturalScroll = false; # Traditional scroll direction
        };

        # Night Light (blue light filter)
        nightLight = {
          enable = true; # Enable Night Light
          temperature = 4500; # Warm color temperature (Kelvin)
        };
      };
    };
  };

  # Example GTK applications that will be themed
  home.packages = with pkgs; [
    # GNOME apps
    nautilus # Files
    gnome-text-editor
    gnome-calendar
    gnome-calculator

    # GTK applications
    gimp
    inkscape
    transmission-gtk
    audacity
  ];
}

# What this configuration provides:
#
# 1. Visual Theming:
#    - Signal colors applied to all GTK 3/4 applications
#    - Full Adwaita color palette (45 variables)
#    - Window, button, entry, list, menu styling
#    - State colors (error, warning, success)
#
# 2. Behavioral Settings (via dconf):
#    - color-scheme preference (prefer-dark)
#    - Font rendering optimized for your monitor type
#    - Interface behaviors (animations, clock format)
#    - Touchpad settings (tap-to-click, natural scroll)
#    - Night Light for reduced eye strain
#
# 3. Application Integration:
#    - GNOME Settings respects Signal colors
#    - File manager (Nautilus) uses Signal palette
#    - GNOME Text Editor follows color scheme
#    - All GTK apps get consistent theming
