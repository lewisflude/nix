{ ... }:
{
  imports = [
    ./hardware-tools
    ./browser.nix
    ./launcher.nix
    ./swaync.nix
    ./desktop-apps.nix
    ./yazi.nix
    ./niri
    ./mcp.nix
    ./flatpak.nix
    # ./apps/ironbar.nix  # Replaced by signal-ironbar
    ./apps/signal-ironbar.nix
    ./apps/signal-notifications.nix
    ./apps/polkit-gnome.nix
    ./apps/wlsunset.nix
    ./apps/swayidle.nix
    ./apps/satty.nix
    ./apps/wofi.nix
    ./apps/gaming.nix
    ./apps/vr.nix
    ./apps/mpv.nix
    ./apps/obs.nix
    ./apps/hytale.nix
  ];

}
