{
  imports = [
    # System integration
    ./system
    
    # Desktop environment
    ./browser.nix
    # ./hyprland.nix
    # ./hyprland-config
    ./hyprland-packages.nix
    ./launcher.nix
    ./hyprlock.nix
    ./mako.nix
    ./waybar.nix
    ./desktop-apps.nix
    ./yazi.nix
    ./niri.nix
    
    # Services
    ./mcp.nix
  ];
}
