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

  # Theming library and palette
  palette = import ../modules/shared/features/theming/palette.nix { };
  themeLib = import ../modules/shared/features/theming/lib.nix {
    inherit lib;
    palette = import ../modules/shared/features/theming/palette.nix { };
  };
in
{
  # Module arguments available to all flake-parts modules
  # These can be referenced in any module using the same attribute names
  _module.args = {
    inherit
      hosts
      hostsConfig
      systemBuilders
      outputBuilders
      functionsLib
      constants
      palette
      themeLib
      ;
  };
}
