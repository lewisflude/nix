{
  imports = [
    # ./bar.nix  # disabled to avoid conflicts with nixos-specific waybar config
    ./theme.nix
    # ./desktop-environment.nix  # disabled to avoid conflicts with nixos-specific configs
    # ./hyprland.nix  # disabled to avoid conflicts with nixos-specific config
    # ./hyprland  # hyprland directory disabled due to conflicts
  ];
}