# Keyboard Configuration - Main Entry Point
# Manages keyboard layouts and Vial definitions
{
  ...
}:
let
  mnk88Layout = import ./layouts/mnk88.nix { };
in
{
  home.packages = [ ];

  home.file."Library/Application Support/Vial/definitions/mnk88.json".text = mnk88Layout;
}
