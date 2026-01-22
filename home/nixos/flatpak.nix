# Home-Manager Flatpak Integration
# Ensures flatpak desktop entries are visible in application launchers
# Per nix-flatpak documentation: https://github.com/gmodena/nix-flatpak/issues/31
{ ... }:
{
  # Add flatpak exports to XDG_DATA_DIRS so desktop entries are visible in launchers
  # This is the proper Home Manager way to extend XDG_DATA_DIRS
  xdg.systemDirs.data = [
    "/var/lib/flatpak/exports/share" # System-wide flatpaks
    "$HOME/.local/share/flatpak/exports/share" # User flatpaks
  ];
}
