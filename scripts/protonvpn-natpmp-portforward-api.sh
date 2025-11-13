#!/usr/bin/env bash
# ProtonVPN NAT-PMP Port Forwarding with qBittorrent API Integration
# Queries NAT-PMP for forwarded port and updates qBittorrent via WebUI API

set -euo pipefail

# Configuration (from environment or defaults)
NAMESPACE="${NAMESPACE:-qbt}"
VPN_GATEWAY="${VPN_GATEWAY:-10.2.0.1}"
LEASE_DURATION=3600  # seconds (60 minutes)
QBITTORRENT_HOST="${QBITTORRENT_HOST:-http://localhost:8080}"
QBITTORRENT_USERNAME="${QBITTORRENT_USERNAME:-}"
QBITTORRENT_PASSWORD="${QBITTORRENT_PASSWORD:-}"
PORTFORWARD_STATE="/var/lib/protonvpn-portforward.state"
LOG_PREFIX="[ProtonVPN-PortForward]"

# Tool paths
NATPMPC="${NATPMPC_BIN:-$(command -v natpmpc)}"
CURL="${CURL_BIN:-$(command -v curl)}"

# Logging
log_info() { echo "$LOG_PREFIX INFO: $*" >&2; }
log_error() { echo "$LOG_PREFIX ERROR: $*" >&2; }
log_success() { echo "$LOG_PREFIX SUCCESS: $*" >&2; }

# Query NAT-PMP for port forwarding
get_forwarded_port() {
    log_info "Querying NAT-PMP for port forwarding..."

    # Request port mapping for arbitrary port (ProtonVPN will assign one)
    # Use port 1 as internal port since ProtonVPN ignores it anyway
    local output
    output=$("${NATPMPC}" -a 1 0 tcp "$LEASE_DURATION" -g "$VPN_GATEWAY" 2>&1 || true)

    if echo "$output" | grep -q "Mapped public port"; then
        local public_port
        public_port=$(echo "$output" | grep "Mapped public port" | grep -oP 'Mapped public port \K[0-9]+')

        if [[ -n "$public_port" && "$public_port" -gt 0 ]]; then
            log_success "NAT-PMP assigned public port: $public_port"
            echo "$public_port"
            return 0
        fi
    fi

    log_error "Failed to get port mapping from NAT-PMP"
    log_error "Output: $output"
    return 1
}

# Get current qBittorrent port via API
get_qbittorrent_port() {
    local cookie="$1"

    local prefs
    prefs=$("${CURL}" -sS -b "SID=${cookie}" \
        --header "Referer: ${QBITTORRENT_HOST}" \
        "${QBITTORRENT_HOST}/api/v2/app/preferences" 2>&1 || echo "{}")

    if [[ "$prefs" == "{}" ]]; then
        log_error "Failed to get qBittorrent preferences"
        return 1
    fi

    local current_port
    current_port=$(echo "$prefs" | grep -oP '"listen_port":\K[0-9]+' || echo "0")

    if [[ "$current_port" -gt 0 ]]; then
        echo "$current_port"
        return 0
    fi

    return 1
}

# Login to qBittorrent WebUI
qbittorrent_login() {
    log_info "Logging in to qBittorrent WebUI..."

    local login_response
    login_response=$("${CURL}" -sS -i \
        --header "Referer: ${QBITTORRENT_HOST}" \
        --data-urlencode "username=${QBITTORRENT_USERNAME}" \
        --data-urlencode "password=${QBITTORRENT_PASSWORD}" \
        "${QBITTORRENT_HOST}/api/v2/auth/login" 2>&1 || echo "")

    local cookie
    cookie=$(echo "$login_response" | grep -ioE 'SID=[^;]+' | sed 's/SID=//i' || echo "")

    if [[ -n "$cookie" ]]; then
        log_success "Login successful"
        echo "$cookie"
        return 0
    fi

    log_error "Login failed - check credentials or 'Bypass authentication for clients on localhost'"
    return 1
}

# Update qBittorrent port via API
update_qbittorrent_port() {
    local port="$1"
    local cookie="$2"

    log_info "Updating qBittorrent listening port to $port via API..."

    local json_payload="{\"listen_port\": $port}"

    local response
    response=$("${CURL}" -sS \
        --cookie "SID=${cookie}" \
        --header "Referer: ${QBITTORRENT_HOST}" \
        --data-urlencode "json=${json_payload}" \
        "${QBITTORRENT_HOST}/api/v2/app/setPreferences" 2>&1 || echo "ERROR")

    # qBittorrent returns "Ok." or empty response on success
    if [[ "$response" == "Ok." ]] || [[ -z "$response" ]]; then
        log_success "qBittorrent port updated to $port"
        return 0
    fi

    log_error "Failed to update qBittorrent port. Response: $response"
    return 1
}

# Logout from qBittorrent
qbittorrent_logout() {
    local cookie="$1"

    "${CURL}" -sS -X POST \
        --cookie "SID=${cookie}" \
        --header "Referer: ${QBITTORRENT_HOST}" \
        "${QBITTORRENT_HOST}/api/v2/auth/logout" >/dev/null 2>&1 || true
}

# Save state
save_state() {
    local port="$1"

    cat > "$PORTFORWARD_STATE" << EOF
# ProtonVPN Port Forwarding State
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
PUBLIC_PORT=$port
NAMESPACE=$NAMESPACE
VPN_GATEWAY=$VPN_GATEWAY
EOF
    chmod 644 "$PORTFORWARD_STATE"
}

# Main execution
main() {
    log_info "Starting ProtonVPN NAT-PMP port forwarding automation"

    # Check for required credentials
    if [[ -z "$QBITTORRENT_USERNAME" ]] || [[ -z "$QBITTORRENT_PASSWORD" ]]; then
        log_error "QBITTORRENT_USERNAME and QBITTORRENT_PASSWORD must be set"
        exit 1
    fi

    # Get forwarded port from ProtonVPN
    FORWARDED_PORT=$(get_forwarded_port)
    if [[ -z "$FORWARDED_PORT" ]]; then
        log_error "Failed to get forwarded port from ProtonVPN"
        exit 1
    fi

    # Login to qBittorrent
    COOKIE=$(qbittorrent_login)
    if [[ -z "$COOKIE" ]]; then
        log_error "Failed to login to qBittorrent"
        exit 1
    fi

    # Get current qBittorrent port
    CURRENT_PORT=$(get_qbittorrent_port "$COOKIE" || echo "0")
    log_info "Current qBittorrent port: $CURRENT_PORT"
    log_info "ProtonVPN forwarded port: $FORWARDED_PORT"

    # Update port if different
    if [[ "$CURRENT_PORT" != "$FORWARDED_PORT" ]]; then
        log_info "Port mismatch detected - updating qBittorrent..."

        if update_qbittorrent_port "$FORWARDED_PORT" "$COOKIE"; then
            save_state "$FORWARDED_PORT"
            log_success "Port forwarding updated successfully!"
            log_info "qBittorrent is now using port: $FORWARDED_PORT"
        else
            qbittorrent_logout "$COOKIE"
            exit 1
        fi
    else
        log_info "Port already correct ($FORWARDED_PORT) - no update needed"
        save_state "$FORWARDED_PORT"
    fi

    # Logout
    qbittorrent_logout "$COOKIE"

    log_success "Port forwarding maintenance complete - port: $FORWARDED_PORT"
    echo "$FORWARDED_PORT"
}

main "$@"
