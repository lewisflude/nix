# Darwin-specific home-manager configuration
# Dendritic pattern: Full implementation as flake.modules.homeManager.darwinHome
{ config, ... }:
{
  flake.modules.homeManager.darwinHome =
    { lib, pkgs, ... }:
    lib.mkIf pkgs.stdenv.isDarwin {
      home.packages = [
        pkgs.ninja
        pkgs.portaudio
        pkgs.imagemagick
        pkgs.xcodebuild
        pkgs.lame
        pkgs.flac
      ];
    };
}
