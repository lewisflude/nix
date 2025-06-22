{
  lib,
  system,
  ...
}:
{
  imports = [
    ./theme.nix
    ./hyprland
    # Platform-specific desktop configs are handled in nixos/ and darwin/ directories
    # to avoid conflicts between different desktop environments
  ] ++ lib.optionals (lib.hasInfix "darwin" system) [
    # macOS-specific desktop configs would go here
    ./desktop-environment.nix  # Basic desktop utilities for macOS
  ];
}