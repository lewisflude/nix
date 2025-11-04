# Home Manager activation tests
# Tests that Home Manager configurations can activate successfully
{
  pkgs,
  inputs,
  ...
}: let
  # Test home-manager activation for a given profile
  mkHomeTest = profile: username:
    pkgs.runCommand "home-manager-${profile}-test" {} ''
      # Create a minimal home-manager configuration
      export HOME=$(mktemp -d)
      export USER=${username}

      # Test that the configuration evaluates
      ${pkgs.nix}/bin/nix eval --impure --expr '
        let
          pkgs = import ${inputs.nixpkgs} { system = "${pkgs.stdenv.hostPlatform.system}"; };
          home-manager = import ${inputs.home-manager} { inherit pkgs; };
        in
          (home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              ../home/common/profiles/${profile}.nix
              {
                home.username = "${username}";
                home.homeDirectory = "/home/${username}";
                home.stateVersion = "24.11";
              }
            ];
          }).activationPackage
      ' || exit 1

      touch $out
    '';
in {
  # Test minimal profile
  home-minimal = mkHomeTest "minimal" "testuser";

  # Test development profile
  home-development = mkHomeTest "development" "testuser";

  # Test desktop profile
  home-desktop = mkHomeTest "desktop" "testuser";

  # Test full profile
  home-full = mkHomeTest "full" "testuser";
}
