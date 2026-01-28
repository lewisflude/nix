{
  config,
  lib,
  pkgs,
  hostSystem,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkAfter
    optionalAttrs
    ;
  inherit (lib.lists) optional optionals;
  cfg = config.host.features.media;
  platformLib = (import ../../../../lib/functions.nix { inherit lib; }).withSystem hostSystem;
  inherit (platformLib) isLinux;
  audioNixCfg = cfg.audio.audioNix;
in
{
  config = mkIf cfg.enable (mkMerge [
    (optionalAttrs isLinux {
      environment.systemPackages =
        optionals (cfg.audio.enable && cfg.audio.production) [
          pkgs.audacity
          pkgs.helm
          pkgs.lsp-plugins
        ]
        ++ optionals (cfg.audio.enable && audioNixCfg.enable) (
          (optional audioNixCfg.bitwig pkgs.bitwig-studio-stable-latest)
          ++ (optionals audioNixCfg.plugins [
            pkgs.neuralnote
            pkgs.paulxstretch
          ])
        )
        # Note: obs-studio is configured via home-manager programs.obs-studio
        ++ optionals (cfg.video.enable && cfg.video.streaming) [
          pkgs.v4l2loopback
        ];

      musnix = mkIf (cfg.audio.enable && cfg.audio.realtime) {
        enable = true;
        rtirq.enable = cfg.audio.rtirq;
        das_watchdog.enable = cfg.audio.dasWatchdog;
        rtcqs.enable = cfg.audio.rtcqs;
      };

      security.pam.loginLimits = mkIf (cfg.audio.enable && cfg.audio.realtime) (mkAfter [
        {
          domain = "@audio";
          type = "soft";
          item = "nofile";
          value = "1048576";
        }
        {
          domain = "@audio";
          type = "hard";
          item = "nofile";
          value = "1048576";
        }
      ]);


      security.rtkit.enable = mkIf cfg.audio.enable true;

      users.users.${config.host.username}.extraGroups = optional cfg.audio.enable "audio";
    })

    {
      assertions = [
        {
          assertion = cfg.video.streaming -> cfg.video.enable;
          message = "Video streaming requires media.video.enable to be true";
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
