#!/usr/bin/env bash
# Common functions for Sunshine scripts
# Shared user detection, logging, and environment setup
# Note: Not all functions are used in all scripts - this file is inlined

# Logging with script name prefix
# shellcheck disable=SC2329  # May be overridden in some scripts
log() {
    local script_name="${SCRIPT_NAME:-sunshine}"
    echo "[$script_name] $*" | systemd-cat -t "$script_name" -p info
}

# shellcheck disable=SC2329  # May be overridden in some scripts
error() {
    local script_name="${SCRIPT_NAME:-sunshine}"
    echo "[$script_name] ERROR: $*" | systemd-cat -t "$script_name" -p err
}

# Detect active graphical session user
# Sets SESSION_USER, USER_ID, XDG_RUNTIME_DIR, and NIRI_SOCKET
detect_session_user() {
    local session_user=""
    
    # Try loginctl first (most reliable for graphical sessions)
    if session_user=$(loginctl list-sessions --no-legend 2>/dev/null | \
        awk '$4 == "seat0" && $3 != "" {print $3; exit}'); then
        log "Detected user via loginctl: $session_user"
    elif [ -n "${SUDO_USER:-}" ]; then
        session_user="$SUDO_USER"
        log "Detected user via SUDO_USER: $session_user"
    elif [ -n "${USER:-}" ]; then
        session_user="$USER"
        log "Using current USER: $session_user"
    else
        error "Could not determine active graphical session user"
        return 1
    fi
    
    # Validate user exists
    if ! id "$session_user" >/dev/null 2>&1; then
        error "User '$session_user' does not exist"
        return 1
    fi
    
    # Export session information
    export SESSION_USER="$session_user"
    export USER_ID
    USER_ID=$(id -u "$SESSION_USER")
    export XDG_RUNTIME_DIR="/run/user/$USER_ID"
    
    if [ ! -d "$XDG_RUNTIME_DIR" ]; then
        error "XDG_RUNTIME_DIR does not exist: $XDG_RUNTIME_DIR"
        return 1
    fi
    
    # Find Niri socket
    local niri_socket
    niri_socket=$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name "niri.*.sock" -type s 2>/dev/null | head -n1)
    if [ -n "$niri_socket" ]; then
        export NIRI_SOCKET="$niri_socket"
        log "Found Niri socket: $NIRI_SOCKET"
    else
        log "Warning: Niri socket not found in $XDG_RUNTIME_DIR"
    fi
    
    log "Using XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
    return 0
}

# Run command as session user with proper environment
run_as_user() {
    if [ -z "${SESSION_USER:-}" ]; then
        error "SESSION_USER not set - call detect_session_user first"
        return 1
    fi
    
    local env_vars=(
        "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
    )
    
    [ -n "${NIRI_SOCKET:-}" ] && env_vars+=("NIRI_SOCKET=$NIRI_SOCKET")
    
    sudo -u "$SESSION_USER" env "${env_vars[@]}" "$@"
}

# Wait for condition with timeout
# Usage: wait_for_condition <timeout_seconds> <check_command>
# shellcheck disable=SC2329  # Not used in all scripts that inline this file
wait_for_condition() {
    local timeout="$1"
    local check_command="$2"
    local interval="${3:-0.5}"
    
    local elapsed=0
    local iterations=$((timeout * 2))  # Check twice per second
    
    for ((i=1; i<=iterations; i++)); do
        if eval "$check_command"; then
            return 0
        fi
        sleep "$interval"
        elapsed=$((elapsed + interval))
    done
    
    return 1
}
