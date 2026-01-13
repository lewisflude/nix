#!/usr/bin/env bash
# XRizer OpenGL Initialization Diagnostic Script
# Captures detailed debug info to identify the actual failure point

set -euo pipefail

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "XRizer OpenGL Initialization Diagnostics"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Phase 1: System Configuration Verification
echo "📋 Phase 1: System Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "✓ NVIDIA Driver Version:"
nvidia-smi --query-gpu=driver_version --format=csv,noheader

echo
echo "✓ NVIDIA Modesetting Status:"
if nvidia-settings -q CurrentMetaMode &>/dev/null; then
    echo "  Modesetting: ENABLED"
else
    echo "  Modesetting: DISABLED (check hardware.nvidia.modesetting.enable)"
fi

echo
echo "✓ Hardware Graphics Configuration:"
if systemctl list-units --type=service --all | grep -q nvidia-persistenced; then
    systemctl status nvidia-persistenced.service --no-pager | head -3
fi

echo
echo "✓ OpenGL Environment Variables:"
echo "  __GLX_VENDOR_LIBRARY_NAME=${__GLX_VENDOR_LIBRARY_NAME:-<not set>}"
echo "  LIBGL_DEBUG=${LIBGL_DEBUG:-<not set>}"
echo "  LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-<not set>}"

echo
echo "✓ Vulkan Configuration:"
echo "  VK_DRIVER_FILES=${VK_DRIVER_FILES:-<not set>}"
echo "  VK_INSTANCE_LAYERS=${VK_INSTANCE_LAYERS:-<not set>}"

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Phase 2: OpenXR Runtime Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "✓ XR_RUNTIME_JSON Environment Variable:"
if [ -n "${XR_RUNTIME_JSON:-}" ]; then
    echo "  Set to: $XR_RUNTIME_JSON"
    if [ -f "$XR_RUNTIME_JSON" ]; then
        echo "  ✓ File exists"
    else
        echo "  ❌ File does not exist!"
    fi
else
    echo "  ❌ Not set! This is required for VR apps."
    echo "  Expected in home.sessionVariables.XR_RUNTIME_JSON"
fi

echo
if [ -f ~/.config/openxr/1/active_runtime.json ]; then
    echo "✓ Active OpenXR Runtime (Config File):"
    cat ~/.config/openxr/1/active_runtime.json | grep -E '"name"|"library_path"'
else
    echo "❌ No active_runtime.json found!"
    echo "   Expected: ~/.config/openxr/1/active_runtime.json"
fi

echo
echo "✓ WiVRn Service Status:"
systemctl --user is-active wivrn || echo "  WiVRn is NOT running"

echo
echo "✓ WiVRn IPC Socket (2026):"
if [ -S "$XDG_RUNTIME_DIR/wivrn/comp_ipc" ]; then
    echo "  Socket exists: $XDG_RUNTIME_DIR/wivrn/comp_ipc"
else
    echo "  Socket NOT found (created when VR app starts)"
    echo "  Legacy path check..."
    if [ -S "$XDG_RUNTIME_DIR/monado_comp_ipc" ]; then
        echo "  ⚠️  Found LEGACY socket: $XDG_RUNTIME_DIR/monado_comp_ipc"
        echo "  Consider updating WiVRn to use new socket path"
    fi
fi

echo
echo "✓ OpenVR Paths Configuration:"
if [ -f ~/.config/openvr/openvrpaths.vrpath ]; then
    echo "  openvrpaths.vrpath exists"
    if grep -q "xrizer" ~/.config/openvr/openvrpaths.vrpath; then
        echo "  ✓ Configured for xrizer"
    elif grep -q "opencomposite" ~/.config/openvr/openvrpaths.vrpath; then
        echo "  ⚠️  Configured for OpenComposite (legacy)"
    else
        echo "  ❌ Unknown configuration"
    fi
    echo "  Runtime path:"
    cat ~/.config/openvr/openvrpaths.vrpath | grep -A1 '"runtime"' | tail -1
else
    echo "  File not found (WiVRn creates this automatically)"
fi

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Phase 3: OpenGL & OpenXR Library Detection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "✓ OpenGL Library Paths:"
echo "  /run/opengl-driver/lib:"
if [ -d /run/opengl-driver/lib ]; then
    ls -la /run/opengl-driver/lib/libGL* 2>/dev/null | head -5 || echo "  No libGL found"
else
    echo "  ❌ Directory does not exist"
fi

echo
echo "  /run/opengl-driver-32/lib:"
if [ -d /run/opengl-driver-32/lib ]; then
    ls -la /run/opengl-driver-32/lib/libGL* 2>/dev/null | head -5 || echo "  No libGL found"
else
    echo "  ❌ Directory does not exist (needed for 32-bit apps)"
fi

echo
echo "✓ OpenXR Loader:"
which openxr-loader || echo "  openxr-loader not in PATH"

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 Phase 4: Test OpenGL & OpenXR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "✓ Testing OpenGL with glxinfo:"
if command -v glxinfo &>/dev/null; then
    glxinfo | grep -E "OpenGL (vendor|renderer|version) string" || echo "  glxinfo failed"
else
    echo "  glxinfo not installed (optional)"
fi

echo
echo "✓ Testing Vulkan:"
if command -v vulkaninfo &>/dev/null; then
    vulkaninfo --summary | grep -E "deviceName|driverVersion" | head -2 || echo "  vulkaninfo failed"
else
    echo "  vulkaninfo not installed (optional)"
fi

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 Phase 5: XRizer-Specific Diagnostics"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "To debug XRizer crash, run with verbose logging:"
echo
echo "  export XR_LOADER_DEBUG=all"
echo "  export LIBGL_DEBUG=verbose"
echo "  export MESA_DEBUG=1"
echo "  <your-xrizer-command-here>"
echo
echo "Look for these error patterns:"
echo "  • 'No fbconfig found' → OpenGL context creation failed"
echo "  • 'ERROR_GRAPHICS_DEVICE_INVALID' → Driver rejected OpenGL context"
echo "  • 'Failed to load runtime' → OpenXR runtime not found"
echo "  • 'Can't open display' → X11/Wayland display connection issue"
echo

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Diagnostic Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "Next steps:"
echo "  1. Save this output: ./diagnose-xrizer.sh > xrizer-diag.log"
echo "  2. Run XRizer with debug flags (see Phase 5)"
echo "  3. Share the XRizer crash output to identify the actual error"
echo
