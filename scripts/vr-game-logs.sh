#!/usr/bin/env bash
# VR Game Log Collector
# Gathers all relevant logs for debugging VR game issues

set -euo pipefail

GAME_NAME="${1:-Half-Life 2: VR Mod}"
APP_ID="${2:-658920}"  # Half-Life 2 VR default

STEAM_ROOT="$HOME/.local/share/Steam"
OUTPUT_DIR="$HOME/vr-game-logs-$(date +%Y%m%d-%H%M%S)"

echo "=== VR Game Log Collector ==="
echo "Game: $GAME_NAME (App ID: $APP_ID)"
echo "Output directory: $OUTPUT_DIR"
echo ""

mkdir -p "$OUTPUT_DIR"

# Function to safely copy log file
copy_log() {
    local src="$1"
    local dest="$2"
    if [ -f "$src" ]; then
        cp "$src" "$OUTPUT_DIR/$dest"
        echo "✓ Copied: $dest"
    else
        echo "⊘ Not found: $src"
    fi
}

# Function to save command output
save_output() {
    local cmd="$1"
    local dest="$2"
    echo "Running: $cmd"
    eval "$cmd" > "$OUTPUT_DIR/$dest" 2>&1 || echo "Command failed (exit $?)" >> "$OUTPUT_DIR/$dest"
    echo "✓ Saved: $dest"
}

echo "## Collecting Steam logs..."

# Main Steam logs
copy_log "$STEAM_ROOT/logs/console-linux.txt" "steam-console.txt"
copy_log "$STEAM_ROOT/logs/compat_log.txt" "steam-compat.txt"
copy_log "$STEAM_ROOT/logs/shader_log.txt" "steam-shader.txt"
copy_log "$STEAM_ROOT/logs/gameprocess_log.txt" "steam-gameprocess.txt"

# SteamVR logs
copy_log "$STEAM_ROOT/logs/vrserver.txt" "steamvr-server.txt"
copy_log "$STEAM_ROOT/logs/vrstartup.txt" "steamvr-startup.txt"
copy_log "$STEAM_ROOT/logs/vrstartup-linux.txt" "steamvr-startup-linux.txt"
copy_log "$STEAM_ROOT/logs/vrcompositor.txt" "steamvr-compositor.txt"
copy_log "$STEAM_ROOT/logs/vrcompositor-linux.txt" "steamvr-compositor-linux.txt"
copy_log "$STEAM_ROOT/logs/vrmonitor.txt" "steamvr-monitor.txt"
copy_log "$STEAM_ROOT/logs/vrclient_vrserver.txt" "steamvr-client-server.txt"

echo ""
echo "## Collecting Proton/Wine logs for App ID $APP_ID..."

COMPAT_DIR="$STEAM_ROOT/steamapps/compatdata/$APP_ID"
if [ -d "$COMPAT_DIR" ]; then
    # Find all log files in the compat data directory
    find "$COMPAT_DIR" -name "*.log" -o -name "steam_*.txt" | while read -r logfile; do
        rel_path="${logfile#$COMPAT_DIR/}"
        dest="proton-$(echo "$rel_path" | tr '/' '-')"
        copy_log "$logfile" "$dest"
    done

    # Wine debug logs
    copy_log "$COMPAT_DIR/pfx/drive_c/users/steamuser/Temp/steam.log" "wine-steam.log"
else
    echo "⊘ Compat data directory not found: $COMPAT_DIR"
    echo "  (Game may not have been launched yet)"
fi

echo ""
echo "## Collecting WiVRn/Monado logs..."

# WiVRn service logs (last 500 lines)
save_output "journalctl --user -u wivrn.service -n 500 --no-pager" "wivrn-service.log"

# Monado logs from WiVRn (if WiVRn includes Monado)
save_output "journalctl --user -t monado -n 500 --no-pager" "monado.log"

echo ""
echo "## Collecting system logs..."

# Recent system logs related to VR/graphics
save_output "journalctl -b -n 1000 --no-pager | grep -iE 'steamvr|wivrn|monado|openxr|nvidia|vulkan|drm'" "system-vr-related.log"

# Kernel messages (for driver issues)
save_output "dmesg -T | tail -500" "dmesg.log"

echo ""
echo "## Collecting VR configuration..."

# OpenXR runtime config
copy_log "$HOME/.config/openxr/1/active_runtime.json" "openxr-runtime.json"
save_output "readlink -f $HOME/.config/openxr/1/active_runtime.json" "openxr-runtime-path.txt"

# OpenVR paths
copy_log "$HOME/.config/openvr/openvrpaths.vrpath" "openvr-paths.json"

# WiVRn config
copy_log "$HOME/.config/wivrn/config.json" "wivrn-config.json"

# SteamVR settings
copy_log "$STEAM_ROOT/config/steamvr.vrsettings" "steamvr-settings.json"

echo ""
echo "## Gathering system information..."

# GPU and driver info
save_output "nvidia-smi" "nvidia-smi.txt"
save_output "vulkaninfo --summary" "vulkan-info.txt"
save_output "glxinfo -B" "glx-info.txt"

# VR runtime detection
save_output "vr-which-runtime" "vr-runtime-detection.txt"

# WiVRn service status
save_output "systemctl --user status wivrn.service" "wivrn-status.txt"

# Environment variables
save_output "env | grep -iE 'xr_|steam|vr|pressure'" "environment-vars.txt"

echo ""
echo "## Creating summary..."

cat > "$OUTPUT_DIR/README.txt" << EOF
VR Game Debugging Logs
======================

Game: $GAME_NAME
App ID: $APP_ID
Collected: $(date)
System: $(uname -a)

Log Files:
----------

Steam Logs:
- steam-console.txt: Main Steam client log
- steam-compat.txt: Proton compatibility layer log
- steam-gameprocess.txt: Game process management log
- steam-shader.txt: Shader compilation log

SteamVR Logs:
- steamvr-*.txt: SteamVR component logs (server, compositor, monitor)

Proton/Wine Logs:
- proton-*.log: Wine/Proton logs for the game

WiVRn/Monado Logs:
- wivrn-service.log: WiVRn streaming service log
- monado.log: Monado OpenXR runtime log

System Logs:
- system-vr-related.log: System messages related to VR
- dmesg.log: Kernel messages (driver issues)

Configuration:
- openxr-runtime.json: Active OpenXR runtime
- openvr-paths.json: OpenVR configuration
- wivrn-config.json: WiVRn server config
- steamvr-settings.json: SteamVR settings

System Info:
- nvidia-smi.txt: GPU status
- vulkan-info.txt: Vulkan capabilities
- glx-info.txt: OpenGL info

Common Issues to Check:
-----------------------

1. Check steam-console.txt for game launch errors
2. Check proton-*.log for Wine/compatibility issues
3. Check steamvr-server.txt for SteamVR startup issues
4. Check wivrn-service.log for connection/streaming issues
5. Check system-vr-related.log for driver/permission issues
6. Verify openxr-runtime.json points to correct runtime

For 32-bit game issues (Half-Life 2 VR):
- Check that SteamVR is properly installed
- Verify 32-bit graphics drivers are available
- Look for "32-bit" or "i686" errors in logs
EOF

echo ""
echo "=== Log collection complete! ==="
echo ""
echo "Logs saved to: $OUTPUT_DIR"
echo ""
echo "To view logs:"
echo "  cd $OUTPUT_DIR"
echo "  cat README.txt"
echo "  less steam-console.txt"
echo ""
echo "To share for debugging:"
echo "  tar -czf vr-game-logs.tar.gz $OUTPUT_DIR"
