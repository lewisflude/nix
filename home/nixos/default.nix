{ ... }:
{
  imports = [
    ./hardware-tools
    ./browser.nix
    ./desktop-apps.nix
    ./yazi.nix
    ./niri
    ./mcp.nix
    ./flatpak.nix
    ./dank-material-shell.nix
    # Removed - conflicts with DMS:
    # ./swaync.nix - DMS has notification system
    # ./apps/signal-ironbar.nix - DMS is the bar
    # ./apps/signal-notifications.nix - Only needed for swaync
    # ./apps/wofi.nix - DMS has application launcher
    # ./launcher.nix - DMS has application launcher (fuzzel)
    ./apps/polkit-gnome.nix
    ./apps/wlsunset.nix
    ./apps/swayidle.nix
    ./apps/satty.nix
    ./apps/gaming.nix
    ./apps/vr.nix
    ./apps/mpv.nix
    ./apps/obs.nix
    ./apps/hytale.nix
  ];

}
