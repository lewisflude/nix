{ pkgs, ... }:
{
  home.packages = [
    pkgs.dbeaver-bin
    pkgs.ninja
    pkgs.portaudio
    pkgs.imagemagick
    pkgs.ffmpeg
    pkgs.doxygen
    pkgs.xcodebuild # Wrapper for Xcode CLI tools (requires Xcode installed via App Store)
  ];
}
