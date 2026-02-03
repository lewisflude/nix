# NH (Nix Helper) configuration
# Dendritic pattern: Full implementation as flake.modules.homeManager.nh
{ config, ... }:
{
  flake.modules.homeManager.nh =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      isDarwin = pkgs.stdenv.isDarwin;
      homeDir = if isDarwin then "/Users/${config.home.username}" else "/home/${config.home.username}";
      flakePath = "${homeDir}/.config/nix";
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
