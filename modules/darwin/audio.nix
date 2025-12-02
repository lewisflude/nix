{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.lists) optionals;
  cfg = config.host.features.media.audio;
in
{
  config = mkIf cfg.enable {
    # macOS handles audio natively via CoreAudio
    # We only provide CLI tools and audio production packages

    environment.systemPackages = [
      # Basic audio packages
      pkgs.ffmpeg-full # Comprehensive audio/video conversion
      pkgs.flac
      pkgs.lame
      pkgs.opus
      pkgs.vorbis-tools
    ]
    ++ optionals cfg.production [
      # Audio production tools
      pkgs.portaudio
      pkgs.rtaudio
      pkgs.rtmidi
      pkgs.jack2
      pkgs.qjackctl
    ];

    # Audio production utilities that benefit from system-wide installation
    # DAWs and heavy audio software are typically installed via App Store or DMG
  };
}
