{
  username,
  system,
  lib,
  inputs,
  ...
}:
let
  platformLib = (import ../lib/functions.nix { inherit lib; }).withSystem system;
  functionsLib = import ../lib/functions.nix { inherit lib; };
in
{
  # Note: nixpkgs config is handled at system level with useGlobalPkgs = true
  # This ensures home-manager uses the same pkgs instance with all overlays applied

  home = {
    stateVersion = "24.05";
    inherit username;
    homeDirectory = platformLib.homeDir username;
  };
  imports = [
    ./common
  ]
  ++
    platformLib.platformModules
      [
        ./nixos
      ]
      [
        ./darwin
      ];
  programs = {
    home-manager.enable = true;
    git.enable = true;
  };
}
