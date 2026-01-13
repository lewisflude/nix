# Audio Processing Configuration
# Noise cancellation (RNNoise) and echo cancellation (WebRTC)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
  cfg = config.host.features.media.audio;
in
{
  config = mkMerge [
    # Noise cancellation (RNNoise) for voice chat and calls
    (mkIf (cfg.enable && cfg.noiseCancellation) {
      services.pipewire.extraConfig.pipewire."99-input-denoising"."context.modules" = [
        {
          name = "libpipewire-module-filter-chain";
          args = {
            "node.description" = "Noise Canceling Source";
            "media.name" = "Noise Canceling Source";
            "filter.graph".nodes = [
              {
                type = "ladspa";
                name = "rnnoise";
                plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                label = "noise_suppressor_stereo";
                control = {
                  "VAD Threshold (%)" = 50.0;
                  "VAD Grace Period (ms)" = 200;
                  "Retroactive VAD Grace (ms)" = 0;
                };
              }
            ];
            "audio.position" = [
              "FL"
              "FR"
            ];
            "capture.props" = {
              "node.name" = "capture.rnnoise_source";
              "node.passive" = true;
              "audio.rate" = 48000;
            };
            "playback.props" = {
              "node.name" = "rnnoise_source";
              "media.class" = "Audio/Source";
              "audio.rate" = 48000;
            };
          };
        }
      ];

      environment.systemPackages = [ pkgs.rnnoise-plugin ];
    })

    # Echo cancellation (WebRTC) for calls and streaming
    (mkIf (cfg.enable && cfg.echoCancellation) {
      services.pipewire.extraConfig.pipewire."99-echo-cancel"."context.modules" = [
        {
          name = "libpipewire-module-echo-cancel";
          args = {
            "node.description" = "Echo Cancellation";
            "capture.props" = {
              "node.name" = "echo-cancel-capture";
              "node.passive" = true;
            };
            "source.props" = {
              "node.name" = "echo-cancel-source";
              "media.class" = "Audio/Source";
            };
            "sink.props" = {
              "node.name" = "echo-cancel-sink";
              "media.class" = "Audio/Sink";
            };
            "aec.method" = "webrtc";
            "aec.args" = {
              "webrtc.gain_control" = true;
              "webrtc.extended_filter" = true;
              "webrtc.delay_agnostic" = true;
              "webrtc.noise_suppression" = true;
              "webrtc.high_pass_filter" = true;
            };
          };
        }
      ];
    })
  ];
}
