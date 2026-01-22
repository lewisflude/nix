{ pkgs, ... }:
{
  home.packages = [
    pkgs.dbeaver-bin
    pkgs.ninja
    pkgs.portaudio
    pkgs.imagemagick
    # Note: ffmpeg-full is provided via home/common/apps/audio/default.nix
    pkgs.doxygen
    pkgs.xcodebuild # Wrapper for Xcode CLI tools (requires Xcode installed via App Store)
  ];
}
