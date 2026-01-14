#!/usr/bin/env bash
# Audio Configuration Diagnostic Script
# Checks PipeWire, WirePlumber, and system audio configuration
# Usage: ./diagnose-audio-config.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_error "Command '$1' not found"
        return 1
    fi
    return 0
}

# Check required commands
print_header "Checking Required Commands"
REQUIRED_CMDS=("pw-cli" "wpctl" "pactl" "systemctl" "cat" "grep")
for cmd in "${REQUIRED_CMDS[@]}"; do
    if check_command "$cmd"; then
        print_success "$cmd found"
    else
        print_error "$cmd not found - some checks will be skipped"
    fi
done

# PipeWire Status
print_header "PipeWire Service Status"
if systemctl --user is-active pipewire &> /dev/null; then
    print_success "PipeWire service is running"
else
    print_error "PipeWire service is NOT running"
fi

if systemctl --user is-active pipewire-pulse &> /dev/null; then
    print_success "PipeWire-Pulse service is running"
else
    print_error "PipeWire-Pulse service is NOT running"
fi

if systemctl --user is-active wireplumber &> /dev/null; then
    print_success "WirePlumber service is running"
else
    print_error "WirePlumber service is NOT running"
fi

# PipeWire Version
print_header "PipeWire Version"
if check_command "pw-cli"; then
    PW_VERSION=$(pw-cli --version 2>&1 | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "unknown")
    print_info "PipeWire version: $PW_VERSION"

    # Check if ALSA sequencer fix is available
    if [[ "$PW_VERSION" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        major="${BASH_REMATCH[1]}"
        minor="${BASH_REMATCH[2]}"
        patch="${BASH_REMATCH[3]}"

        if [ "$major" -ge 1 ] && [ "$minor" -ge 4 ] && [ "$patch" -ge 10 ]; then
            print_success "ALSA sequencer crash fix available (>=1.4.10)"
            print_info "Consider removing ALSA sequencer kernel module blacklist"
        else
            print_warning "ALSA sequencer crash present (<1.4.10)"
            print_info "Kernel module blacklist should remain in place"
        fi
    fi
fi

# Current Quantum/Latency Settings
print_header "PipeWire Latency Configuration"
if check_command "pw-cli"; then
    echo -e "${BLUE}Current settings:${NC}"
    pw-cli info 0 | grep -E "default.clock.(rate|quantum|min-quantum|max-quantum)" || print_warning "Could not retrieve quantum settings"
fi

# Active Audio Devices
print_header "Active Audio Devices"
if check_command "wpctl"; then
    echo -e "${BLUE}Sinks (outputs):${NC}"
    wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep -v "Sources:" | tail -n +2

    echo -e "\n${BLUE}Sources (inputs):${NC}"
    wpctl status | sed -n '/Sources:/,/Sink endpoints:/p' | grep -v "Sink endpoints:" | tail -n +2
fi

# Check for Apogee Device
print_header "Apogee Symphony Desktop Detection"
if check_command "wpctl"; then
    if wpctl status | grep -i "apogee" &> /dev/null; then
        print_success "Apogee device detected"
        wpctl status | grep -i "apogee"
    else
        print_warning "Apogee device NOT detected"
        print_info "Check USB connection and device power"
    fi
fi

# Check Gaming Bridge
print_header "Gaming Audio Bridge Status"
if check_command "pw-cli"; then
    if pw-cli list-objects | grep -i "apogee_stereo_game_bridge" &> /dev/null; then
        print_success "Gaming bridge is active"
    else
        print_warning "Gaming bridge NOT found"
        print_info "This is normal if Apogee is disconnected"
    fi
fi

# Check Sunshine Virtual Sink
print_header "Sunshine Virtual Sink Status"
if check_command "pw-cli"; then
    if pw-cli list-objects | grep -i "sunshine" &> /dev/null; then
        print_success "Sunshine virtual sink is active"
    else
        print_info "Sunshine virtual sink not found (normal when not streaming)"
    fi
fi

# CPU Governor
print_header "CPU Frequency Governor"
if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
    GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
    print_info "Current governor: $GOVERNOR"

    case "$GOVERNOR" in
        "performance")
            print_warning "Performance mode active (high power usage)"
            print_info "Consider 'schedutil' for better efficiency"
            ;;
        "schedutil")
            print_success "Schedutil active (balanced performance/efficiency)"
            ;;
        "powersave")
            print_warning "Powersave mode may cause audio dropouts"
            ;;
        *)
            print_info "Governor: $GOVERNOR"
            ;;
    esac
else
    print_warning "Could not read CPU governor"
fi

# USB Power Management (Apogee)
print_header "USB Audio Power Management"
print_info "Checking USB autosuspend for Apogee (Vendor ID: 0a07)..."

APOGEE_FOUND=false
for usbdev in /sys/bus/usb/devices/*; do
    if [ -f "$usbdev/idVendor" ]; then
        VENDOR=$(cat "$usbdev/idVendor" 2>/dev/null || echo "")
        if [ "$VENDOR" = "0a07" ]; then
            APOGEE_FOUND=true
            DEVICE=$(basename "$usbdev")
            POWER_CONTROL=$(cat "$usbdev/power/control" 2>/dev/null || echo "unknown")
            AUTOSUSPEND=$(cat "$usbdev/power/autosuspend" 2>/dev/null || echo "unknown")

            print_info "Device: $DEVICE"
            print_info "  Power control: $POWER_CONTROL"
            print_info "  Autosuspend: $AUTOSUSPEND"

            if [ "$POWER_CONTROL" = "on" ]; then
                print_success "USB autosuspend disabled (correct)"
            else
                print_error "USB autosuspend NOT disabled (may cause dropouts)"
            fi
        fi
    fi
done

if [ "$APOGEE_FOUND" = false ]; then
    print_warning "Apogee device not found on USB bus"
fi

# ALSA Sequencer Kernel Modules
print_header "ALSA Sequencer Kernel Modules"
ALSA_SEQ_MODULES=("snd_seq" "snd_seq_dummy" "snd_seq_midi" "snd_seq_midi_event")
for module in "${ALSA_SEQ_MODULES[@]}"; do
    if lsmod | grep -q "^$module"; then
        print_error "$module is loaded (should be blacklisted)"
    else
        print_success "$module is NOT loaded (correct)"
    fi
done

# Real-time Priority
print_header "Real-time Audio Priorities"
if check_command "ps"; then
    echo -e "${BLUE}PipeWire processes:${NC}"
    ps -eo pid,rtprio,cmd | grep -E "pipewire|wireplumber" | grep -v grep || print_warning "No PipeWire processes found"
fi

# Check for XRuns (buffer underruns)
print_header "Recent Audio Issues (journalctl)"
print_info "Checking for recent PipeWire errors..."
if check_command "journalctl"; then
    ERRORS=$(journalctl --user -u pipewire.service -u wireplumber.service --since "1 hour ago" --no-pager | grep -iE "error|failed|xrun|underrun|dropout" | wc -l)

    if [ "$ERRORS" -eq 0 ]; then
        print_success "No errors in the last hour"
    else
        print_warning "Found $ERRORS error/warning messages in the last hour"
        print_info "Run: journalctl --user -u pipewire.service -u wireplumber.service --since '1 hour ago' | grep -i error"
    fi
fi

# Summary
print_header "Summary"
echo -e "${BLUE}Configuration recommendations:${NC}"
echo ""
echo "1. ${GREEN}Optimal latency:${NC} 256 frames (~5.3ms) for daily use with XanMod kernel"
echo "2. ${GREEN}CPU governor:${NC} 'schedutil' for balanced performance/efficiency"
echo "3. ${GREEN}USB power:${NC} Ensure Apogee autosuspend is disabled via udev rules"
echo "4. ${GREEN}Gaming:${NC} Use Sunshine virtual sink when streaming, bridge for local gaming"
echo ""
echo -e "${YELLOW}For ultra-low latency recording (64 frames):${NC}"
echo "  - Enable realtime=true in host config"
echo "  - Use RT kernel (musnix)"
echo "  - Set CPU governor to 'performance'"
echo ""
echo -e "${CYAN}Diagnostic complete!${NC}"
