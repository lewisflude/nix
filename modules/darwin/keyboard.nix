_: {
  # Keyboard firmware tools for macOS
  # VIA for configuring QMK keyboards
  #
  # Note: On macOS, VIA is installed via Homebrew Cask
  # as the native application works better than wrapped versions

  # Install via Homebrew for native macOS integration
  homebrew.casks = [
    "via" # VIA keyboard configurator
    # "vial" is not available via homebrew, use VIA instead or download from vial.rocks
  ];

  # Note: Firmware JSON files are cross-platform
  # Use the same mnk88-universal.json on both NixOS and macOS
  # Location: docs/reference/mnk88-universal.json
}
