#!/usr/bin/env bash
# Debug script for Wine/Proton game black screens
set -euo pipefail

WINE_PREFIX="${1:-$HOME/Games/epic-games-store}"
LOG_DIR="$HOME/.cache/wine-debug-logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$LOG_DIR"

echo "=== Wine/DXVK Debug Session: $TIMESTAMP ==="
echo "Wine Prefix: $WINE_PREFIX"
echo "Log Directory: $LOG_DIR"
echo ""

# Set comprehensive debug environment
export WINEDEBUG=-all
export DXVK_LOG_LEVEL=info
export DXVK_HUD=devinfo,fps,version,api
export VKD3D_DEBUG=warn
export VKD3D_SHADER_DEBUG=warn
export WINEDLLOVERRIDES="winemenubuilder.exe=d"

# Explicit Vulkan ICD paths (from lutris-systemd wrapper)
export VK_ICD_FILENAMES=/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/nvidia_icd.i686.json
export DXVK_FILTER_DEVICE_NAME="NVIDIA"

# Enable DXVK state cache
export DXVK_STATE_CACHE_PATH="$HOME/.cache/dxvk-state-cache"
mkdir -p "$DXVK_STATE_CACHE_PATH"

# Proton/Wine optimizations
export WINE_CPU_TOPOLOGY=8:4  # 8 cores, 4 threads each (adjust for your CPU)
export WINE_LARGE_ADDRESS_AWARE=1

echo "=== Environment Variables ==="
env | grep -E "DXVK|VK_|WINE|VKD3D|VULKAN" | sort
echo ""

echo "=== Vulkan Device Info ==="
vulkaninfo --summary 2>&1 | grep -A 10 "Device Properties" || echo "vulkaninfo failed"
echo ""

echo "=== DXVK DLL Check ==="
if [ -d "$WINE_PREFIX" ]; then
    echo "Checking for DXVK DLLs..."
    for dll in d3d9.dll d3d10core.dll d3d11.dll dxgi.dll; do
        dll_path="$WINE_PREFIX/drive_c/windows/system32/$dll"
        if [ -f "$dll_path" ]; then
            file_type=$(file "$dll_path" | cut -d: -f2)
            echo "  $dll: $file_type"
        else
            echo "  $dll: MISSING"
        fi
    done
else
    echo "Wine prefix not found at $WINE_PREFIX"
fi
echo ""

echo "=== Testing Vulkan with vkcube ==="
timeout 3s vkcube --suppress_popups 2>&1 || echo "vkcube test completed/timed out"
echo ""

echo "=== Recommendations ==="
echo ""
echo "If you see a black screen, try:"
echo "1. Launch game with virtual desktop:"
echo "   WINE_PREFIX='$WINE_PREFIX' wine explorer /desktop=Game,1920x1080 path/to/game.exe"
echo ""
echo "2. Check DXVK logs after launch:"
echo "   tail -f \$WINEPREFIX/*.log"
echo ""
echo "3. Try different DXVK versions:"
echo "   In Lutris: Configure -> Runner options -> DXVK version"
echo ""
echo "4. Reset shader cache:"
echo "   rm -rf ~/.cache/dxvk-state-cache/"
echo "   rm -rf '$WINE_PREFIX/GLCache/'"
echo ""
echo "5. Check compositor interference (Wayland/niri):"
echo "   Some games don't work well with Wayland compositors"
echo ""
echo "=== Press Enter to continue (or Ctrl+C to exit) ==="
read -r

# If second argument provided, launch it
if [ $# -ge 2 ]; then
    echo "Launching: ${2}"
    cd "$WINE_PREFIX" || exit 1

    # Log output
    WINEPREFIX="$WINE_PREFIX" wine "$2" 2>&1 | tee "$LOG_DIR/game_launch_$TIMESTAMP.log"
else
    echo "No executable specified. You can now launch your game manually with debug env set."
    echo "Example: WINEPREFIX='$WINE_PREFIX' wine path/to/game.exe"
fi
