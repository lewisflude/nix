{pkgs, ...}: {
  home.packages = with pkgs; [
    dbeaver-bin
    ninja
    portaudio
    imagemagick
    ffmpeg
    doxygen
  ];
}
