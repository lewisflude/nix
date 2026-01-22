#!/usr/bin/env bash
# Audio Configuration Diagnostic Tool
# Verifies PipeWire, WirePlumber, and audio optimizations based on Arch Wiki recommendations
# Tests: sample rates, resample quality, memlock limits, suspension, Bluetooth codecs

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Header
print_header() {
    echo -e "${BOLD}${CYAN}========================================${NC}"
    echo -e "${BOLD}${CYAN}   PipeWire Audio Configuration Check${NC}"
    echo -e "${BOLD}${CYAN}========================================${NC}\n"
}

# Section headers
print_section() {
    echo -e "\n${BOLD}${BLUE}▶ $1${NC}"
    echo -e "${BLUE}$(printf '─%.0s' {1..50})${NC}"
}

# Test result indicators
print_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

print_fail() {
    echo -e "${RED}✗${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# Error counter
ERRORS=0
WARNINGS=0

# Check if PipeWire is running
check_pipewire_running() {
    print_section "PipeWire Service Status"
    
    if systemctl --user is-active --quiet pipewire.service; then
        print_pass "pipewire.service is running"
    else
        print_fail "pipewire.service is NOT running"
        ((ERRORS++))
    fi
    
    if systemctl --user is-active --quiet pipewire-pulse.service; then
        print_pass "pipewire-pulse.service is running"
    else
        print_fail "pipewire-pulse.service is NOT running"
        ((ERRORS++))
    fi
    
    if systemctl --user is-active --quiet wireplumber.service; then
        print_pass "wireplumber.service is running"
    else
        print_fail "wireplumber.service is NOT running"
        ((ERRORS++))
    fi
}

# Check dynamic sample rate configuration
check_sample_rates() {
    print_section "Dynamic Sample Rate Configuration"
    
    local config_check=$(pw-metadata -n settings 2>/dev/null | grep -i "clock.allowed-rates" || echo "")
    
    if [[ -n "$config_check" ]]; then
        print_pass "Allowed sample rates configured:"
        echo -e "   ${CYAN}$config_check${NC}"
        
        # Check if it includes common rates
        if echo "$config_check" | grep -q "44100" && echo "$config_check" | grep -q "192000"; then
            print_pass "Includes CD quality (44.1kHz) and high-res (192kHz) rates"
        else
            print_warn "May be missing important sample rates"
            ((WARNINGS++))
        fi
    else
        print_fail "Allowed sample rates not configured - will resample everything"
        ((ERRORS++))
    fi
    
    # Show current active sample rate
    print_info "Current active sample rates per card:"
    if compgen -G "/proc/asound/card*/pcm*/sub*/hw_params" > /dev/null; then
        grep -H "rate:" /proc/asound/card*/pcm*/sub*/hw_params 2>/dev/null | while read -r line; do
            echo -e "   ${CYAN}$line${NC}"
        done
    else
        print_info "No active audio streams"
    fi
}

# Check resample quality
check_resample_quality() {
    print_section "Resampling Quality Configuration"
    
    local quality=$(pw-metadata -n settings 2>/dev/null | grep -i "resample.quality" | tail -1 || echo "")
    
    if [[ -n "$quality" ]]; then
        local quality_num=$(echo "$quality" | grep -oP '\d+' | head -1)
        print_info "Resample quality: $quality"
        
        if [[ "$quality_num" -ge 10 ]]; then
            print_pass "High quality resampling configured (≥10)"
        elif [[ "$quality_num" -ge 4 ]]; then
            print_warn "Medium quality resampling (4-9) - consider increasing to 10"
            ((WARNINGS++))
        else
            print_fail "Low quality resampling (<4) - should increase"
            ((ERRORS++))
        fi
    else
        print_warn "Resample quality not explicitly configured"
        ((WARNINGS++))
    fi
}

# Check memlock limits
check_memlock() {
    print_section "Memory Locking (RLIMIT_MEMLOCK)"
    
    local memlock_soft=$(ulimit -l)
    
    if [[ "$memlock_soft" == "unlimited" ]]; then
        print_pass "Memlock limit is unlimited"
    elif [[ "$memlock_soft" -ge 128 ]]; then
        print_warn "Memlock limit is $memlock_soft kB (sufficient but not optimal)"
        ((WARNINGS++))
    else
        print_fail "Memlock limit is only $memlock_soft kB (may cause 'Failed to mlock' warnings)"
        ((ERRORS++))
    fi
    
    # Check if user is in audio group
    if groups | grep -q '\baudio\b'; then
        print_pass "User is in 'audio' group"
    else
        print_fail "User is NOT in 'audio' group - enhanced limits not active"
        print_info "Add yourself to audio group and re-login"
        ((ERRORS++))
    fi
    
    # Check PAM limits configuration
    if [[ -f /etc/security/limits.conf ]] || [[ -d /etc/security/limits.d ]]; then
        if grep -r "@audio.*memlock" /etc/security/limits.conf /etc/security/limits.d/ 2>/dev/null | grep -q "unlimited\|^[^#]*@audio"; then
            print_pass "PAM limits configured for @audio group"
        else
            print_warn "PAM limits for @audio group not found"
            ((WARNINGS++))
        fi
    fi
}

# Check RTKit and realtime priorities
check_rtkit() {
    print_section "Realtime Scheduling (RTKit)"
    
    if systemctl is-active --quiet rtkit-daemon.service; then
        print_pass "rtkit-daemon.service is running"
    else
        print_fail "rtkit-daemon.service is NOT running"
        ((ERRORS++))
    fi
    
    # Check if PipeWire has realtime priority
    local pw_pid=$(pgrep -u "$USER" "^pipewire$" | head -1)
    if [[ -n "$pw_pid" ]]; then
        local priority=$(ps -p "$pw_pid" -o ni= 2>/dev/null | tr -d ' ')
        if [[ "$priority" -lt 0 ]]; then
            print_pass "PipeWire process has elevated priority (nice=$priority)"
        else
            print_warn "PipeWire process has normal priority (nice=$priority)"
            ((WARNINGS++))
        fi
    fi
}

# Check pro audio kernel optimizations
check_pro_audio_kernel() {
    print_section "Pro Audio Kernel Optimizations"
    
    # Check for threadirqs kernel parameter
    if grep -q "threadirqs" /proc/cmdline 2>/dev/null; then
        print_pass "threadirqs kernel parameter is enabled"
    else
        print_warn "threadirqs not enabled - recommended for pro audio"
        ((WARNINGS++))
    fi
    
    # Check RTC interrupt frequency
    if [[ -f /sys/class/rtc/rtc0/max_user_freq ]]; then
        local rtc_freq=$(cat /sys/class/rtc/rtc0/max_user_freq 2>/dev/null)
        if [[ "$rtc_freq" -ge 2048 ]]; then
            print_pass "RTC interrupt frequency: $rtc_freq Hz (optimal for audio)"
        elif [[ "$rtc_freq" -ge 1024 ]]; then
            print_info "RTC interrupt frequency: $rtc_freq Hz (good)"
        else
            print_warn "RTC interrupt frequency: $rtc_freq Hz (default: 64 Hz, recommended: 2048 Hz)"
            ((WARNINGS++))
        fi
    fi
    
    # Check CPU frequency governor
    if command -v cpupower &>/dev/null; then
        local governor=$(cpupower frequency-info -p 2>/dev/null | grep "current policy" | awk '{print $NF}')
        if [[ -n "$governor" ]]; then
            if [[ "$governor" == "performance" ]]; then
                print_pass "CPU governor: $governor (optimal for audio)"
            elif [[ "$governor" == "schedutil" ]]; then
                print_info "CPU governor: $governor (good for most use cases)"
            else
                print_warn "CPU governor: $governor (consider 'performance' for ultra-low latency)"
            fi
        fi
    fi
}

# Check suspension settings
check_suspension() {
    print_section "Audio Device Suspension"
    
    # Check for ALSA devices
    local alsa_suspended=0
    while IFS= read -r node; do
        if echo "$node" | grep -q "SUSPENDED"; then
            ((alsa_suspended++))
        fi
    done < <(wpctl status 2>/dev/null | grep -E "alsa_output|alsa_input" || true)
    
    if [[ $alsa_suspended -eq 0 ]]; then
        print_pass "No ALSA devices are suspended"
    else
        print_warn "$alsa_suspended ALSA device(s) currently suspended"
        ((WARNINGS++))
    fi
    
    # Check Bluetooth devices
    local bt_suspended=0
    while IFS= read -r node; do
        if echo "$node" | grep -q "SUSPENDED"; then
            ((bt_suspended++))
        fi
    done < <(wpctl status 2>/dev/null | grep -E "bluez_output|bluez_input" || true)
    
    if [[ $bt_suspended -eq 0 ]]; then
        print_pass "No Bluetooth devices are suspended"
    else
        print_info "$bt_suspended Bluetooth device(s) suspended (normal when idle)"
    fi
    
    # Check configuration
    local wp_config_dirs=("/etc/wireplumber" "$HOME/.config/wireplumber")
    local suspend_disabled=false
    for dir in "${wp_config_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            if grep -r "suspend-timeout-seconds.*0" "$dir" 2>/dev/null | grep -qv "^#"; then
                suspend_disabled=true
                break
            fi
        fi
    done
    
    if $suspend_disabled; then
        print_pass "Device suspension is disabled in configuration"
    else
        print_warn "Device suspension configuration not found"
        ((WARNINGS++))
    fi
}

# Check Bluetooth codecs
check_bluetooth_codecs() {
    print_section "Bluetooth Audio Codecs"
    
    # Check if Bluetooth is available
    if ! command -v bluetoothctl &> /dev/null; then
        print_info "Bluetooth tools not available - skipping"
        return
    fi
    
    # Check WirePlumber Bluetooth configuration
    local wp_config_dirs=("/etc/wireplumber" "$HOME/.config/wireplumber")
    local codecs_found=false
    
    for dir in "${wp_config_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local codec_config=$(grep -r "bluez5.codecs" "$dir" 2>/dev/null | grep -v "^#" || echo "")
            if [[ -n "$codec_config" ]]; then
                codecs_found=true
                print_pass "Bluetooth codecs configured:"
                echo -e "   ${CYAN}$codec_config${NC}"
                
                # Check for high-quality codecs
                if echo "$codec_config" | grep -q "ldac"; then
                    print_pass "LDAC codec enabled (high quality)"
                fi
                if echo "$codec_config" | grep -q "aptx_ll"; then
                    print_pass "aptX Low Latency enabled (gaming)"
                fi
                if echo "$codec_config" | grep -q "lc3plus"; then
                    print_pass "LC3Plus enabled (modern high-res)"
                fi
                break
            fi
        fi
    done
    
    if ! $codecs_found; then
        print_warn "Bluetooth codec configuration not found"
        ((WARNINGS++))
    fi
    
    # List connected Bluetooth audio devices
    local bt_devices=$(wpctl status 2>/dev/null | grep -E "bluez_output|bluez_input" || echo "")
    if [[ -n "$bt_devices" ]]; then
        print_info "Connected Bluetooth audio devices:"
        echo "$bt_devices" | while read -r line; do
            echo -e "   ${CYAN}$line${NC}"
        done
    else
        print_info "No Bluetooth audio devices currently connected"
    fi
}

# Check Discord-specific configuration
check_discord_config() {
    print_section "Discord Audio Configuration"
    
    # Check if Discord process is running
    if pgrep -i discord > /dev/null; then
        print_info "Discord is currently running"
        
        # Check for Discord-specific PipeWire rules
        local discord_rule_found=false
        for config_file in /etc/pipewire/pipewire-pulse.conf ~/.config/pipewire/pipewire-pulse.conf; do
            if [[ -f "$config_file" ]] && grep -q "Discord\|discord" "$config_file" 2>/dev/null; then
                discord_rule_found=true
                print_pass "Discord-specific audio rules configured"
                break
            fi
        done
        
        if ! $discord_rule_found; then
            print_warn "No Discord-specific quantum configuration found"
            ((WARNINGS++))
        fi
    else
        print_info "Discord is not running (skipping runtime checks)"
    fi
}

# Check for audio errors in journal
check_journal_errors() {
    print_section "Recent Audio Errors (Last Hour)"
    
    local error_count=$(journalctl --user -u pipewire.service -u pipewire-pulse.service -u wireplumber.service --since "1 hour ago" 2>/dev/null | grep -iE "error|fail|underflow" | grep -v "ifexists" | wc -l)
    
    if [[ $error_count -eq 0 ]]; then
        print_pass "No audio errors in the last hour"
    elif [[ $error_count -lt 5 ]]; then
        print_warn "$error_count audio error(s) found in the last hour"
        ((WARNINGS++))
        print_info "Run: journalctl --user -u pipewire.service --since '1 hour ago' | grep -i error"
    else
        print_fail "$error_count audio errors found in the last hour"
        ((ERRORS++))
        print_info "Run: journalctl --user -u pipewire.service --since '1 hour ago' | grep -i error"
    fi
    
    # Check for specific known issues
    if journalctl --user -u pipewire-pulse.service --since "1 hour ago" 2>/dev/null | grep -q "UNDERFLOW"; then
        print_warn "UNDERFLOW errors detected - may indicate buffer issues"
        ((WARNINGS++))
    fi
    
    if journalctl --user -u pipewire.service --since "1 hour ago" 2>/dev/null | grep -q "Failed to mlock"; then
        print_fail "Memory lock failures detected - check memlock limits"
        ((ERRORS++))
    fi
}

# Check quantum and latency settings
check_latency() {
    print_section "Latency and Quantum Settings"
    
    local quantum=$(pw-metadata -n settings 2>/dev/null | grep "default.clock.quantum" || echo "")
    if [[ -n "$quantum" ]]; then
        print_info "Default quantum: $quantum"
        local quantum_num=$(echo "$quantum" | grep -oP '\d+' | head -1)
        if [[ "$quantum_num" -le 256 ]]; then
            print_pass "Low latency quantum (≤256)"
        else
            print_warn "Higher latency quantum (>256)"
            ((WARNINGS++))
        fi
    fi
    
    local rate=$(pw-metadata -n settings 2>/dev/null | grep "default.clock.rate" | head -1 || echo "")
    if [[ -n "$rate" ]]; then
        print_info "Default clock rate: $rate"
    fi
}

# List audio devices
list_audio_devices() {
    print_section "Available Audio Devices"
    
    print_info "Audio Sinks (Output Devices):"
    wpctl status 2>/dev/null | sed -n '/Sinks:/,/Sources:/p' | grep -v "Sources:" | tail -n +2 | head -20 || echo "  None found"
    
    print_info "\nAudio Sources (Input Devices):"
    wpctl status 2>/dev/null | sed -n '/Sources:/,/Sink endpoints:/p' | grep -v "Sink endpoints:" | tail -n +2 | head -20 || echo "  None found"
}

# Performance recommendations
show_recommendations() {
    print_section "Recommendations"
    
    if [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
        print_pass "All checks passed! Your audio configuration is optimal."
        return
    fi
    
    if groups | grep -qv '\baudio\b'; then
        echo -e "${YELLOW}1.${NC} Add yourself to the audio group and re-login:"
        echo -e "   ${CYAN}sudo usermod -aG audio \$USER${NC}"
    fi
    
    if [[ $(ulimit -l) != "unlimited" ]]; then
        echo -e "${YELLOW}2.${NC} After adding to audio group, verify memlock limit:"
        echo -e "   ${CYAN}ulimit -l${NC} (should show 'unlimited')"
    fi
    
    if ! systemctl --user is-active --quiet wireplumber.service; then
        echo -e "${YELLOW}3.${NC} Start WirePlumber session manager:"
        echo -e "   ${CYAN}systemctl --user start wireplumber.service${NC}"
    fi
    
    echo -e "\n${CYAN}For more details, check:${NC}"
    echo -e "  • ${CYAN}journalctl --user -u pipewire.service -f${NC}"
    echo -e "  • ${CYAN}pw-top${NC} (monitor active streams)"
    echo -e "  • ${CYAN}wpctl status${NC} (list all audio devices)"
}

# Generate summary
show_summary() {
    print_section "Summary"
    
    if [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}✓ All checks passed!${NC}"
        echo -e "Your audio configuration is optimal for gaming and high-quality playback."
    elif [[ $ERRORS -eq 0 ]]; then
        echo -e "${YELLOW}${BOLD}⚠ $WARNINGS warning(s) found${NC}"
        echo -e "Your configuration is good but could be improved."
    else
        echo -e "${RED}${BOLD}✗ $ERRORS error(s) and $WARNINGS warning(s) found${NC}"
        echo -e "Please review the issues above and apply recommended fixes."
    fi
    
    echo ""
}

# Main execution
main() {
    print_header
    
    check_pipewire_running
    check_sample_rates
    check_resample_quality
    check_memlock
    check_rtkit
    check_pro_audio_kernel
    check_suspension
    check_bluetooth_codecs
    check_discord_config
    check_latency
    check_journal_errors
    list_audio_devices
    show_recommendations
    show_summary
}

main "$@"
