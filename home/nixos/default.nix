{ ... }:
{
  imports = [
    ./hardware-tools
    ./browser.nix
    ./launcher.nix
    ./swaync.nix
    ./desktop-apps.nix
    ./yazi.nix
    ./niri.nix
    ./mcp.nix
    # Removed: polkit-gnome (niri-flake provides polkit-kde-agent automatically)
    ./apps/wlsunset.nix
    ./apps/swayidle.nix
    ./apps/satty.nix
    ./apps/wofi.nix
    ./apps/gaming.nix
    ./apps/vr.nix
    ./apps/mpv.nix
    ./apps/obs.nix
  ];

}
