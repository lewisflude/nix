# NH (Nix Helper) configuration
# Dendritic pattern: Full implementation as flake.modules.homeManager.nh
{ config, ... }:
let
  inherit (config) myLib;
in
{
  flake.modules.homeManager.nh =
    { pkgs, ... }@hmArgs:
    let
      configDir = myLib.configDir pkgs.stdenv.hostPlatform.system hmArgs.config.home.username;
      flakePath = "${configDir}/nix";
    in
    {
      programs.nh = {
        enable = true;
        clean = {
          enable = true;
          dates = "weekly";
          extraArgs = "--keep-since 4d --keep 3";
        };
        flake = flakePath;
      };

      home.sessionVariables = {
        NH_FLAKE = flakePath;
        NH_OS_FLAKE = flakePath;
        NH_HOME_FLAKE = flakePath;
        NH_DARWIN_FLAKE = flakePath;
        NH_NOM = "1";
      };
    };
}
