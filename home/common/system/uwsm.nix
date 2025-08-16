_: {
  # UWSM environment configuration - optimized for RTX 4090 + Wayland performance
  home.file.".config/uwsm/env".text = ''
    # Essential NVIDIA variables for Wayland (minimal set for best compatibility)
    export LIBVA_DRIVER_NAME="nvidia"
    export __GL_VRR_ALLOWED="1"

    # Tell UWSM to explicitly export these variables to the activation environment
    export UWSM_FINALIZE_VARNAMES="LIBVA_DRIVER_NAME __GL_VRR_ALLOWED"
  '';

  # Niri-specific environment configuration
  home.file.".config/uwsm/env-niri".text = ''
    # Same optimized setup for Niri - let compositor handle GBM backend selection
    export LIBVA_DRIVER_NAME="nvidia"
    export __GL_VRR_ALLOWED="1"

    # Tell UWSM to explicitly export these variables to the activation environment
    export UWSM_FINALIZE_VARNAMES="LIBVA_DRIVER_NAME __GL_VRR_ALLOWED"
  '';
}
