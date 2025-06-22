{
  lib,
  system,
  ...
}:
{
  imports = [
    # Cross-platform modules
    ./shell
    ./programs
    ./development
    ./system
    ./lib

    # Linux-specific modules (desktop environment)
  ] ++ lib.optionals (lib.hasInfix "linux" system) [
    ./desktop
  ];
}