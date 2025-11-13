{ pkgs, ... }:
{
  home.packages = [
    pkgs.dbeaver-bin
    pkgs.ninja
    pkgs.portaudio
    pkgs.imagemagick
    pkgs.ffmpeg
    pkgs.doxygen
  ];
}
