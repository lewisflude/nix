# Sunshine Service Module - Dendritic Pattern
# Game streaming server with Wayland/NVIDIA optimization
# Usage: Import flake.modules.nixos.sunshine in host definition
{ config, ... }:
let
  constants = config.constants;
in
{
  # ==========================================================================
  # NixOS System Configuration
  # ==========================================================================
  flake.modules.nixos.sunshine =
    { lib, pkgs, ... }:
    let
      inherit (lib) mkDefault mkIf optional;

      # Configuration constants for scripts and encoding settings
      scriptConstants = {
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

      # Default configuration (can be overridden by hosts)
      displayPrimary = null; # Set by hosts if display management needed
      displayStreaming = null; # Set by hosts if display management needed
      lockOnStreamEnd = true;
      autoFocusSteam = true;
      audioSink = null; # null = use default sink

      # Build scripts with proper environment
      commonRuntimeInputs = [
        pkgs.coreutils
        pkgs.systemd
        pkgs.util-linux
        pkgs.findutils
      ];

      niriRuntimeInputs = [
        pkgs.niri
        pkgs.jq
      ];

      mkScriptEnv = lib.concatStringsSep "\n" (
        optional (displayStreaming != null) "export STREAMING_DISPLAY=\"${displayStreaming}\""
        ++ optional (displayPrimary != null) "export PRIMARY_DISPLAY=\"${displayPrimary}\""
        ++ [
          # Export timing constants as JSON for scripts to parse
          "export SUNSHINE_CONSTANTS='${builtins.toJSON scriptConstants.timing}'"
        ]
      );

      # Inline common functions
      commonFunctions = builtins.readFile ../pkgs/sunshine/scripts/common.sh;

      # Build script packages
      sunshine-steam-launcher = pkgs.writeShellApplication {
        name = "sunshine-steam-launcher";
        runtimeInputs = commonRuntimeInputs ++ niriRuntimeInputs ++ [ pkgs.steam ];
        text = commonFunctions + "\n" + builtins.readFile ../pkgs/sunshine/scripts/steam-launcher.sh;
      };

      sunshine-prep = pkgs.writeShellApplication {
        name = "sunshine-prep";
        runtimeInputs = commonRuntimeInputs ++ niriRuntimeInputs;
        text =
          mkScriptEnv + "\n" + commonFunctions + "\n" + builtins.readFile ../pkgs/sunshine/scripts/prep.sh;
      };

      sunshine-cleanup = pkgs.writeShellApplication {
        name = "sunshine-cleanup";
        runtimeInputs = commonRuntimeInputs ++ niriRuntimeInputs ++ [ pkgs.swaylock-effects ];
        text =
          mkScriptEnv
          + "\nexport LOCK_ON_STREAM_END=\""
          + lib.boolToString lockOnStreamEnd
          + "\"\n"
          + commonFunctions
          + "\n"
          + builtins.readFile ../pkgs/sunshine/scripts/cleanup.sh;
      };
    in
    {
      # Sunshine service configuration
      services.sunshine = {
        enable = true;
        autoStart = true;
        capSysAdmin = true; # Required for Wayland KMS capture
        openFirewall = true;

        settings = {
          # Audio configuration - optimized for low-latency streaming
          audio_sink = mkIf (audioSink != null) audioSink;
          virtual_sink = "sink-sunshine-stereo";

          # Audio codec settings - Opus is best for game streaming
          audio_codec = "opus"; # Low-latency, high-quality codec
          channels = scriptConstants.audio.channels;
          audio_bitrate = scriptConstants.audio.bitrate;

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
          bitrate = scriptConstants.video.bitrate1080p;

          # Quality settings - QP (Quantization Parameter) range
          qp = scriptConstants.video.qpDefault;

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
                do = "${sunshine-prep}/bin/sunshine-prep";
                undo = "${sunshine-cleanup}/bin/sunshine-cleanup";
              }
            ];
            image-path = "desktop.png";
          }

          # Steam Big Picture - for gaming
          {
            name = "Steam Big Picture";
            detached = [ "${sunshine-steam-launcher}/bin/sunshine-steam-launcher steam://open/gamepadui" ];
            prep-cmd = [
              {
                do = "${sunshine-prep}/bin/sunshine-prep";
                undo = "${sunshine-cleanup}/bin/sunshine-cleanup";
              }
            ];
            image-path = "steam.png";
          }

          # Regular Steam - for desktop mode gaming
          {
            name = "Steam";
            detached = [ "${sunshine-steam-launcher}/bin/sunshine-steam-launcher" ];
            prep-cmd = [
              {
                do = "${sunshine-prep}/bin/sunshine-prep";
                undo = "${sunshine-cleanup}/bin/sunshine-cleanup";
              }
            ];
            image-path = "steam.png";
          }
        ];
      };

      # Make scripts available system-wide for debugging
      environment.systemPackages = [
        sunshine-prep
        sunshine-cleanup
        sunshine-steam-launcher
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
              command = "${pkgs.swaylock-effects}/bin/swaylock -f";
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
