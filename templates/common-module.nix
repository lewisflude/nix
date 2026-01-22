{
  pkgs,
  lib,
  system,
  username,
  ...
}:
let
  platformLib = (import ../../lib/functions.nix { inherit lib; }).withSystem system;
in
{
  environment.systemPackages = [
    pkgs.curl
    pkgs.wget
    pkgs.git
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
