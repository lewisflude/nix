{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    mkIf
    types
    ;

  cfg = config.services.sunshine;

  # Sunshine prep script - unlocks screen, disables auto-lock, inhibits sleep, and prepares display
  # Updated: 2026-01-08 - Fixed fd command shadowing GNU find
  sunshine-prep = pkgs.writeShellApplication {
    name = "sunshine-prep";
    runtimeInputs = [
      pkgs.niri
      pkgs.jq
      pkgs.systemd
      pkgs.coreutils
      pkgs.util-linux
      pkgs.findutils
    ];
    text = ''
      # Exit on error, but allow individual commands to fail gracefully
      set -u
      set -o pipefail

      # Logging function
      log() {
          echo "[sunshine-prep] $*" | systemd-cat -t sunshine-prep -p info
      }

      error() {
          echo "[sunshine-prep] ERROR: $*" | systemd-cat -t sunshine-prep -p err
      }

      log "Starting Sunshine stream preparation"

      # Detect the active graphical session user
      # Priority: loginctl > SUDO_USER > fallback
      SESSION_USER=""

      # Try loginctl first (most reliable for graphical sessions)
      if SESSION_USER=$(loginctl list-sessions --no-legend 2>/dev/null | \
          awk '$4 == "seat0" && $3 != "" {print $3; exit}'); then
          log "Detected user via loginctl: $SESSION_USER"
      elif [ -n "''${SUDO_USER:-}" ]; then
          SESSION_USER="$SUDO_USER"
          log "Detected user via SUDO_USER: $SESSION_USER"
      else
          error "Could not determine active graphical session user"
          exit 1
      fi

      # Validate user exists
      if ! id "$SESSION_USER" >/dev/null 2>&1; then
          error "User '$SESSION_USER' does not exist"
          exit 1
      fi

      # Get user's runtime directory
      USER_ID=$(id -u "$SESSION_USER")
      export XDG_RUNTIME_DIR="/run/user/$USER_ID"

      if [ ! -d "$XDG_RUNTIME_DIR" ]; then
          error "XDG_RUNTIME_DIR does not exist: $XDG_RUNTIME_DIR"
          exit 1
      fi

      log "Using XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"

      # Find Niri socket
      NIRI_SOCKET=""
      if [ -d "$XDG_RUNTIME_DIR" ]; then
          NIRI_SOCKET=$(find "$XDG_RUNTIME_DIR" -name "niri.*.sock" -type s 2>/dev/null | head -n1)
          if [ -n "$NIRI_SOCKET" ]; then
              log "Found Niri socket: $NIRI_SOCKET"
          else
              log "Warning: Niri socket not found in $XDG_RUNTIME_DIR"
          fi
      fi

      # Helper function to run commands as session user
      run_as_user() {
          if [ -n "$NIRI_SOCKET" ]; then
              sudo -u "$SESSION_USER" env XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" NIRI_SOCKET="$NIRI_SOCKET" "$@"
          else
              sudo -u "$SESSION_USER" env XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" "$@"
          fi
      }

      # Stop swayidle to prevent auto-lock during streaming
      log "Disabling auto-lock (stopping swayidle)"
      if run_as_user systemctl --user is-active swayidle.service >/dev/null 2>&1; then
          if run_as_user systemctl --user stop swayidle.service; then
              log "Successfully stopped swayidle"
          else
              error "Failed to stop swayidle"
          fi
      else
          log "swayidle is not running"
      fi

      # Unlock swaylock if running (using SIGUSR1 signal)
      log "Unlocking screen (sending SIGUSR1 to swaylock if running)"
      if run_as_user pgrep -u "$SESSION_USER" swaylock >/dev/null 2>&1; then
          if run_as_user pkill --signal SIGUSR1 -u "$SESSION_USER" swaylock; then
              # Wait for swaylock to actually exit (max 2 seconds)
              for _ in {1..10}; do
                  if ! run_as_user pgrep -u "$SESSION_USER" swaylock >/dev/null 2>&1; then
                      log "swaylock unlocked successfully"
                      break
                  fi
                  sleep 0.2
              done

              if run_as_user pgrep -u "$SESSION_USER" swaylock >/dev/null 2>&1; then
                  error "swaylock still running after unlock attempt"
              fi
          else
              error "Failed to unlock swaylock"
          fi
      else
          log "swaylock is not running"
      fi

      # Inhibit system sleep/idle during streaming session
      # This runs in background and will be killed when prep script exits
      log "Inhibiting system sleep and idle"
      systemd-inhibit \
          --what=idle:sleep:shutdown \
          --who=sunshine \
          --why="Active streaming session" \
          --mode=block \
          sleep infinity &
      INHIBIT_PID=$!
      echo "$INHIBIT_PID" > "$XDG_RUNTIME_DIR/sunshine-inhibit.pid"
      log "Started systemd-inhibit (PID: $INHIBIT_PID)"

      # Configure display for streaming
      ${
        if cfg.streamingDisplay != null then
          ''
            # Get current focused workspace
            if ! current_ws=$(run_as_user niri msg --json workspaces | jq -r '.[] | select(.is_focused == true) | .idx'); then
                error "Failed to get current workspace"
                exit 1
            fi

            log "Current workspace: $current_ws"

            # Move workspace to streaming display
            log "Moving workspace to ${cfg.streamingDisplay}"
            if run_as_user niri msg action focus-monitor "${cfg.streamingDisplay}"; then
                if run_as_user niri msg action move-workspace-to-monitor "${cfg.streamingDisplay}"; then
                    log "Workspace moved to ${cfg.streamingDisplay}"
                else
                    error "Failed to move workspace to ${cfg.streamingDisplay}"
                fi
            else
                error "Failed to focus ${cfg.streamingDisplay}"
            fi

            ${
              if cfg.primaryDisplay != null then
                ''
                  # Disable primary display to force all content to streaming display
                  log "Disabling ${cfg.primaryDisplay}"
                  if run_as_user niri msg output "${cfg.primaryDisplay}" off; then
                      log "Successfully disabled ${cfg.primaryDisplay}"
                  else
                      error "Failed to disable ${cfg.primaryDisplay}"
                  fi
                ''
              else
                ""
            }
          ''
        else
          "log \"Display management disabled (no streamingDisplay configured)\""
      }

      log "Preparation complete - screen unlocked, auto-lock disabled, sleep inhibited"
    '';
  };

  # Sunshine cleanup script - re-locks screen, re-enables auto-lock, and restores display
  sunshine-cleanup = pkgs.writeShellApplication {
    name = "sunshine-cleanup";
    runtimeInputs = [
      pkgs.niri
      pkgs.systemd
      pkgs.coreutils
      pkgs.swaylock-effects
      pkgs.util-linux
      pkgs.findutils
    ];
    text = ''
      set -u
      set -o pipefail

      log() {
          echo "[sunshine-cleanup] $*" | systemd-cat -t sunshine-cleanup -p info
      }

      error() {
          echo "[sunshine-cleanup] ERROR: $*" | systemd-cat -t sunshine-cleanup -p err
      }

      log "Starting Sunshine stream cleanup"

      # Detect session user (same logic as prep script)
      SESSION_USER=""

      if SESSION_USER=$(loginctl list-sessions --no-legend 2>/dev/null | \
          awk '$4 == "seat0" && $3 != "" {print $3; exit}'); then
          log "Detected user via loginctl: $SESSION_USER"
      elif [ -n "''${SUDO_USER:-}" ]; then
          SESSION_USER="$SUDO_USER"
          log "Detected user via SUDO_USER: $SESSION_USER"
      else
          error "Could not determine active graphical session user"
          exit 1
      fi

      USER_ID=$(id -u "$SESSION_USER")
      export XDG_RUNTIME_DIR="/run/user/$USER_ID"

      # Find Niri socket
      NIRI_SOCKET=""
      if [ -d "$XDG_RUNTIME_DIR" ]; then
          # Use explicit path to avoid fd shadowing find
          NIRI_SOCKET=$(${pkgs.findutils}/bin/find "$XDG_RUNTIME_DIR" -maxdepth 1 -name "niri.*.sock" -type s 2>/dev/null | head -n1)
          if [ -n "$NIRI_SOCKET" ]; then
              log "Found Niri socket: $NIRI_SOCKET"
          else
              log "Warning: Niri socket not found in $XDG_RUNTIME_DIR"
          fi
      fi

      run_as_user() {
          if [ -n "$NIRI_SOCKET" ]; then
              sudo -u "$SESSION_USER" env XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" NIRI_SOCKET="$NIRI_SOCKET" "$@"
          else
              sudo -u "$SESSION_USER" env XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" "$@"
          fi
      }

      # Stop the systemd-inhibit process
      if [ -f "$XDG_RUNTIME_DIR/sunshine-inhibit.pid" ]; then
          INHIBIT_PID=$(cat "$XDG_RUNTIME_DIR/sunshine-inhibit.pid")
          if kill "$INHIBIT_PID" 2>/dev/null; then
              log "Stopped systemd-inhibit (PID: $INHIBIT_PID)"
          else
              log "systemd-inhibit process already terminated"
          fi
          rm -f "$XDG_RUNTIME_DIR/sunshine-inhibit.pid"
      else
          log "No systemd-inhibit PID file found"
      fi

      ${
        if cfg.streamingDisplay != null then
          ''
            ${
              if cfg.primaryDisplay != null then
                ''
                  # Re-enable primary display
                  log "Re-enabling ${cfg.primaryDisplay}"
                  if run_as_user niri msg output "${cfg.primaryDisplay}" on; then
                      log "Successfully re-enabled ${cfg.primaryDisplay}"

                      # Wait for output to be ready
                      sleep 0.3
                  else
                      error "Failed to re-enable ${cfg.primaryDisplay}"
                  fi
                ''
              else
                ""
            }

            # Move workspace back to primary display
            ${
              if cfg.primaryDisplay != null then
                ''
                  log "Moving workspace back to ${cfg.primaryDisplay}"
                  if run_as_user niri msg action focus-monitor "${cfg.primaryDisplay}"; then
                      if run_as_user niri msg action move-workspace-to-monitor "${cfg.primaryDisplay}"; then
                          log "Workspace moved back to ${cfg.primaryDisplay}"
                      else
                          error "Failed to move workspace back to ${cfg.primaryDisplay}"
                      fi
                  else
                      error "Failed to focus ${cfg.primaryDisplay}"
                  fi
                ''
              else
                ""
            }
          ''
        else
          "log \"Display management disabled (no streamingDisplay configured)\""
      }

      # Re-enable swayidle for auto-lock
      log "Re-enabling auto-lock (starting swayidle)"
      if run_as_user systemctl --user start swayidle.service 2>&1; then
          log "Successfully started swayidle"
      else
          error "Failed to start swayidle (may not be installed)"
      fi

      ${
        if cfg.lockOnStreamEnd then
          ''
            # Re-lock screen for security
            log "Re-locking screen for security"
            if run_as_user ${pkgs.swaylock-effects}/bin/swaylock-effects -f; then
                log "Screen locked successfully"
            else
                error "Failed to lock screen"
            fi
          ''
        else
          "log \"Screen locking disabled (lockOnStreamEnd = false)\""
      }

      log "Cleanup complete"
    '';
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
          detached = [ "${pkgs.steam}/bin/steam -gamepadui" ];
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
          detached = [ "${pkgs.steam}/bin/steam" ];
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
    ];

    # Ensure sudo rules allow running swaylock as user
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
        ];
      }
    ];
  };
}
