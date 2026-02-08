# MPV media player configuration
# Dendritic pattern: Full implementation as flake.modules.homeManager.mpv
{ config, ... }:
{
  flake.modules.homeManager.mpv =
    { lib, pkgs, ... }:
    {
      programs.mpv = {
        enable = true;
        config = {
          vo = "wayland";
          gpu-context = "wayland";
          hwdec = "auto-safe";
          osd-font-size = 24;
          osd-duration = 2000;
          osd-margin-x = 40;
          osd-margin-y = 40;
          osd-bar-align-y = "0.9";
          osd-bar-w = 100;
          osd-bar-h = 2;
          osd-bar-border-size = 1;
          osd-bar-pos-y = "0.9";
          cache = "yes";
          cache-secs = 60;
          demuxer-max-bytes = "500M";
          demuxer-max-back-bytes = "500M";
        };
      };
    };
}
