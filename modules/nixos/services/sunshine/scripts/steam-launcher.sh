#!/usr/bin/env bash
# Steam launcher with window focus - ensures Steam window gets focused after launch
set -u
set -o pipefail

# Logging function
log() {
  echo "[sunshine-steam-launcher] $*" | systemd-cat -t sunshine-steam-launcher -p info
  echo "[sunshine-steam-launcher] $*"
}

error() {
  echo "[sunshine-steam-launcher] ERROR: $*" | systemd-cat -t sunshine-steam-launcher -p err
  echo "[sunshine-steam-launcher] ERROR: $*"
}

# Detect the active graphical session user
SESSION_USER=""
if SESSION_USER=$(loginctl list-sessions --no-legend 2>/dev/null | \
    awk '$4 == "seat0" && $3 != "" {print $3; exit}'); then
    log "Detected user via loginctl: $SESSION_USER"
elif [ -n "${SUDO_USER:-}" ]; then
    SESSION_USER="$SUDO_USER"
    log "Detected user via SUDO_USER: $SESSION_USER"
elif [ -n "${USER:-}" ]; then
    SESSION_USER="$USER"
    log "Using current USER: $SESSION_USER"
else
    error "Could not determine active graphical session user"
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
    NIRI_SOCKET=$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name "niri.*.sock" -type s 2>/dev/null | head -n1)
    if [ -n "$NIRI_SOCKET" ]; then
        export NIRI_SOCKET
        log "Found Niri socket: $NIRI_SOCKET"
    else
        error "Niri socket not found in $XDG_RUNTIME_DIR"
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
