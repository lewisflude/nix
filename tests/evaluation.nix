# Configuration evaluation tests
# Ensures all configurations evaluate without errors
{
  pkgs,
  inputs,
  ...
}: let
  # Test that a configuration evaluates successfully
  mkEvalTest = name: config:
    pkgs.runCommand "eval-test-${name}" {} ''
      ${pkgs.nix}/bin/nix eval --impure --expr 'builtins.deepSeq (${config}) true' || exit 1
      touch $out
    '';
in {
  # Test all system configurations evaluate
  darwin-config = mkEvalTest "darwin" ''
    (import ${inputs.darwin} {
      inherit (inputs) nixpkgs;
      system = "aarch64-darwin";
    }).darwinSystem {
      system = "aarch64-darwin";
      modules = [ ../hosts/Lewiss-MacBook-Pro/configuration.nix ];
    }.system
  '';

  nixos-config = mkEvalTest "nixos" ''
    (import ${inputs.nixpkgs} {
      system = "x86_64-linux";
    }).lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ../hosts/jupiter/configuration.nix ];
    }.config.system.build.toplevel
  '';

  # Test that options are properly typed
  host-options = mkEvalTest "host-options" ''
    let
      lib = (import ${inputs.nixpkgs} { system = "x86_64-linux"; }).lib;
      module = import ../modules/shared/host-options.nix { inherit lib; config = {}; };
    in
      module.options.host.username.type
  '';

  # Test that overlays evaluate
  overlays = mkEvalTest "overlays" ''
    let
      overlaySet = import ../overlays {
        inherit inputs;
        system = "x86_64-linux";
      };
    in
      builtins.attrNames overlaySet
  '';

  # Test feature system
  features = mkEvalTest "features" ''
    let
      lib = (import ${inputs.nixpkgs} { system = "x86_64-linux"; }).lib;
      featuresLib = import ../lib/features.nix { inherit lib; };
    in
      featuresLib.availableFeatures
  '';
}
