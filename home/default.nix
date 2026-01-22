{
  username,
  system,
  lib,
  pkgs,
  ...
}:
let
  platformLib = (import ../lib/functions.nix { inherit lib; }).withSystem system;
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
  ++ lib.optionals platformLib.isLinux [
    ./nixos
  ]
  ++ lib.optionals platformLib.isDarwin [
    ./darwin
  ];
  programs = {
    home-manager.enable = true;
    git.enable = true;
  };

  # tig doesn't have a home-manager module yet, install as package
  home.packages = [ pkgs.tig ];
}
