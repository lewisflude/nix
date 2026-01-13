{ pkgs }:
let
  mkTest = import "${pkgs.path}/nixos/tests/make-test-python.nix";

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
