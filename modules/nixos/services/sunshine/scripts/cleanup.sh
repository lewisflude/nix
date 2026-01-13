#!/usr/bin/env bash
# Sunshine cleanup script - re-locks screen, re-enables auto-lock, and restores display
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
elif [ -n "${SUDO_USER:-}" ]; then
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
    NIRI_SOCKET=$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name "niri.*.sock" -type s 2>/dev/null | head -n1)
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

# Restore display configuration (if STREAMING_DISPLAY is set)
if [ -n "${STREAMING_DISPLAY:-}" ]; then
    # Re-enable primary display if configured
    if [ -n "${PRIMARY_DISPLAY:-}" ]; then
        log "Re-enabling $PRIMARY_DISPLAY"
        if run_as_user niri msg output "$PRIMARY_DISPLAY" on; then
            log "Successfully re-enabled $PRIMARY_DISPLAY"

            # Wait for output to be ready
            sleep 0.3
        else
            error "Failed to re-enable $PRIMARY_DISPLAY"
        fi

        # Move workspace back to primary display
        log "Moving workspace back to $PRIMARY_DISPLAY"
        if run_as_user niri msg action focus-monitor "$PRIMARY_DISPLAY"; then
            if run_as_user niri msg action move-workspace-to-monitor "$PRIMARY_DISPLAY"; then
                log "Workspace moved back to $PRIMARY_DISPLAY"
            else
                error "Failed to move workspace back to $PRIMARY_DISPLAY"
            fi
        else
            error "Failed to focus $PRIMARY_DISPLAY"
        fi
    fi
else
    log "Display management disabled (no STREAMING_DISPLAY configured)"
fi

# Re-enable swayidle for auto-lock
log "Re-enabling auto-lock (starting swayidle)"
if run_as_user systemctl --user start swayidle.service 2>&1; then
    log "Successfully started swayidle"
else
    error "Failed to start swayidle (may not be installed)"
fi

# Re-lock screen if configured
if [ "${LOCK_ON_STREAM_END:-true}" = "true" ]; then
    log "Re-locking screen for security"
    if run_as_user swaylock-effects -f; then
        log "Screen locked successfully"
    else
        error "Failed to lock screen"
    fi
else
    log "Screen locking disabled (LOCK_ON_STREAM_END = false)"
fi

log "Cleanup complete"
