{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  inherit (lib)
    mkOption
    mkIf
    types
    ;

  cfg = config.services.sunshine;

  # Import scripts
  scripts = import ./scripts/default.nix {
    inherit
      config
      lib
      pkgs
      cfg
      ;
  };
in
{
  options.services.sunshine = {
    # Extend existing sunshine options with our configuration
    primaryDisplay = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "DP-3";
      description = ''
        Primary display to disable during streaming.
        Set to null to keep all displays enabled.
        Use `niri msg outputs` to list available displays.
      '';
    };

    streamingDisplay = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "HDMI-A-4";
      description = ''
        Display to use for streaming.
        Workspaces will be moved to this display during streaming.
        Set to null to disable automatic display management.
        Use `niri msg outputs` to list available displays.
      '';
    };

    lockOnStreamEnd = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to lock the screen when streaming ends.
        Set to false if you want to leave the screen unlocked after streaming.
      '';
    };

    audioSink = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "alsa_output.pci-0000_01_00.1.hdmi-stereo";
      description = ''
        Audio sink to use for streaming.
        Use `pactl list sinks` to find available sinks.
        Set to null to use default sink.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Sunshine service configuration
    services.sunshine = {
      autoStart = true;
      capSysAdmin = true; # Required for Wayland KMS capture
      openFirewall = true;

      settings = {
        # Monitor configuration
        output_name = mkIf (cfg.streamingDisplay != null) "1";

        # Audio configuration - optimized for low-latency streaming
        audio_sink = mkIf (cfg.audioSink != null) cfg.audioSink;
        virtual_sink = "sink-sunshine-stereo";

        # Audio codec settings - Opus is best for game streaming
        audio_codec = "opus"; # Low-latency, high-quality codec
        channels = 2; # Stereo
        audio_bitrate = 128; # kbps - balance between quality and bandwidth

        # NVENC Encoder Configuration (2026 Best Practices)
        # Leverages RTX 4090's NVENC Gen 8 encoder for optimal streaming quality
        encoder = "nvenc"; # Force NVENC hardware encoding

        # Video codec - H.264 for wide compatibility, HEVC for better compression
        sw_preset = "llhp"; # Low Latency High Performance (optimal for RTX 40-series)

        # Rate control mode - CBR prevents bandwidth spikes
        nvenc_rc = "cbr"; # Constant Bitrate for consistent network usage

        # Two-pass encoding for better quality (minimal latency on RTX 4090)
        nvenc_twopass = "quarter_res"; # Quarter resolution analysis pass

        # Bitrate for 1080p60 streaming (HDMI-A-4 output)
        # Adjust based on network: 15-20 Mbps for 1080p60, 30-40 Mbps for 1440p60
        bitrate = 20000; # 20 Mbps - good balance for 1080p60

        # Quality settings - QP (Quantization Parameter) range
        qp = 28; # Default quality (lower = better, 18-28 recommended for streaming)

        # Advanced NVENC features (RTX 40-series)
        nvenc_spatial_aq = 1; # Spatial Adaptive Quantization (improves quality)
        nvenc_temporal_aq = 1; # Temporal AQ (reduces motion artifacts)

        # Capture method - KMS is optimal for Wayland + NVIDIA
        capture = "kms";
      };

      # Application definitions with prep-cmd lifecycle hooks
      applications.apps = [
        # Desktop streaming - streams entire workspace
        {
          name = "Desktop";
          prep-cmd = [
            {
              do = "${scripts.sunshine-prep}/bin/sunshine-prep";
              undo = "${scripts.sunshine-cleanup}/bin/sunshine-cleanup";
            }
          ];
          image-path = "desktop.png";
        }

        # Steam Big Picture - for gaming
        {
          name = "Steam Big Picture";
          detached = [
            "${scripts.sunshine-steam-launcher}/bin/sunshine-steam-launcher steam://open/gamepadui"
          ];
          prep-cmd = [
            {
              do = "${scripts.sunshine-prep}/bin/sunshine-prep";
              undo = "${scripts.sunshine-cleanup}/bin/sunshine-cleanup";
            }
          ];
          image-path = "steam.png";
        }

        # Regular Steam - for desktop mode gaming
        {
          name = "Steam";
          detached = [
            "${scripts.sunshine-steam-launcher}/bin/sunshine-steam-launcher"
          ];
          prep-cmd = [
            {
              do = "${scripts.sunshine-prep}/bin/sunshine-prep";
              undo = "${scripts.sunshine-cleanup}/bin/sunshine-cleanup";
            }
          ];
          image-path = "steam.png";
        }
      ];
    };

    # Make scripts available system-wide for debugging
    environment.systemPackages = [
      scripts.sunshine-prep
      scripts.sunshine-cleanup
      scripts.sunshine-steam-launcher
    ];

    # Ensure sudo rules allow running necessary commands as user
    security.sudo.extraRules = [
      {
        users = [ "sunshine" ];
        commands = [
          {
            command = "${pkgs.systemd}/bin/systemctl";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.util-linux}/bin/kill";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.swaylock-effects}/bin/swaylock-effects";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.steam}/bin/steam";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.niri}/bin/niri";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.procps}/bin/pgrep";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
