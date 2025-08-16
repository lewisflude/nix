{
  imports = [
    # System integration
    ./system

    # Desktop environment
    ./browser.nix
    ./launcher.nix
    ./swaync.nix
    ./waybar.nix
    ./desktop-apps.nix
    ./yazi.nix
    ./niri.nix
    ./swappy.nix
    ./swayidle.nix
    # Services
    ./mcp.nix
  ];
}
