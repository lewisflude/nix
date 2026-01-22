#!/usr/bin/env bash
# Steam launcher with window focus - ensures Steam window gets focused after launch
set -u
set -o pipefail

export SCRIPT_NAME="sunshine-steam-launcher"

# Override log/error to also echo to stdout for immediate feedback
# (common.sh functions are inlined by Nix derivation, but we want stdout too)
_common_log="$(declare -f log)"
_common_error="$(declare -f error)"

log() {
    local script_name="${SCRIPT_NAME:-sunshine}"
    echo "[$script_name] $*" | systemd-cat -t "$script_name" -p info
    echo "[$script_name] $*"
}

error() {
    local script_name="${SCRIPT_NAME:-sunshine}"
    echo "[$script_name] ERROR: $*" | systemd-cat -t "$script_name" -p err
    echo "[$script_name] ERROR: $*"
}

# Initialize session (detect_session_user and run_as_user are from common.sh, inlined by Nix)
detect_session_user || exit 1

# Determine launch mode based on arguments
LAUNCH_BIG_PICTURE=0
if [[ "${1:-}" == "steam://open/gamepadui" ]] || [[ "${1:-}" == "steam://open/bigpicture" ]]; then
  LAUNCH_BIG_PICTURE=1
  shift  # Remove the URI argument
fi

log "Steam launcher starting (Big Picture mode: $LAUNCH_BIG_PICTURE)"
log "Arguments received: $*"

# Check if Steam is already running for this user
if run_as_user pgrep -x steam >/dev/null 2>&1; then
  log "Steam is already running"

  # If we need Big Picture mode, send command to running Steam
  if [ $LAUNCH_BIG_PICTURE -eq 1 ]; then
    log "Opening Big Picture mode in running Steam instance"
    # Use Steam's command-line to open Big Picture in running instance
    run_as_user steam steam://open/bigpicture >/dev/null 2>&1 &
    sleep 2  # Give Steam time to switch modes
  fi
else
  log "Launching Steam..."
  if [ $LAUNCH_BIG_PICTURE -eq 1 ]; then
    log "Launching Steam in Big Picture mode using -gamepadui flag"
    # Launch Steam directly in Big Picture mode using -gamepadui flag
    run_as_user steam -gamepadui "$@" >/dev/null 2>&1 &
  else
    log "Launching Steam normally"
    run_as_user steam "$@" >/dev/null 2>&1 &
  fi
fi

# Wait for Steam window to appear (max 15 seconds)
log "Waiting for Steam window to appear..."
for i in {1..30}; do
  # Check if a Steam window exists
  if run_as_user niri msg --json windows | jq -e '.[] | select(.app_id == "steam")' >/dev/null 2>&1; then
    log "Steam window detected (attempt $i), focusing..."

    # Get the Steam window ID
    WINDOW_ID=$(run_as_user niri msg --json windows | jq -r '.[] | select(.app_id == "steam") | .id' | head -n1)

    if [ -n "$WINDOW_ID" ]; then
      # Focus the Steam window
      if run_as_user niri msg action focus-window --id "$WINDOW_ID"; then
        log "Successfully focused Steam window (ID: $WINDOW_ID)"

        # Additional focus attempt for Big Picture mode
        if [ $LAUNCH_BIG_PICTURE -eq 1 ]; then
          sleep 1
          run_as_user niri msg action focus-window --id "$WINDOW_ID"
          log "Re-focused for Big Picture mode"
        fi

        exit 0
      else
        log "Failed to focus window, retrying..."
      fi
    fi
  fi
  sleep 0.5
done

log "Warning: Steam window did not appear within 15 seconds"
# Don't fail - Steam might still be starting
exit 0
