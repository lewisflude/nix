{
  config,
  lib,
  system,
  ...
}:
let
  platformLib = (import ../../lib/functions.nix { inherit lib; }).withSystem system;
in
{
  programs.nh = {
    enable = true;

    clean.enable = false;

    flake = "${platformLib.configDir config.home.username}/nix";
  };

  home.sessionVariables = {

    NH_FLAKE = "${platformLib.configDir config.home.username}/nix";

    NH_CLEAN_ARGS = "--keep-since 4d --keep 3";
  };
}
