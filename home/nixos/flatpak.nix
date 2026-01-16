# Home-Manager Flatpak Integration
# Ensures flatpak desktop entries are visible in application launchers
{ lib, ... }:
{
  # Add flatpak exports to XDG_DATA_DIRS so desktop entries are visible in launchers (wofi, rofi, etc.)
  # Use mkAfter to append to the existing XDG_DATA_DIRS set by home-manager
  home.sessionVariables = {
    XDG_DATA_DIRS = lib.mkAfter "$HOME/.local/share/flatpak/exports/share\${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}";
  };
}
