{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.host.features.desktop;
in
{
  config = lib.mkIf cfg.enable {
    # System-level font configuration for consistent rendering across all applications
    fonts = {
      # Enable font configuration and optimization
      fontconfig = {
        enable = true;

        # Default font families - using Iosevka for consistency across the system
        defaultFonts = {
          monospace = [ "Iosevka Nerd Font" ];
          sansSerif = [ "Iosevka" ];
          serif = [ "Iosevka" ];
        };

        # Subpixel rendering for crisp text on LCD screens
        # This matches macOS-quality font rendering
        subpixel = {
          rgba = "rgb"; # Standard RGB subpixel layout (use "bgr" for rotated displays)
          lcdfilter = "default"; # FreeType LCD filter for smooth edges
        };

        # Hinting configuration - "slight" is modern standard (macOS-like)
        hinting = {
          enable = true;
          style = "slight"; # Minimal hinting preserves font design while improving clarity
        };

        # Anti-aliasing for smooth font edges
        antialias = true;
      };

      # Enable font directory symlinks for compatibility
      fontDir.enable = true;

      # System font packages
      packages = [
        # Primary fonts (already in home-manager but needed system-wide for GDM/SDDM)
        pkgs.iosevka-bin
        pkgs.nerd-fonts.iosevka

        # Fallback fonts for international characters and emoji
        pkgs.noto-fonts
        pkgs.noto-fonts-cjk-sans
        pkgs.noto-fonts-color-emoji
      ];
    };
  };
}
