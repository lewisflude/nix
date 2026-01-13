# PipeWire Core Configuration
# Low-latency settings and compatibility layers
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.host.features.media.audio;

  # Audio configuration constants
  quantum = if cfg.ultraLowLatency then 64 else 256;
  latency = "${toString quantum}/48000";
in
{
  config = mkIf cfg.enable {
    # Enable realtime scheduling for PipeWire
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;

      # Compatibility layers for legacy audio APIs
      alsa = {
        enable = true;
        support32Bit = true; # Required for 32-bit games
      };
      pulse.enable = true; # PulseAudio compatibility
      jack.enable = true; # JACK for professional audio (Ardour, REAPER, etc.)

      # Core PipeWire configuration - low-latency settings
      extraConfig = {
        # Low-latency configuration for PipeWire core
        pipewire."92-low-latency" = {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.quantum" = quantum;
            "default.clock.min-quantum" = 64;
            "default.clock.max-quantum" = 2048;
            # Disable ALSA sequencer to prevent crashes with phantom MIDI devices
            # See: https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/3644
            "alsa.seq.disabled" = true;
          };
          "context.modules" = [
            {
              name = "libpipewire-module-rt";
              args = {
                "nice.level" = -11;
                "rt.prio" = 88;
                "rt.time.soft" = 200000;
                "rt.time.hard" = 200000;
              };
              flags = [
                "ifexists"
                "nofail"
              ];
            }
          ];
        };

        # Low-latency configuration for PulseAudio backend
        # Note: libpipewire-module-protocol-pulse is already loaded by the base
        # pipewire-pulse.conf when services.pipewire.pulse.enable = true
        # We only need to configure the pulse properties here
        pipewire-pulse."92-low-latency" = {
          "pulse.properties" = {
            "pulse.min.req" = latency;
            "pulse.default.req" = latency;
            "pulse.max.req" = latency;
            "pulse.min.quantum" = latency;
            "pulse.max.quantum" = latency;
          };
          "stream.properties" = {
            "node.latency" = latency;
            "resample.quality" = 4; # Medium quality (was 1) - prevents crackling
          };
        };
      };
    };

    # Audio utilities and environment
    environment = {
      sessionVariables = {
        PIPEWIRE_LATENCY = latency;
        SDL_AUDIODRIVER = "pulseaudio"; # For SDL2 games
        PULSE_LATENCY_MSEC = "60"; # Balance for gaming
      };

      systemPackages = [
        pkgs.pulseaudio # pactl and compatibility tools
        pkgs.alsa-utils
        pkgs.alsa-tools
      ];
    };
  };
}
