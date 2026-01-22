{
  pkgs,
  inputs,
  ...
}:
let

  mkHomeTest =
    profile: username:
    pkgs.runCommand "home-manager-${profile}-test" { } ''

      export HOME=$(mktemp -d)
      export USER=${username}


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
in
{

  home-minimal = mkHomeTest "minimal" "testuser";

  home-development = mkHomeTest "development" "testuser";

  home-desktop = mkHomeTest "desktop" "testuser";

  home-full = mkHomeTest "full" "testuser";
}
