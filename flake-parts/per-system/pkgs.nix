{
  inputs,
  functionsLib,
  ...
}:
{
  # Sets up pkgs for each system with overlays applied
  # Other perSystem modules can reference it via config._module.args.pkgs
  perSystem =
    { system, ... }:
    let
      inherit (inputs) nixpkgs;
      pkgsWithOverlays = import nixpkgs {
        inherit system;
        overlays = functionsLib.mkOverlays { inherit inputs system; };
        config = functionsLib.mkPkgsConfig;
      };
    in
    {
      _module.args.pkgs = pkgsWithOverlays;
    };
}
