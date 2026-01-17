{
  inputs,
  self,
  ...
}:
let
  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;

  hostsConfig = import ../lib/hosts.nix { inherit lib; };
  inherit (hostsConfig) hosts;

  functionsLib = import ../lib/functions.nix { inherit lib; };

  systemBuilders = import ../lib/system-builders.nix {
    inherit inputs;
  };

  outputBuilders = import ../lib/output-builders.nix {
    inputs = inputs // {
      inherit self;
    };
    inherit hosts;
  };

  # Shared resources available as module arguments
  # These eliminate fragile relative imports throughout the codebase
  constants = import ../lib/constants.nix;

  # Theming library and palette - provided by Signal flake's homeManagerModule
  # Signal's module exports palette and themeLib via _module.args
  # Do not override them here - let Signal provide the colors
in
{
  # Module arguments available to all flake-parts modules
  # These can be referenced in any module using the same attribute names
  # Note: palette and themeLib are provided by Signal's homeManagerModule
  _module.args = {
    inherit
      hosts
      hostsConfig
      systemBuilders
      outputBuilders
      functionsLib
      constants
      ;
  };
}
