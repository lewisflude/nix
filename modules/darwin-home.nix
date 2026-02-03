# Darwin-specific home-manager configuration
# Dendritic pattern: Full implementation as flake.modules.homeManager.darwinHome
{ config, ... }:
{
  flake.modules.homeManager.darwinHome = { lib, pkgs, config, ... }:
    lib.mkIf pkgs.stdenv.isDarwin {
      home.packages = [
        pkgs.dbeaver-bin
        pkgs.ninja
        pkgs.portaudio
        pkgs.imagemagick
        pkgs.doxygen
        pkgs.xcodebuild
        pkgs.lame
        pkgs.flac
      ];
    };
}
