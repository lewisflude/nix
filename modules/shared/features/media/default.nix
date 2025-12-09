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
  rtKernelPackages = pkgs.linuxPackages_rt;
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
        ++ optionals (cfg.video.enable && cfg.video.editing) [
          pkgs.kdenlive
          pkgs.ffmpeg
          pkgs.handbrake
          pkgs.imagemagick
          pkgs.gimp
        ]
        # Note: obs-studio is configured via home-manager programs.obs-studio
        ++ optionals (cfg.video.enable && cfg.video.streaming) [
          pkgs.v4l2loopback
        ];

      musnix = mkIf (cfg.audio.enable && cfg.audio.realtime) {
        enable = true;

        # Real-time kernel with RT patches
        kernel = {
          realtime = true;
          # Use stable RT kernel (6.6) - more reliable ZFS support
          # linuxPackages_latest_rt (6.11) may have ZFS module build issues
          # Available: linuxPackages_rt (6.6), linuxPackages_latest_rt (6.11)
          packages = rtKernelPackages;
        };

        # IRQ priority management for audio devices
        rtirq = {
          enable = cfg.audio.rtirq;
          # Prioritize USB (for USB audio interfaces) and sound devices
          # Higher priority (lower number) = higher real-time priority
          nameList = "rtc usb snd";
          prioLow = 0; # Lowest priority for non-realtime
          prioHigh = 90; # Highest priority for realtime
        };

        # das_watchdog: Prevents RT processes from hanging the system
        # Monitors CPU usage and kills runaway RT processes
        das_watchdog.enable = cfg.audio.dasWatchdog;

        # rtcqs: Real-time configuration analysis tool
        # Run with: rtcqs
        rtcqs.enable = cfg.audio.rtcqs;

        # Soundcard PCI ID for latency timer optimization
        # For USB interfaces, use the USB controller PCI ID
        soundcardPciId =
          if cfg.audio.usbAudioInterface.enable && cfg.audio.usbAudioInterface.pciId != null then
            cfg.audio.usbAudioInterface.pciId
          else
            "";
      };

      # Override musnix's default nofile limit (99999) for gaming compatibility
      # musnix sets PAM limits for @audio group, but gaming (ESYNC) requires 1048576
      # Use mkAfter to ensure our settings come after musnix's and take precedence
      # This override ensures both real-time audio and Wine/Proton gaming work correctly
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

      # Keep boot kernel aligned with the musnix RT kernel selection
      boot.kernelPackages = mkIf (cfg.audio.enable && cfg.audio.realtime) (
        lib.mkOverride 50 rtKernelPackages
      );

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
