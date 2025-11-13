#!/usr/bin/env bash
# ProtonVPN NAT-PMP Port Forwarding Automation
# Automatically queries and maintains port forwarding via NAT-PMP

set -euo pipefail

# Configuration (from environment or defaults)
NAMESPACE="${NAMESPACE:-qbt}"
VPN_GATEWAY="${VPN_GATEWAY:-10.2.0.1}"
QBT_PORT="${QBT_PORT:-62000}"  # qBittorrent BitTorrent port (from Nix config)
LEASE_DURATION=3600  # seconds (60 minutes matches typical NAT-PMP lease time)
QBITTORRENT_CONFIG="/var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf"
PORTFORWARD_STATE="/var/lib/protonvpn-portforward.state"  # Store current public port (requires root)
LOG_PREFIX="[ProtonVPN-PortForward]"

# Tool paths (can be overridden by systemd environment variables)
IP="${IP_BIN:-$(command -v ip)}"
GREP="${GREP_BIN:-$(command -v grep)}"
NATPMPC="${NATPMPC_BIN:-$(command -v natpmpc)}"

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
    if ! "${IP}" netns list | "${GREP}" -q "^${NAMESPACE}"; then
        log_error "Namespace '${NAMESPACE}' does not exist"
        return 1
    fi
    log_info "Namespace '${NAMESPACE}' exists"
}

# Check if natpmpc is available
check_natpmpc() {
    if [[ ! -x "${NATPMPC}" ]]; then
        log_error "natpmpc not found at ${NATPMPC}"
        return 1
    fi
    log_info "natpmpc found at ${NATPMPC}"
}

# Check VPN connectivity with retries (run on host, not in namespace)
check_vpn() {
    log_info "Checking VPN connectivity via NAT-PMP..."

    local max_attempts=5
    local attempt=1
    local wait_time=2

    # Wait for WireGuard handshake to complete (try NAT-PMP as connectivity test)
    # NOTE: natpmpc must run on the HOST, not in the namespace
    while [[ $attempt -le $max_attempts ]]; do
        log_info "Attempt $attempt/$max_attempts: Testing NAT-PMP connectivity..."

        # Try to get public IP via NAT-PMP on the HOST
        local natpmp_output
        natpmp_output=$("${NATPMPC}" -g "$VPN_GATEWAY" 2>&1)

        if echo "$natpmp_output" | "${GREP}" -q "Public IP address"; then
            log_success "VPN gateway $VPN_GATEWAY is reachable via NAT-PMP"
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

# Query NAT-PMP for port forwarding (run on host, not in namespace)
get_forwarded_port() {
    log_info "Querying NAT-PMP for port forwarding on port $QBT_PORT..."

    # ProtonVPN requires explicit ports (does not support port 0 wildcard)
    # Use qBittorrent's configured torrent port (passed from Nix config)

    # Request port mapping with explicit port
    # Protocol: tcp, Duration: $LEASE_DURATION seconds
    # NOTE: natpmpc must run on the HOST, not in the namespace
    local output
    output=$("${NATPMPC}" -a "$QBT_PORT" "$QBT_PORT" tcp "$LEASE_DURATION" -g "$VPN_GATEWAY" 2>&1)

    if echo "$output" | "${GREP}" -q "Mapped public port"; then
        # Extract public port from response
        local public_port
        public_port=$(echo "$output" | "${GREP}" "Mapped public port" | "${GREP}" -oP 'Mapped public port \K[0-9]+')

        if [[ -n "$public_port" && "$public_port" -gt 0 ]]; then
            log_success "NAT-PMP mapped public port $public_port to local port $QBT_PORT"

            # Save public port to state file for tracking/monitoring
            cat > "$PORTFORWARD_STATE" << STATEEOF
# ProtonVPN Port Forwarding State
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
PUBLIC_PORT=$public_port
PRIVATE_PORT=$QBT_PORT
NAMESPACE=$NAMESPACE
VPN_GATEWAY=$VPN_GATEWAY
STATEEOF
            chmod 644 "$PORTFORWARD_STATE"

            # Return the private port (qBittorrent should continue using configured port)
            echo "$QBT_PORT"
            return 0
        fi
    fi

    log_error "Failed to get port mapping from NAT-PMP"
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

    if "${IP}" netns exec "$NAMESPACE" ss -tuln | "${GREP}" -q ":${expected_port} "; then
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

    # Port is now managed by Nix configuration, not by this script
    # Just verify qBittorrent is listening on the configured port
    if verify_port "$PORT"; then
        log_info "Port mapping successful, qBittorrent is listening on $PORT"
    else
        # Not a fatal error - NAT-PMP mapping succeeded even if qBittorrent isn't listening yet
        log_info "qBittorrent not yet listening on $PORT (may be starting up)"
    fi

    log_success "Port forwarding setup complete! Using port: $PORT"
    echo "$PORT"  # Output port for scripts/automation
}

# Run main function
main "$@"
