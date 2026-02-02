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
    # Files removed - DMS provides these features:
    #   mako.nix, swaync.nix - DMS has notification system
    #   launcher.nix - DMS has Spotlight launcher
    #   apps/wofi.nix - DMS has application launcher
    #   apps/signal-ironbar.nix - DMS is the bar
    #   apps/signal-notifications.nix - Only needed for swaync
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
