{
  pkgs,
  ...
}:
pkgs.mkShell {
  buildInputs = with pkgs; [
    openxr-loader
    vulkan-loader
    libglvnd # Provides libGL
    xorg.libX11
  ];

  shellHook = ''
    echo "🕶️  VR Environment Loaded"
    echo "Setting up NVIDIA OpenXR environment..."

    # Inject Driver Paths
    export LD_LIBRARY_PATH=/run/opengl-driver/lib:/run/opengl-driver-32/lib:$LD_LIBRARY_PATH

    # Set NVIDIA Vendor ID
    export __GLX_VENDOR_LIBRARY_NAME=nvidia

    # Enable Loader Debugging
    export XR_LOADER_DEBUG=all

    echo "✅ Environment variables set:"
    echo "   LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
    echo "   __GLX_VENDOR_LIBRARY_NAME=$__GLX_VENDOR_LIBRARY_NAME"
    echo "   XR_LOADER_DEBUG=$XR_LOADER_DEBUG"
    echo ""
    echo "Ready to run XRizer or other VR applications."
  '';
}
