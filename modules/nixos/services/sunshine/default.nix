{
  config,
  lib,
  pkgs,
  ...
}:
# Sunshine Game Streaming Module
#
# This module configures Sunshine for optimal game streaming on NixOS with:
# - Niri Wayland compositor integration
# - Display management (primary/streaming display switching)
# - Screen lock/unlock automation
# - Steam integration with window focusing
# - NVENC hardware encoding (RTX 40-series optimized)
#
# Workflow:
#   1. prep.sh: Unlock screen, disable auto-lock, configure displays
#   2. Stream: Sunshine captures and encodes gameplay
#   3. cleanup.sh: Restore displays, re-enable auto-lock, optionally lock screen
#
# See: docs/STREAMING_DEBUG_GUIDE.md for troubleshooting
let
  inherit (lib)
    mkOption
    mkIf
    mkEnableOption
    types
    optional
    ;

  cfg = config.services.sunshine;

  # Configuration constants for scripts and encoding settings
  constants = {
    # Video encoding defaults
    video = {
      bitrate1080p = 20000; # 20 Mbps - good balance for 1080p60
      bitrate1440p = 35000; # 35 Mbps - for higher resolution
      qpDefault = 28; # Quality parameter (lower = better, 18-28 recommended)
    };

    # Audio settings
    audio = {
      bitrate = 128; # kbps - balance between quality and bandwidth
      channels = 2; # Stereo output
    };

    # Timing constants (milliseconds)
    timing = {
      displayTransition = 300; # Display enable/disable delay
      steamWindowTimeout = 15000; # Max wait for Steam window
      unlockPollInterval = 200; # Swaylock check interval
      unlockMaxAttempts = 10; # Max unlock retries
    };
  };

  # Import scripts with constants
  scripts = import ./scripts/default.nix {
    inherit
      config
      lib
      pkgs
      cfg
      constants
      ;
  };
in
{
  options.services.sunshine = {
    # Extend existing sunshine options with our configuration
    display = {
      primary = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "DP-3";
        description = ''
          Primary display to disable during streaming.
          Set to null to keep all displays enabled.
          Use `niri msg outputs` to list available displays.
        '';
      };

      streaming = mkOption {
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
    };

    behavior = {
      lockOnStreamEnd = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to lock the screen when streaming ends.
          Set to false if you want to leave the screen unlocked after streaming.
        '';
      };

      autoFocusSteam = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Automatically focus Steam window after launch.
          This ensures the game streaming session starts with the correct window.
        '';
      };
    };

    audio = {
      sink = mkOption {
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
  };

  config = mkIf cfg.enable {
    # Validate configuration
    assertions = [
      {
        assertion = (cfg.display.streaming != null) -> (cfg.display.primary != cfg.display.streaming);
        message = "services.sunshine: display.streaming and display.primary cannot be the same";
      }
      {
        assertion = (cfg.display.primary != null) -> (cfg.display.streaming != null);
        message = "services.sunshine: display.primary requires display.streaming to be set";
      }
    ];

    # Warn about common misconfigurations
    warnings =
      optional (cfg.display.streaming == null && cfg.display.primary != null)
        "services.sunshine: display.primary is set but display.streaming is null - display management will not work";

    # Sunshine service configuration
    services.sunshine = {
      autoStart = true;
      capSysAdmin = true; # Required for Wayland KMS capture
      openFirewall = true;

      settings = {
        # Monitor configuration
        # When display management is enabled, prep-cmd disables the primary display,
        # leaving only the streaming display active. Sunshine auto-detects it.
        # We don't set output_name here because it requires numeric indices,
        # and the index changes when displays are enabled/disabled.

        # Audio configuration - optimized for low-latency streaming
        audio_sink = mkIf (cfg.audio.sink != null) cfg.audio.sink;
        virtual_sink = "sink-sunshine-stereo";

        # Audio codec settings - Opus is best for game streaming
        audio_codec = "opus"; # Low-latency, high-quality codec
        channels = constants.audio.channels;
        audio_bitrate = constants.audio.bitrate;

        # NVENC Encoder Configuration (2026 Best Practices)
        # Leverages RTX 4090's NVENC Gen 8 encoder for optimal streaming quality
        encoder = "nvenc"; # Force NVENC hardware encoding

        # Video codec - H.264 for wide compatibility, HEVC for better compression
        sw_preset = "llhp"; # Low Latency High Performance (optimal for RTX 40-series)

        # Rate control mode - CBR prevents bandwidth spikes
        nvenc_rc = "cbr"; # Constant Bitrate for consistent network usage

        # Two-pass encoding for better quality (minimal latency on RTX 4090)
        nvenc_twopass = "quarter_res"; # Quarter resolution analysis pass

        # Bitrate for 1080p60 streaming
        # Adjust based on network: 15-20 Mbps for 1080p60, 30-40 Mbps for 1440p60
        bitrate = constants.video.bitrate1080p;

        # Quality settings - QP (Quantization Parameter) range
        qp = constants.video.qpDefault;

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

    # Sudo rules with restricted command patterns for security
    # Only allow specific command patterns needed by Sunshine scripts
    security.sudo.extraRules = [
      {
        users = [ "sunshine" ];
        commands = [
          {
            command = "${pkgs.systemd}/bin/systemctl --user *";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.util-linux}/bin/kill";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.util-linux}/bin/pkill";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.swaylock-effects}/bin/swaylock-effects -f";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.steam}/bin/steam *";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.niri}/bin/niri msg *";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.procps}/bin/pgrep *";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
