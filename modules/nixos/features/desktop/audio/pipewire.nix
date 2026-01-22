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

    # Enhanced memory locking for realtime audio performance
    # Increases RLIMIT_MEMLOCK from default 64kB to prevent mlock warnings
    # and ensure optimal low-latency performance
    security.pam.loginLimits = [
      {
        domain = "@audio";
        type = "-";
        item = "memlock";
        value = "unlimited";
      }
      {
        domain = "@audio";
        type = "-";
        item = "rtprio";
        value = "99";
      }
      {
        domain = "@audio";
        type = "-";
        item = "nice";
        value = "-11";
      }
    ];

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
        # Client configuration - applies to all PipeWire clients
        client."92-high-quality-resample" = {
          "stream.properties" = {
            "resample.quality" = 10; # High quality for all clients
          };
        };

        pipewire."92-low-latency" = {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.quantum" = quantum;
            "default.clock.min-quantum" = 64;
            "default.clock.max-quantum" = 2048;
            # Allow dynamic sample rate switching for lossless audio
            # PipeWire will match the stream's native sample rate when possible
            # CD quality family: 44.1kHz, 88.2kHz, 176.4kHz
            # DVD quality family: 48kHz, 96kHz, 192kHz
            "default.clock.allowed-rates" = [
              44100
              48000
              88200
              96000
              176400
              192000
            ];
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
            "resample.quality" = 10; # High quality - good balance of CPU and quality
          };
          # Discord notification sounds fix
          # Discord needs higher quantum to avoid missing notification sounds
          "pulse.rules" = [
            {
              matches = [
                { "application.process.binary" = "Discord"; }
                { "application.process.binary" = "discord"; }
              ];
              actions.update-props = {
                "pulse.min.quantum" = "1024/48000"; # 21ms - prevents notification dropouts
              };
            }
          ];
        };
      };
    };

    # pactl for debugging/control (wpctl is the PipeWire-native alternative)
    # Also provides pulseaudio binary for FMOD game compatibility
    # Some games using old FMOD engine check for 'pulseaudio --check'
    environment.systemPackages = [ pkgs.pulseaudio ];
  };
}
