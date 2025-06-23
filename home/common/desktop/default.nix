{
  lib,
  system,
  ...
}:
{
  imports = [
    # Platform-specific desktop configs are handled in nixos/ and darwin/ directories
  ] ++ lib.optionals (lib.hasInfix "linux" system) [
    # Linux-specific desktop configs (Wayland/X11 applications)
    ./desktop-environment.nix
  ];
}