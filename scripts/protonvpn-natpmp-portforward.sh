#!/usr/bin/env bash
# ProtonVPN NAT-PMP Port Forwarding Automation
# Automatically queries and maintains port forwarding via NAT-PMP

set -euo pipefail

# Configuration
NAMESPACE="${NAMESPACE:-qbt}"
VPN_GATEWAY="${VPN_GATEWAY:-10.2.0.1}"
LEASE_DURATION=60  # seconds
QBITTORRENT_CONFIG="/var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf"
LOG_PREFIX="[ProtonVPN-PortForward]"

# Logging
log_info() {
    echo "$LOG_PREFIX INFO: $*" >&2
}

log_error() {
    echo "$LOG_PREFIX ERROR: $*" >&2
}

log_success() {
    echo "$LOG_PREFIX SUCCESS: $*" >&2
}

# Check if namespace exists
check_namespace() {
    if ! ip netns list | grep -q "^${NAMESPACE}"; then
        log_error "Namespace '${NAMESPACE}' does not exist"
        return 1
    fi
    log_info "Namespace '${NAMESPACE}' exists"
}

# Check if natpmpc is available
check_natpmpc() {
    if ! command -v natpmpc >/dev/null 2>&1; then
        log_error "natpmpc not found. Install with: nix-shell -p libnatpmp"
        return 1
    fi
    log_info "natpmpc found"
}

# Check VPN connectivity with retries
check_vpn() {
    log_info "Checking VPN connectivity..."

    local max_attempts=10
    local attempt=1
    local wait_time=2

    # Wait for WireGuard handshake to complete
    while [[ $attempt -le $max_attempts ]]; do
        log_info "Attempt $attempt/$max_attempts: Testing gateway connectivity..."

        # Check if gateway is reachable
        if ip netns exec "$NAMESPACE" ping -c 1 -W 3 "$VPN_GATEWAY" >/dev/null 2>&1; then
            log_success "VPN gateway $VPN_GATEWAY is reachable"
            return 0
        fi

        if [[ $attempt -lt $max_attempts ]]; then
            log_info "Gateway not reachable yet, waiting ${wait_time}s before retry..."
            sleep $wait_time
        fi

        ((attempt++))
    done

    log_error "Cannot reach VPN gateway $VPN_GATEWAY after $max_attempts attempts"
    return 1
}

# Query NAT-PMP for port forwarding
get_forwarded_port() {
    log_info "Querying NAT-PMP for forwarded port..."

    # Request port mapping (0 0 = any internal/external port)
    # Protocol: tcp (1), Duration: $LEASE_DURATION seconds
    local output
    output=$(ip netns exec "$NAMESPACE" natpmpc -a 0 0 tcp "$LEASE_DURATION" -g "$VPN_GATEWAY" 2>&1)

    if echo "$output" | grep -q "Mapped public port"; then
        local port
        port=$(echo "$output" | grep "Mapped public port" | grep -oP 'Mapped public port \K[0-9]+')

        if [[ -n "$port" && "$port" -gt 0 ]]; then
            log_success "NAT-PMP assigned port: $port"
            echo "$port"
            return 0
        fi
    fi

    log_error "Failed to get port from NAT-PMP"
    log_error "Output: $output"
    return 1
}

# Update qBittorrent configuration
update_qbittorrent_port() {
    local port=$1

    log_info "Updating qBittorrent configuration to use port $port..."

    # Check if qBittorrent config exists
    if [[ ! -f "$QBITTORRENT_CONFIG" ]]; then
        log_error "qBittorrent config not found at $QBITTORRENT_CONFIG"
        return 1
    fi

    # Backup config
    cp "$QBITTORRENT_CONFIG" "${QBITTORRENT_CONFIG}.bak"

    # Update port in config (use proper escaping for grep)
    if grep -q '^Session\\Port=' "$QBITTORRENT_CONFIG"; then
        # Port setting exists, update it
        sed -i "s/^Session\\\\Port=.*/Session\\\\Port=$port/" "$QBITTORRENT_CONFIG"
    else
        # Port setting doesn't exist, add it under [BitTorrent] section
        if grep -q "^\[BitTorrent\]" "$QBITTORRENT_CONFIG"; then
            sed -i "/^\[BitTorrent\]/a Session\\\\Port=$port" "$QBITTORRENT_CONFIG"
        else
            # No [BitTorrent] section, create it
            echo -e "\n[BitTorrent]\nSession\\\\Port=$port" >> "$QBITTORRENT_CONFIG"
        fi
    fi

    # Verify update (use proper escaping for grep)
    if grep -q "^Session\\\\Port=$port" "$QBITTORRENT_CONFIG"; then
        log_success "Updated qBittorrent config to use port $port"
        return 0
    else
        log_error "Failed to update qBittorrent config"
        return 1
    fi
}

# Restart qBittorrent service
restart_qbittorrent() {
    log_info "Restarting qBittorrent service..."

    if systemctl restart qbittorrent.service; then
        log_success "qBittorrent service restarted"
        sleep 3  # Give service time to start
        return 0
    else
        log_error "Failed to restart qBittorrent service"
        return 1
    fi
}

# Verify qBittorrent is using the new port
verify_port() {
    local expected_port=$1

    log_info "Verifying qBittorrent is listening on port $expected_port..."

    sleep 5  # Give qBittorrent time to start listening

    if ip netns exec "$NAMESPACE" ss -tuln | grep -q ":${expected_port} "; then
        log_success "qBittorrent is listening on port $expected_port"
        return 0
    else
        log_error "qBittorrent is not listening on port $expected_port"
        return 1
    fi
}

# Main execution
main() {
    log_info "Starting ProtonVPN NAT-PMP port forwarding"

    # Pre-flight checks
    check_namespace || exit 1
    check_natpmpc || exit 1
    check_vpn || exit 1

    # Get forwarded port
    PORT=$(get_forwarded_port)
    if [[ -z "$PORT" ]]; then
        log_error "Failed to get forwarded port"
        exit 1
    fi

    # Check if current port matches (use proper escaping for grep)
    CURRENT_PORT=$(grep '^Session\\Port=' "$QBITTORRENT_CONFIG" 2>/dev/null | cut -d'=' -f2 || echo "")

    if [[ "$CURRENT_PORT" == "$PORT" ]]; then
        log_info "Port already set to $PORT, no update needed"
        exit 0
    fi

    # Update configuration
    update_qbittorrent_port "$PORT" || exit 1

    # Restart service
    restart_qbittorrent || exit 1

    # Verify
    verify_port "$PORT" || exit 1

    log_success "Port forwarding setup complete! Using port: $PORT"
    echo "$PORT"  # Output port for scripts/automation
}

# Run main function
main "$@"
