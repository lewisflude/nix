{
  lib,
  system,
  ...
}:
{
  imports = [
    # Cross-platform modules
    ./apps.nix
    ./shell
    ./terminal.nix
    ./theme.nix
    ./development
    ./system
    ./lib

    # Linux-specific modules (desktop environment)
  ] ++ lib.optionals (lib.hasInfix "linux" system) [
    ./desktop
  ];
}