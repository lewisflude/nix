#!/usr/bin/env bash
# Update Transmission peer port using transmission-remote
# This is the ONLY safe way to update Transmission settings while running

set -euo pipefail

# Configuration
NAMESPACE="${NAMESPACE:-qbt}"
TRANSMISSION_HOST="${TRANSMISSION_HOST:-127.0.0.1:9091}"
TRANSMISSION_USERNAME="${TRANSMISSION_USERNAME:-}"
TRANSMISSION_PASSWORD="${TRANSMISSION_PASSWORD:-}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Show usage
usage() {
    cat << EOF
Usage: $0 <PORT> [OPTIONS]

Update Transmission peer port using transmission-remote (the safe way).

IMPORTANT:
  - NEVER edit settings.json while Transmission is running
  - Manual edits are overwritten when Transmission restarts
  - ALWAYS use transmission-remote for live configuration changes

Arguments:
  PORT                  New peer port (1024-65535)

Options:
  -h, --host HOST:PORT  Transmission RPC host (default: 127.0.0.1:9091)
  -u, --username USER   RPC username (required if auth enabled)
  -p, --password PASS   RPC password (required if auth enabled)
  -n, --namespace NS    Network namespace (default: qbt)
  --no-namespace        Don't use network namespace
  --help               Show this help message

Environment Variables:
  TRANSMISSION_HOST      Override default host
  TRANSMISSION_USERNAME  Override default username
  TRANSMISSION_PASSWORD  Override default password
  NAMESPACE             Override default namespace

Examples:
  # Update port in VPN namespace
  $0 55555 -u admin -p secret

  # Update port on remote host
  $0 64243 --host jupiter:9091 -u admin -p secret --no-namespace

  # Get current port
  $0 info -u admin -p secret

EOF
    exit 0
}

# Parse arguments
USE_NAMESPACE=true
NEW_PORT=""
SHOW_INFO=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--host)
            TRANSMISSION_HOST="$2"
            shift 2
            ;;
        -u|--username)
            TRANSMISSION_USERNAME="$2"
            shift 2
            ;;
        -p|--password)
            TRANSMISSION_PASSWORD="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --no-namespace)
            USE_NAMESPACE=false
            shift
            ;;
        --help)
            usage
            ;;
        info)
            SHOW_INFO=true
            shift
            ;;
        *)
            if [[ "$1" =~ ^[0-9]+$ ]]; then
                NEW_PORT="$1"
                shift
            else
                echo -e "${RED}Error: Invalid argument '$1'${NC}" >&2
                usage
            fi
            ;;
    esac
done

# Validate port if updating
if [[ "$SHOW_INFO" == false ]]; then
    if [[ -z "$NEW_PORT" ]]; then
        echo -e "${RED}Error: PORT argument is required${NC}" >&2
        usage
    fi

    if [[ "$NEW_PORT" -lt 1024 ]] || [[ "$NEW_PORT" -gt 65535 ]]; then
        echo -e "${RED}Error: Port must be between 1024 and 65535${NC}" >&2
        exit 1
    fi
fi

# Check if transmission-remote is available
if ! command -v transmission-remote &>/dev/null; then
    echo -e "${RED}Error: transmission-remote not found${NC}" >&2
    echo "Install Transmission: nix-shell -p transmission" >&2
    exit 1
fi

# Build transmission-remote command
build_cmd() {
    local cmd="transmission-remote ${TRANSMISSION_HOST}"

    # Add authentication if provided
    if [[ -n "$TRANSMISSION_USERNAME" ]] && [[ -n "$TRANSMISSION_PASSWORD" ]]; then
        cmd="${cmd} -n '${TRANSMISSION_USERNAME}:${TRANSMISSION_PASSWORD}'"
    fi

    # Add namespace execution if needed
    if [[ "$USE_NAMESPACE" == true ]]; then
        cmd="ip netns exec ${NAMESPACE} ${cmd}"
    fi

    echo "$cmd"
}

# Execute transmission-remote command
exec_cmd() {
    local args="$*"
    local base_cmd=$(build_cmd)
    local full_cmd="${base_cmd} ${args}"

    if [[ "$USE_NAMESPACE" == true ]]; then
        # Need to use sudo for namespace execution
        eval "sudo ${full_cmd}"
    else
        eval "${full_cmd}"
    fi
}

# Show session info
show_info() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Transmission Session Info${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    if exec_cmd -si; then
        echo ""
        echo -e "${GREEN}✓${NC} Successfully retrieved session info"
    else
        echo ""
        echo -e "${RED}✗${NC} Failed to retrieve session info"
        echo ""
        echo "Troubleshooting:"
        echo "  1. Check if Transmission is running: systemctl status transmission"
        echo "  2. Verify authentication credentials"
        echo "  3. Check network connectivity to ${TRANSMISSION_HOST}"
        return 1
    fi
}

# Update port
update_port() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Update Transmission Peer Port${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "Host:      ${TRANSMISSION_HOST}"
    echo -e "Namespace: ${NAMESPACE} ${USE_NAMESPACE:+(enabled)}"
    echo -e "New Port:  ${GREEN}${NEW_PORT}${NC}"
    echo ""

    # Get current port first
    echo -e "${BLUE}▶ Getting current port...${NC}"
    local current_port
    current_port=$(exec_cmd -si 2>/dev/null | grep "Peer port" | grep -oP '\d+' || echo "unknown")

    if [[ "$current_port" != "unknown" ]]; then
        echo -e "  Current port: ${current_port}"
    else
        echo -e "  ${YELLOW}⚠${NC} Could not determine current port"
    fi

    # Update port
    echo ""
    echo -e "${BLUE}▶ Updating port to ${NEW_PORT}...${NC}"

    if exec_cmd -p "${NEW_PORT}" 2>&1; then
        echo -e "  ${GREEN}✓${NC} Port update command sent successfully"

        # Verify the change
        echo ""
        echo -e "${BLUE}▶ Verifying port change...${NC}"
        sleep 2

        local new_port
        new_port=$(exec_cmd -si 2>/dev/null | grep "Peer port" | grep -oP '\d+' || echo "unknown")

        if [[ "$new_port" == "$NEW_PORT" ]]; then
            echo -e "  ${GREEN}✓${NC} Port successfully updated to ${NEW_PORT}"

            # Check if listening
            if [[ "$USE_NAMESPACE" == true ]]; then
                echo ""
                echo -e "${BLUE}▶ Checking if port is listening...${NC}"
                if sudo ip netns exec "${NAMESPACE}" ss -tuln 2>/dev/null | grep -q ":${NEW_PORT} "; then
                    echo -e "  ${GREEN}✓${NC} Port ${NEW_PORT} is listening"
                else
                    echo -e "  ${YELLOW}⚠${NC} Port ${NEW_PORT} not yet listening (may take a moment)"
                fi
            fi

            echo ""
            echo -e "${GREEN}✓ Success!${NC} Transmission is now using port ${NEW_PORT}"
            return 0
        else
            echo -e "  ${YELLOW}⚠${NC} Port verification returned: ${new_port}"
            echo -e "  ${YELLOW}⚠${NC} Expected: ${NEW_PORT}"
            echo ""
            echo "The port may have been updated, but verification failed."
            echo "Run '$0 info' to check current settings."
            return 1
        fi
    else
        echo -e "  ${RED}✗${NC} Failed to update port"
        echo ""
        echo "Troubleshooting:"
        echo "  1. Check if Transmission is running: systemctl status transmission"
        echo "  2. Verify authentication credentials"
        echo "  3. Check service logs: journalctl -u transmission -n 50"
        return 1
    fi
}

# Main execution
main() {
    # Show warning about manual edits
    echo ""
    echo -e "${YELLOW}⚠ IMPORTANT: Never edit settings.json while Transmission is running!${NC}"
    echo -e "${YELLOW}⚠ Manual edits are overwritten when Transmission restarts.${NC}"
    echo -e "${YELLOW}⚠ Always use transmission-remote for live configuration changes.${NC}"

    if [[ "$SHOW_INFO" == true ]]; then
        show_info
    else
        update_port
    fi

    echo ""
}

# Run main
main
