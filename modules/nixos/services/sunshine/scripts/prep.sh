#!/usr/bin/env bash
# Sunshine prep script - unlocks screen, disables auto-lock, inhibits sleep, and prepares display
# Updated: 2026-01-08 - Fixed fd command shadowing GNU find
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
elif [ -n "${SUDO_USER:-}" ]; then
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
    # Use explicit path to avoid fd shadowing find
    NIRI_SOCKET=$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name "niri.*.sock" -type s 2>/dev/null | head -n1)
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

# Configure display for streaming (if STREAMING_DISPLAY is set)
if [ -n "${STREAMING_DISPLAY:-}" ]; then
    # Get current focused workspace
    if ! current_ws=$(run_as_user niri msg --json workspaces | jq -r '.[] | select(.is_focused == true) | .idx'); then
        error "Failed to get current workspace"
        exit 1
    fi

    log "Current workspace: $current_ws"

    # Move workspace to streaming display
    log "Moving workspace to $STREAMING_DISPLAY"
    if run_as_user niri msg action focus-monitor "$STREAMING_DISPLAY"; then
        if run_as_user niri msg action move-workspace-to-monitor "$STREAMING_DISPLAY"; then
            log "Workspace moved to $STREAMING_DISPLAY"
        else
            error "Failed to move workspace to $STREAMING_DISPLAY"
        fi
    else
        error "Failed to focus $STREAMING_DISPLAY"
    fi

    # Disable primary display if configured
    if [ -n "${PRIMARY_DISPLAY:-}" ]; then
        log "Disabling $PRIMARY_DISPLAY"
        if run_as_user niri msg output "$PRIMARY_DISPLAY" off; then
            log "Successfully disabled $PRIMARY_DISPLAY"
        else
            error "Failed to disable $PRIMARY_DISPLAY"
        fi
    fi
else
    log "Display management disabled (no STREAMING_DISPLAY configured)"
fi

log "Preparation complete - screen unlocked, auto-lock disabled, sleep inhibited"
