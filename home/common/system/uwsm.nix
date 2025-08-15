_: {
  # UWSM environment configuration for NVIDIA EGL support
  home.file.".config/uwsm/env".text = ''
    # NVIDIA EGL/Wayland support for GTK4 applications like Ghostty
    export GBM_BACKEND="nvidia-drm"
    export __GLX_VENDOR_LIBRARY_NAME="nvidia"
    export LIBVA_DRIVER_NAME="nvidia"
    export __GL_VRR_ALLOWED="0"

    # Tell UWSM to explicitly export these variables to the activation environment
    export UWSM_FINALIZE_VARNAMES="GBM_BACKEND __GLX_VENDOR_LIBRARY_NAME LIBVA_DRIVER_NAME __GL_VRR_ALLOWED"
  '';

  # Niri-specific environment configuration
  home.file.".config/uwsm/env-niri".text = ''
    # NVIDIA EGL/Wayland support for GTK4 applications like Ghostty (niri-specific)
    export GBM_BACKEND="nvidia-drm"
    export __GLX_VENDOR_LIBRARY_NAME="nvidia"
    export LIBVA_DRIVER_NAME="nvidia"
    export __GL_VRR_ALLOWED="0"

    # Tell UWSM to explicitly export these variables to the activation environment
    export UWSM_FINALIZE_VARNAMES="GBM_BACKEND __GLX_VENDOR_LIBRARY_NAME LIBVA_DRIVER_NAME __GL_VRR_ALLOWED"
  '';
}
