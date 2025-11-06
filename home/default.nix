{
  username,
  system,
  lib,
  ...
}: let
  platformLib = (import ../lib/functions.nix {inherit lib;}).withSystem system;
  functionsLib = import ../lib/functions.nix {inherit lib;};
in {
  nixpkgs.config = functionsLib.mkPkgsConfig;

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
