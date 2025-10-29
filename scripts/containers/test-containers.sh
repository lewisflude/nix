#!/usr/bin/env bash
# Comprehensive test script for NixOS container services
# Tests Podman installation, containers, networks, and services

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

FAILED_TESTS=0
PASSED_TESTS=0

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[✓]${NC} $1"
    ((PASSED_TESTS++))
}

log_fail() {
    echo -e "${RED}[✗]${NC} $1"
    ((FAILED_TESTS++))
}

log_warn() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_info() {
    echo -e "${BLUE}[ℹ]${NC} $1"
}

print_header() {
    echo ""
    echo "╔════════════════════════════════════════════╗"
    echo "║  NixOS Container Services Test Suite      ║"
    echo "╔════════════════════════════════════════════╗"
    echo ""
}

print_summary() {
    echo ""
    echo "╔════════════════════════════════════════════╗"
    echo "║  Test Summary                              ║"
    echo "╚════════════════════════════════════════════╝"
    echo ""
    echo -e "  Passed: ${GREEN}${PASSED_TESTS}${NC}"
    echo -e "  Failed: ${RED}${FAILED_TESTS}${NC}"
    echo ""
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        return 1
    fi
}

# Test 1: Podman Installation
test_podman_installed() {
    log_test "Checking Podman installation..."
    
    if command -v podman &> /dev/null; then
        local version=$(podman --version)
        log_pass "Podman is installed: $version"
    else
        log_fail "Podman is not installed"
    fi
}

# Test 2: Podman Service
test_podman_service() {
    log_test "Checking Podman socket..."
    
    if [ -S "/run/podman/podman.sock" ]; then
        log_pass "Podman socket exists"
    else
        log_warn "Podman socket not found (this is OK for rootless)"
    fi
}

# Test 3: Container Services
test_container_services() {
    log_test "Checking container systemd services..."
    
    local services=$(systemctl list-units 'podman-*' --no-legend | wc -l)
    
    if [ "$services" -gt 0 ]; then
        log_pass "Found $services container services"
        
        # List running services
        log_info "Running services:"
        systemctl list-units 'podman-*' --no-legend --state=running | while read -r line; do
            local service=$(echo "$line" | awk '{print $1}')
            echo "    - $service"
        done
    else
        log_warn "No container services found (containers may not be enabled yet)"
    fi
}

# Test 4: Running Containers
test_running_containers() {
    log_test "Checking running containers..."
    
    if ! command -v podman &> /dev/null; then
        log_warn "Skipping - Podman not installed"
        return
    fi
    
    local running=$(podman ps --format "{{.Names}}" 2>/dev/null | wc -l)
    
    if [ "$running" -gt 0 ]; then
        log_pass "$running containers are running"
        
        log_info "Running containers:"
        podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null | tail -n +2 | while read -r line; do
            echo "    $line"
        done
    else
        log_warn "No containers are running (this is OK if not enabled yet)"
    fi
}

# Test 5: Networks
test_networks() {
    log_test "Checking Podman networks..."
    
    if ! command -v podman &> /dev/null; then
        log_warn "Skipping - Podman not installed"
        return
    fi
    
    local networks=$(podman network ls --format "{{.Name}}" 2>/dev/null)
    
    if [ -n "$networks" ]; then
        log_pass "Podman networks exist"
        
        log_info "Available networks:"
        echo "$networks" | while read -r net; do
            echo "    - $net"
        done
        
        # Check for expected networks
        if echo "$networks" | grep -q "media"; then
            log_pass "Media network exists"
        fi
        
        if echo "$networks" | grep -q "frontend"; then
            log_pass "Frontend network exists"
        fi
    else
        log_warn "No networks found (will be created when containers start)"
    fi
}

# Test 6: Service Endpoints
test_service_endpoints() {
    log_test "Testing service endpoints..."
    
    # Define services to test (name:port)
    local services=(
        "prowlarr:9696"
        "radarr:7878"
        "sonarr:8989"
        "lidarr:8686"
        "qbittorrent:8080"
        "sabnzbd:8082"
        "jellyfin:8096"
        "jellyseerr:5055"
        "openwebui:7000"
        "comfyui-nvidia:8188"
    )
    
    local any_tested=false
    
    for service in "${services[@]}"; do
        local name="${service%%:*}"
        local port="${service##*:}"
        
        # Check if service is running
        if systemctl is-active --quiet "podman-$name" 2>/dev/null; then
            any_tested=true
            
            # Test HTTP endpoint
            if curl -sf --max-time 2 "http://localhost:$port" > /dev/null 2>&1; then
                log_pass "$name responding on port $port"
            else
                log_warn "$name is running but not yet responding on port $port (may still be starting)"
            fi
        fi
    done
    
    if [ "$any_tested" = false ]; then
        log_info "No services are running to test endpoints"
    fi
}

# Test 7: GPU Support (if applicable)
test_gpu_support() {
    log_test "Checking GPU support..."
    
    if command -v nvidia-smi &> /dev/null; then
        if nvidia-smi > /dev/null 2>&1; then
            log_pass "NVIDIA GPU detected and working"
            
            # Test container toolkit
            if command -v nvidia-container-cli &> /dev/null; then
                log_pass "NVIDIA Container Toolkit is available"
            else
                log_warn "NVIDIA Container Toolkit not found"
            fi
        else
            log_warn "nvidia-smi found but not working properly"
        fi
    else
        log_info "No GPU detected (not required for media stack)"
    fi
}

# Test 8: Container Logs
test_container_logs() {
    log_test "Checking container logs..."
    
    # Check if we can read logs from at least one service
    local any_checked=false
    
    for service in podman-prowlarr podman-radarr podman-test-nginx; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            any_checked=true
            
            local log_count=$(journalctl -u "$service" --no-pager -n 5 2>/dev/null | wc -l)
            
            if [ "$log_count" -gt 0 ]; then
                log_pass "Can read logs from $service"
                break
            fi
        fi
    done
    
    if [ "$any_checked" = false ]; then
        log_info "No services running to check logs"
    fi
}

# Test 9: Configuration Directories
test_config_directories() {
    log_test "Checking configuration directories..."
    
    local configs=(
        "/var/lib/containers/media-management"
        "/var/lib/containers/productivity"
    )
    
    local any_exist=false
    
    for dir in "${configs[@]}"; do
        if [ -d "$dir" ]; then
            any_exist=true
            log_pass "Configuration directory exists: $dir"
            
            # Check permissions
            local perms=$(stat -c "%a" "$dir" 2>/dev/null || echo "unknown")
            log_info "  Permissions: $perms"
        fi
    done
    
    if [ "$any_exist" = false ]; then
        log_info "No configuration directories found yet (created on first run)"
    fi
}

# Test 10: Volume Mounts
test_volume_mounts() {
    log_test "Checking volume mounts..."
    
    if ! command -v podman &> /dev/null; then
        log_warn "Skipping - Podman not installed"
        return
    fi
    
    # Check if any containers have volumes mounted
    local containers=$(podman ps --format "{{.Names}}" 2>/dev/null)
    
    if [ -n "$containers" ]; then
        local any_checked=false
        
        echo "$containers" | head -3 | while read -r container; do
            local mounts=$(podman inspect "$container" --format '{{range .Mounts}}{{.Source}}{{"\n"}}{{end}}' 2>/dev/null | head -1)
            
            if [ -n "$mounts" ]; then
                any_checked=true
                log_pass "Container $container has volumes mounted"
            fi
        done
    else
        log_info "No containers running to check mounts"
    fi
}

# Main test execution
main() {
    print_header
    
    log_info "Starting test suite..."
    echo ""
    
    test_podman_installed
    test_podman_service
    test_container_services
    test_running_containers
    test_networks
    test_service_endpoints
    test_gpu_support
    test_container_logs
    test_config_directories
    test_volume_mounts
    
    print_summary
}

# Run tests
main "$@"
