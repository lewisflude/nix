#!/usr/bin/env bash
# Gaming Setup Diagnostic Script
# Validates that all gaming optimizations and configurations are properly applied

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

print_header() {
  echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

check_pass() {
  echo -e "${GREEN}✓${NC} $1"
  ((PASSED++))
}

check_fail() {
  echo -e "${RED}✗${NC} $1"
  ((FAILED++))
}

check_warn() {
  echo -e "${YELLOW}⚠${NC} $1"
  ((WARNINGS++))
}

print_header "Gaming Setup Diagnostic"

# Check if Steam is installed
print_header "Steam Installation"
if command -v steam &> /dev/null; then
  check_pass "Steam is installed"
  
  # Check Steam dev config
  if [ -f "$HOME/.steam/steam/steam_dev.cfg" ]; then
    check_pass "Steam dev config exists"
    
    # Check shader compilation setting
    if grep -q "unShaderBackgroundProcessingThreads" "$HOME/.steam/steam/steam_dev.cfg"; then
      THREADS=$(grep "unShaderBackgroundProcessingThreads" "$HOME/.steam/steam/steam_dev.cfg" | awk '{print $2}')
      check_pass "Multi-core shader compilation enabled (${THREADS} threads)"
    else
      check_warn "Multi-core shader compilation not configured"
    fi
    
    # Check HTTP2 setting
    if grep -q "@nClientDownloadEnableHTTP2PlatformLinux 0" "$HOME/.steam/steam/steam_dev.cfg"; then
      check_pass "HTTP2 disabled for potentially faster downloads"
    else
      check_warn "HTTP2 not disabled (may be fine for your network)"
    fi
  else
    check_warn "Steam dev config not found (will be created on first Steam launch)"
  fi
else
  check_fail "Steam is not installed"
fi

# Check vm.max_map_count
print_header "Kernel Parameters"
VM_MAX_MAP=$(sysctl -n vm.max_map_count 2>/dev/null || echo "0")
if [ "$VM_MAX_MAP" -ge 2000000 ]; then
  check_pass "vm.max_map_count is set correctly ($VM_MAX_MAP)"
else
  check_fail "vm.max_map_count is too low ($VM_MAX_MAP, should be 2147483642)"
fi

# Check CPU governor
print_header "CPU Performance"
GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
if [ "$GOVERNOR" = "performance" ]; then
  check_pass "CPU governor is set to 'performance'"
else
  check_warn "CPU governor is '$GOVERNOR' (consider 'performance' for gaming)"
fi

# Check irqbalance status
if systemctl is-enabled irqbalance &> /dev/null; then
  check_warn "irqbalance is enabled (known to cause stuttering in games)"
else
  check_pass "irqbalance is disabled (correct for gaming)"
fi

# Check file descriptor limit
print_header "System Limits"
FD_LIMIT=$(ulimit -n)
if [ "$FD_LIMIT" -ge 524288 ]; then
  check_pass "File descriptor limit is high enough ($FD_LIMIT) for ESYNC"
else
  check_warn "File descriptor limit is $FD_LIMIT (should be 524288+ for ESYNC)"
fi

# Check gamemode
print_header "Gaming Software"
if command -v gamemoded &> /dev/null; then
  check_pass "GameMode is installed"
  if systemctl --user is-active gamemode &> /dev/null; then
    check_pass "GameMode daemon is running"
  else
    check_warn "GameMode daemon is not running (starts automatically with games)"
  fi
else
  check_fail "GameMode is not installed"
fi

# Check ananicy-cpp
if systemctl is-active ananicy-cpp &> /dev/null; then
  check_pass "Ananicy-cpp is running (process prioritization active)"
else
  check_warn "Ananicy-cpp is not running"
fi

# Check gamescope
if command -v gamescope &> /dev/null; then
  check_pass "Gamescope is installed"
else
  check_warn "Gamescope is not installed (optional)"
fi

# Check uinput access
print_header "Steam Input"
if [ -e /dev/uinput ]; then
  check_pass "/dev/uinput exists"
  
  # Check if user is in steam group
  if groups | grep -q steam; then
    check_pass "User is in 'steam' group (can access uinput)"
  else
    check_fail "User is not in 'steam' group (Steam Input may not work)"
  fi
  
  # Check uinput permissions
  UINPUT_GROUP=$(stat -c '%G' /dev/uinput)
  if [ "$UINPUT_GROUP" = "steam" ]; then
    check_pass "uinput device restricted to 'steam' group (secure configuration)"
  else
    check_warn "uinput device has group '$UINPUT_GROUP' (may allow broader access)"
  fi
else
  check_fail "/dev/uinput does not exist (Steam Input will not work)"
fi

# Check graphics drivers
print_header "Graphics"
if command -v vulkaninfo &> /dev/null; then
  check_pass "Vulkan tools are installed"
  
  # Check for Vulkan ICD
  if vulkaninfo --summary &> /dev/null; then
    VULKAN_GPU=$(vulkaninfo --summary 2>/dev/null | grep "GPU id" | head -1 | cut -d: -f2 | xargs)
    check_pass "Vulkan is working (GPU: $VULKAN_GPU)"
  else
    check_fail "Vulkan is not working correctly"
  fi
else
  check_warn "Vulkan tools not installed (install mesa-demos or vulkan-tools)"
fi

# Check PCIe Resizable BAR
print_header "PCIe Resizable BAR"
REBAR_INFO=$(sudo dmesg 2>/dev/null | grep -i "BAR=" | head -1)
if [ -n "$REBAR_INFO" ]; then
  # Extract VRAM and BAR sizes
  VRAM_SIZE=$(echo "$REBAR_INFO" | grep -oP 'VRAM RAM=\K[0-9]+' || echo "unknown")
  BAR_SIZE=$(echo "$REBAR_INFO" | grep -oP 'BAR=\K[0-9]+' || echo "unknown")
  
  if [ "$VRAM_SIZE" != "unknown" ] && [ "$BAR_SIZE" != "unknown" ]; then
    if [ "$BAR_SIZE" -ge "$((VRAM_SIZE - 256))" ]; then
      check_pass "Resizable BAR is enabled (BAR=${BAR_SIZE}M, VRAM=${VRAM_SIZE}M)"
    else
      check_warn "Resizable BAR is NOT enabled (BAR=${BAR_SIZE}M, VRAM=${VRAM_SIZE}M)"
      echo "       Enable 'Above 4G Decode' or 'Resizable BAR' in BIOS for 10-20% better performance"
      echo "       Note: CSM/Legacy boot must be disabled"
    fi
  else
    check_warn "Could not parse Resizable BAR status from dmesg"
  fi
else
  check_warn "No Resizable BAR info found (AMD GPU required, or check 'sudo dmesg | grep BAR=')"
fi

# Check WiFi regulatory domain
WIFI_REGDOM=$(cat /sys/module/cfg80211/parameters/ieee80211_regdom 2>/dev/null || echo "")
if [ -n "$WIFI_REGDOM" ]; then
  if [ "$WIFI_REGDOM" = "00" ]; then
    check_warn "WiFi regulatory domain is '00' (restrictive global default)"
    echo "       Set cfg80211.ieee80211_regdom=GB (or your country) in kernel params for better WiFi"
  else
    check_pass "WiFi regulatory domain is set to '$WIFI_REGDOM'"
  fi
fi

# Check Proton-GE
print_header "Proton Compatibility"
if [ -d "$HOME/.steam/root/compatibilitytools.d" ]; then
  PROTON_GE_COUNT=$(find "$HOME/.steam/root/compatibilitytools.d" -name "GE-Proton*" -type d 2>/dev/null | wc -l)
  if [ "$PROTON_GE_COUNT" -gt 0 ]; then
    check_pass "Proton-GE is installed ($PROTON_GE_COUNT versions found)"
  else
    check_warn "Proton-GE not found in compatibilitytools.d"
  fi
else
  check_warn "Steam compatibility tools directory not found (install Proton-GE via protonup-qt)"
fi

# Check MangoHud
if command -v mangohud &> /dev/null; then
  check_pass "MangoHud is installed"
else
  check_warn "MangoHud not installed (useful for FPS monitoring)"
fi

# Network optimizations
print_header "Network Configuration"
TCP_CONGESTION=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "unknown")
if [ "$TCP_CONGESTION" = "bbr" ]; then
  check_pass "TCP BBR congestion control is enabled"
else
  check_warn "TCP congestion control is '$TCP_CONGESTION' (BBR recommended)"
fi

# Check for security hardening that may break games
print_header "Security Checks"
if grep -q "hidepid=" /proc/mounts 2>/dev/null; then
  check_warn "hidepid is enabled (may break Easy Anti-Cheat)"
else
  check_pass "hidepid is not enabled (good for gaming)"
fi

# Summary
print_header "Summary"
TOTAL=$((PASSED + FAILED + WARNINGS))
echo "Total checks: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

echo ""
if [ $FAILED -gt 0 ]; then
  echo -e "${RED}Some critical checks failed. Gaming experience may be suboptimal.${NC}"
  echo "See docs/STEAM_GAMING_GUIDE.md for troubleshooting."
  exit 1
elif [ $WARNINGS -gt 0 ]; then
  echo -e "${YELLOW}Some warnings detected. Gaming should work but may not be optimal.${NC}"
  echo "See docs/STEAM_GAMING_GUIDE.md for optimization tips."
  exit 0
else
  echo -e "${GREEN}All checks passed! Gaming setup is optimal.${NC}"
  exit 0
fi
