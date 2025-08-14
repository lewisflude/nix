{
  imports = [
    # Cross-platform system modules
    ./yubikey.nix
    ./video-conferencing.nix
    # ./uwsm.nix  # Temporarily disabled - using manual env-niri file

    # Note: Linux-specific modules moved to home/nixos/system/
    # Note: usb.nix and keyboard.nix moved to home/nixos/system/ as they're Linux-only
  ];
}
