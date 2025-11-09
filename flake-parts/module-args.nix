{
  inputs,
  self,
  ...
}:
let
  nixpkgs = inputs.nixpkgs or (throw "nixpkgs input is required");
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
      ;
  };
}
