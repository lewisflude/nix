{ pkgs }:
let
  # Create a wrapper around nixos/tests/make-test-python.nix that provides pkgs
  makeTest = import "${pkgs.path}/nixos/tests/make-test-python.nix";

  mkTest =
    testDef:
    makeTest testDef {
      inherit pkgs;
      inherit (pkgs) system;
    };

  mkTestMachine =
    hostFeatures:
    { ... }:
    {
      imports = [
        ./vm-base.nix
        ../../modules/shared
        ../../modules/nixos
      ];

      config.host = {
        username = "testuser";
        useremail = "test@example.com";
        hostname = "test-machine";
        features = hostFeatures;
      };
    };
in
{
  inherit mkTest mkTestMachine;
}
