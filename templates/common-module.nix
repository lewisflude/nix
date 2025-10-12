{
  pkgs,
  lib,
  system,
  username,
  ...
}: let
  platformLib = import ../../lib/functions.nix {inherit lib system;};
in {
  environment.systemPackages = with pkgs; [
    curl
    wget
    git
  ];
  services.example = {
    enable = true;
    port = 8080;
    user = username;
  };
  programs.example = {
    enable = true;
    package = platformLib.platformPackage pkgs.example-linux pkgs.example-darwin;
  };
}
