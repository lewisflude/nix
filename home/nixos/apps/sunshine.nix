_: {
  # Sunshine configuration for game streaming with KMS capture
  # KMS (Kernel Mode Setting) capture is more reliable than wlroots on Wayland
  # Requires CAP_SYS_ADMIN capability (configured in modules/nixos/features/gaming.nix)
  xdg.configFile."sunshine/sunshine.conf".text = ''
    # Display capture settings
    capture = kms

    # Output settings optimized for Quest 3 and RTX 4090 NVENC
    encoder = nvenc
    adapter_name = /dev/dri/card2
    # output_name auto-detected (DP-3 on card2)

    # Network settings
    upnp = on
    port = 47989

    # Performance settings
    min_fps_factor = 1
    channels = 2
  '';
}
