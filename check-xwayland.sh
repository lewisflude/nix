
#!/bin/bash
# Xwayland-satellite debug checker for NVIDIA + NixOS

echo "=== XWAYLAND-SATELLITE DEBUG CHECKER ==="
echo

echo "1. Current EGL Environment Variables:"
echo "   __EGL_VENDOR_LIBRARY_FILENAMES: ${__EGL_VENDOR_LIBRARY_FILENAMES:-'(not set)'}"
echo "   __EGL_EXTERNAL_PLATFORM_CONFIG_DIRS: ${__EGL_EXTERNAL_PLATFORM_CONFIG_DIRS:-'(not set)'}"
echo "   __GLX_VENDOR_LIBRARY_NAME: ${__GLX_VENDOR_LIBRARY_NAME:-'(not set)'}"
echo "   GBM_BACKEND: ${GBM_BACKEND:-'(not set)'}"
echo

echo "2. Check EGL External Platform Files:"
if [ -d "/run/opengl-driver/share/egl/egl_external_platform.d" ]; then
    echo "   ✓ External platform directory exists"
    ls -la /run/opengl-driver/share/egl/egl_external_platform.d/
else
    echo "   ✗ External platform directory missing"
fi
echo

echo "3. Check EGL Vendor Library Directory:"
if [ -d "/run/opengl-driver/share/glvnd/egl_vendor.d" ]; then
    echo "   ✓ EGL vendor directory exists"
    ls -la /run/opengl-driver/share/glvnd/egl_vendor.d/
else
    echo "   ✗ EGL vendor directory missing - checking alternatives..."
    find /run/opengl-driver -name "*vendor*" -type d 2>/dev/null || echo "     No vendor directories found"
fi
echo

echo "4. Check NVIDIA EGL Libraries:"
echo "   NVIDIA EGL libraries in /run/opengl-driver/lib:"
ls -la /run/opengl-driver/lib/*EGL* 2>/dev/null || echo "   No EGL libraries found"
ls -la /run/opengl-driver/lib/*nvidia*egl* 2>/dev/null || echo "   No NVIDIA EGL libraries found"
ls -la /run/opengl-driver/lib/*gbm* 2>/dev/null || echo "   No GBM libraries found"
echo

echo "5. Test EGL with Current Environment:"
echo "   Running eglinfo (looking for errors)..."
timeout 10s eglinfo 2>&1 | grep -E "(error|Error|ERROR|warning|Warning|WARNING|failed|Failed|FAILED)" | head -5
echo "   EGL test complete"
echo

echo "6. Check Xwayland Binary and Dependencies:"
if command -v Xwayland >/dev/null; then
    echo "   ✓ Xwayland binary found: $(which Xwayland)"
    echo "   Xwayland version: $(Xwayland -version 2>&1 | head -1)"
else
    echo "   ✗ Xwayland binary not found"
fi
echo

echo "7. Check xwayland-satellite:"
if command -v xwayland-satellite >/dev/null; then
    echo "   ✓ xwayland-satellite found: $(which xwayland-satellite)"
else
    echo "   ✗ xwayland-satellite not found"
fi
echo

echo "8. Test GBM Backend:"
echo "   Testing GBM device creation..."
python3 -c "
try:
    import ctypes
    libgbm = ctypes.CDLL('libgbm.so.1')
    print('   ✓ libgbm.so.1 loaded successfully')
except Exception as e:
    print(f'   ✗ libgbm.so.1 load failed: {e}')
" 2>/dev/null || echo "   ⚠ Python3 not available for GBM test"
echo

echo "9. Suggested Environment Variables for Testing:"
echo "   export __EGL_EXTERNAL_PLATFORM_CONFIG_DIRS=/run/opengl-driver/share/egl/egl_external_platform.d"
echo "   export __GLX_VENDOR_LIBRARY_NAME=nvidia"
echo "   export GBM_BACKEND=nvidia-drm"
echo

echo "10. Quick Xwayland Test (if you want to try):"
echo "    # Set environment and test Xwayland startup:"
echo "    export __EGL_EXTERNAL_PLATFORM_CONFIG_DIRS=/run/opengl-driver/share/egl/egl_external_platform.d"
echo "    export __GLX_VENDOR_LIBRARY_NAME=nvidia"
echo "    export GBM_BACKEND=nvidia-drm"
echo "    timeout 5s Xwayland :99 -rootless &"
echo "    sleep 2 && pkill Xwayland"
echo

echo "=== DEBUG CHECK COMPLETE ==="
