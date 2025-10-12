{
  username,
  system,
  lib,
  ...
}: let
  platformLib = import ../lib/functions.nix {inherit lib system;};
in {
  home = {
    stateVersion = "24.05";
    inherit username;
    homeDirectory = platformLib.homeDir username;
  };
  imports =
    [
      ./common
    ]
    ++ platformLib.platformModules
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
