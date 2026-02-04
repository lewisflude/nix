#!/usr/bin/env bash
# Sunshine cleanup script - re-locks screen, re-enables auto-lock, and restores display
set -u
set -o pipefail

export SCRIPT_NAME="sunshine-cleanup"

# Common functions are inlined by Nix build (see scripts/default.nix)

log "Starting Sunshine stream cleanup"

# Initialize session
detect_session_user || exit 1

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
