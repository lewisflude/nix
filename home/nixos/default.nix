{
  imports = [
    # System integration
    ./system

    # Desktop environment
    ./browser.nix
    ./launcher.nix
    ./mako.nix
    ./waybar.nix
    ./desktop-apps.nix
    ./yazi.nix
    ./niri.nix
    ./swayidle.nix
    # Services
    ./mcp.nix
  ];
}
