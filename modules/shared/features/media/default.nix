{
  config,
  lib,
  pkgs,
  hostSystem,
  ...
}: let
  inherit (lib) mkIf mkMerge optionalAttrs;
  inherit (lib.lists) optional optionals;
  cfg = config.host.features.media;
  platformLib = (import ../../../../lib/functions.nix {inherit lib;}).withSystem hostSystem;
  inherit (platformLib) isLinux;
  audioNixCfg = cfg.audio.audioNix;
in {
  config = mkIf cfg.enable (mkMerge [
    (optionalAttrs isLinux {
      environment.systemPackages = with pkgs;
        optionals (cfg.audio.enable && cfg.audio.production) [
          audacity
          helm
          lsp-plugins
        ]
        ++ optionals (cfg.audio.enable && audioNixCfg.enable) (
          (optional audioNixCfg.bitwig bitwig-studio-stable-latest)
          ++ (optionals audioNixCfg.plugins [
            neuralnote
            paulxstretch
          ])
        )
        ++ optionals (cfg.video.enable && cfg.video.editing) [
          kdenlive
          ffmpeg
          handbrake

          imagemagick
          gimp
        ]
        ++ optionals ((cfg.video.enable && cfg.video.streaming) || (cfg.streaming.enable && cfg.streaming.obs))
        [
          obs-studio
        ]
        ++ optionals (cfg.video.enable && cfg.video.streaming) [
          v4l2loopback
        ];

      musnix = mkIf (cfg.audio.enable && cfg.audio.realtime) {
        enable = true;

        kernel = {
          realtime = true;
          packages = pkgs.linuxPackages-rt_latest;
        };
        rtirq.enable = true;
      };

      security.rtkit.enable = mkIf cfg.audio.enable true;

      users.users.${config.host.username}.extraGroups = optional cfg.audio.enable "audio";
    })

    {
      assertions = [
        {
          assertion = cfg.video.streaming -> cfg.streaming.enable || cfg.video.enable;
          message = "Video streaming requires either media.streaming.enable or media.video.enable";
        }
        {
          assertion = audioNixCfg.bitwig -> audioNixCfg.enable;
          message = "Bitwig Studio requires audioNix.enable to be true";
        }
        {
          assertion = audioNixCfg.plugins -> audioNixCfg.enable;
          message = "Audio plugins require audioNix.enable to be true";
        }
      ];
    }
  ]);
}
