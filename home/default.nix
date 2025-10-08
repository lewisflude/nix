{ username
, system
, lib
, ...
}:
let
  platformLib = import ../lib/functions.nix { inherit lib system; };
in
{
  home = {
    stateVersion = "24.05";
    inherit username;
    # Platform-specific home directory
    homeDirectory = platformLib.homeDir username;
  };

  imports =
    [
      # Common configurations (cross-platform)
      ./common

      # Platform-specific configurations
    ]
    ++ platformLib.platformModules
      [
        # Linux modules
        ./nixos
      ]
      [
        # Darwin modules
        ./darwin
      ];

  programs = {
    home-manager.enable = true;
    git.enable = true;
  };
}
