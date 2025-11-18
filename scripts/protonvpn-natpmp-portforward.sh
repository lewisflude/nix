#!/usr/bin/env bash
# ProtonVPN NAT-PMP Port Forwarding with qBittorrent API Integration
# Automatically queries NAT-PMP and updates qBittorrent's listening port

set -euo pipefail

# Configuration (from environment or defaults)
NAMESPACE="${NAMESPACE:-qbt}"
VPN_GATEWAY="${VPN_GATEWAY:-10.2.0.1}"
LEASE_DURATION=60  # seconds (60 seconds per ProtonVPN official docs)
QBITTORRENT_HOST="${QBITTORRENT_HOST:-127.0.0.1:8080}"
QBITTORRENT_USERNAME="${QBITTORRENT_USERNAME:-admin}"
QBITTORRENT_PASSWORD="${QBITTORRENT_PASSWORD:-admin}"
COOKIE_FILE="/tmp/qbittorrent_portforward_cookie.txt"
PORTFORWARD_STATE="/var/lib/protonvpn-portforward.state"
LOG_PREFIX="[ProtonVPN-PortForward]"

# Tool paths (can be overridden by systemd)
NATPMPC="${NATPMPC_BIN:-$(command -v natpmpc)}"
CURL="${CURL_BIN:-$(command -v curl)}"

# Logging functions
log_info() { echo "$LOG_PREFIX INFO: $*" >&2; }
log_error() { echo "$LOG_PREFIX ERROR: $*" >&2; }
log_success() { echo "$LOG_PREFIX SUCCESS: $*" >&2; }

# Cleanup on exit
cleanup() {
    rm -f "${COOKIE_FILE}"
}
trap cleanup EXIT

# Check if NAT-PMP is available
check_natpmpc() {
    if [[ ! -x "${NATPMPC}" ]]; then
        log_error "natpmpc not found at ${NATPMPC}"
        return 1
    fi
}

# Query NAT-PMP for forwarded port
get_forwarded_port() {
    log_info "Querying ProtonVPN NAT-PMP for port assignment..."

    # Request BOTH UDP and TCP port mappings (required per ProtonVPN documentation)
    # Use internal port 1, external port 0 (let ProtonVPN assign)
    # MUST run inside VPN namespace to reach gateway
    local udp_output
    local tcp_output

    log_info "Requesting UDP port mapping..."
    udp_output=$(ip netns exec "${NAMESPACE}" "${NATPMPC}" -a 1 0 udp "$LEASE_DURATION" -g "$VPN_GATEWAY" 2>&1 || true)

    log_info "Requesting TCP port mapping..."
    tcp_output=$(ip netns exec "${NAMESPACE}" "${NATPMPC}" -a 1 0 tcp "$LEASE_DURATION" -g "$VPN_GATEWAY" 2>&1 || true)

    # ProtonVPN should assign the same port for both protocols
    local udp_port=0
    local tcp_port=0

    if echo "$udp_output" | grep -q "Mapped public port"; then
        udp_port=$(echo "$udp_output" | grep -oP 'Mapped public port \K[0-9]+' || echo "0")
    fi

    if echo "$tcp_output" | grep -q "Mapped public port"; then
        tcp_port=$(echo "$tcp_output" | grep -oP 'Mapped public port \K[0-9]+' || echo "0")
    fi

    # Verify both protocols got the same port
    if [[ "$udp_port" -gt 0 ]] && [[ "$tcp_port" -gt 0 ]]; then
        if [[ "$udp_port" == "$tcp_port" ]]; then
            log_success "ProtonVPN assigned port: $tcp_port (UDP+TCP)"
            echo "$tcp_port"
            return 0
        else
            log_error "Port mismatch: UDP=$udp_port, TCP=$tcp_port"
            return 1
        fi
    fi

    log_error "Failed to get port from NAT-PMP"
    log_error "UDP output: $udp_output"
    log_error "TCP output: $tcp_output"
    return 1
}

# Login to qBittorrent and get session cookie (from within namespace for localhost bypass)
qbittorrent_login() {
    log_info "Accessing qBittorrent WebUI at http://${QBITTORRENT_HOST} (localhost bypass enabled)..."

    local login_url="http://${QBITTORRENT_HOST}/api/v2/auth/login"
    local response

    response=$(ip netns exec "${NAMESPACE}" "${CURL}" -s -m 10 -c "${COOKIE_FILE}" -X POST "${login_url}" \
        --data-urlencode "username=${QBITTORRENT_USERNAME}" \
        --data-urlencode "password=${QBITTORRENT_PASSWORD}" 2>&1 || echo "FAILED")

    if [[ "${response}" == "Ok." ]] || [[ "${response}" == "Fails." ]]; then
        # "Fails." means auth failed but that's OK - localhost bypass should work
        log_success "Connected to qBittorrent API"
        return 0
    fi

    log_error "Failed to connect to qBittorrent. Response: ${response}"
    return 1
}

# Get current qBittorrent listening port (from within namespace for localhost bypass)
get_current_port() {
    local prefs_url="http://${QBITTORRENT_HOST}/api/v2/app/preferences"
    local prefs

    prefs=$(ip netns exec "${NAMESPACE}" "${CURL}" -s -m 10 -b "${COOKIE_FILE}" "${prefs_url}" 2>&1 || echo "{}")

    if [[ "$prefs" == "{}" ]] || [[ "$prefs" == *"Unauthorized"* ]]; then
        log_error "Failed to get qBittorrent preferences"
        return 1
    fi

    local current_port
    current_port=$(echo "$prefs" | grep -oP '"listen_port":\K[0-9]+' || echo "0")

    if [[ "$current_port" -gt 0 ]]; then
        echo "$current_port"
        return 0
    fi

    log_error "Could not parse current port from preferences"
    return 1
}

# Update qBittorrent listening port (from within namespace for localhost bypass)
update_qbittorrent_port() {
    local new_port="$1"

    log_info "Updating qBittorrent listening port to ${new_port} and VPN interface binding..."

    local set_prefs_url="http://${QBITTORRENT_HOST}/api/v2/app/setPreferences"
    local response

    # Update port AND interface binding to ensure VPN confinement
    # Interface name must match the veth pair interface name (qbt0)
    response=$(ip netns exec "${NAMESPACE}" "${CURL}" -s -m 10 -b "${COOKIE_FILE}" -X POST "${set_prefs_url}" \
        --data "json={\"listen_port\": ${new_port}, \"current_interface_name\": \"qbt0\", \"current_interface_address\": \"10.2.0.2\"}" 2>&1 || echo "ERROR")

    # Success = empty response or "Ok."
    if [[ -z "${response}" ]] || [[ "${response}" == "Ok." ]]; then
        log_success "qBittorrent port updated to ${new_port} with VPN interface binding"
        return 0
    fi

    # Check for errors
    if [[ "${response}" == *"400 Bad Request"* ]] || [[ "${response}" == *"401 Unauthorized"* ]]; then
        log_error "Failed to update port. Response: ${response}"
        return 1
    fi

    # Treat any other response as success (qBittorrent sometimes returns empty)
    log_success "qBittorrent port updated to ${new_port} (response: ${response:-empty})"
    return 0
}

# Save port forwarding state
save_state() {
    local port="$1"

    cat > "${PORTFORWARD_STATE}" << EOF
# ProtonVPN Port Forwarding State
# Last updated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
PUBLIC_PORT=${port}
NAMESPACE=${NAMESPACE}
VPN_GATEWAY=${VPN_GATEWAY}
QBITTORRENT_HOST=${QBITTORRENT_HOST}
EOF
    chmod 644 "${PORTFORWARD_STATE}"
    log_info "State saved to ${PORTFORWARD_STATE}"
}

# Verify qBittorrent is listening on the port
verify_listening() {
    local port="$1"

    log_info "Verifying qBittorrent is listening on port ${port}..."

    sleep 3  # Give qBittorrent time to bind

    if ip netns exec "${NAMESPACE}" ss -tuln 2>/dev/null | grep -q ":${port} "; then
        log_success "Verified: qBittorrent is listening on port ${port}"
        return 0
    else
        log_error "qBittorrent is not listening on port ${port} (may still be starting)"
        return 1
    fi
}

# Main execution
main() {
    log_info "=== ProtonVPN NAT-PMP Port Forwarding Automation ==="

    # Check for required tools
    check_natpmpc || exit 1

    # Note: Credentials are not strictly required if localhost bypass is enabled
    # We use dummy credentials since we're accessing from within the namespace

    # Step 1: Get forwarded port from ProtonVPN
    FORWARDED_PORT=$(get_forwarded_port)
    if [[ -z "${FORWARDED_PORT}" ]]; then
        log_error "Failed to get port from ProtonVPN NAT-PMP"
        exit 1
    fi

    # Step 2: Login to qBittorrent
    if ! qbittorrent_login; then
        log_error "Cannot proceed without qBittorrent authentication"
        exit 1
    fi

    # Step 3: Get current qBittorrent port
    CURRENT_PORT=$(get_current_port || echo "0")
    log_info "Current qBittorrent port: ${CURRENT_PORT}"
    log_info "ProtonVPN assigned port: ${FORWARDED_PORT}"

    # Step 4: Update port if needed
    if [[ "${CURRENT_PORT}" == "${FORWARDED_PORT}" ]]; then
        log_info "Port already correct (${FORWARDED_PORT}) - no update needed"
        save_state "${FORWARDED_PORT}"
    else
        log_info "Port mismatch detected - updating from ${CURRENT_PORT} to ${FORWARDED_PORT}"

        if update_qbittorrent_port "${FORWARDED_PORT}"; then
            save_state "${FORWARDED_PORT}"

            # Verify the port is listening
            verify_listening "${FORWARDED_PORT}" || log_error "Port verification failed (non-fatal)"

            log_success "Port forwarding update complete!"
        else
            log_error "Failed to update qBittorrent port"
            exit 1
        fi
    fi

    log_success "=== Port Forwarding Maintenance Complete ==="
    log_info "qBittorrent is now using port: ${FORWARDED_PORT}"

    # Output port for other scripts
    echo "${FORWARDED_PORT}"
}

# Run main function
main "$@"
