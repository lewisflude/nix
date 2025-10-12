{pkgs, ...}: {
  # Keyboard firmware tools for macOS
  # VIA/VIAL for configuring QMK keyboards
  #
  # Note: On macOS, VIA/VIAL are installed via Homebrew Casks
  # as the native applications work better than wrapped versions

  # Install via Homebrew for native macOS integration
  homebrew.casks = [
    "via" # VIA keyboard configurator
    # "vial" is not available via homebrew, use VIA instead or download from vial.rocks
  ];

  # Additional packages that might be useful for keyboard development
  home.packages = with pkgs; [
    # QMK CLI tools (optional, for firmware development)
    # qmk # Uncomment if you need QMK CLI on macOS
  ];

  # Note: Firmware JSON files are cross-platform
  # Use the same mnk88-universal.json on both NixOS and macOS
  # Location: docs/reference/mnk88-universal.json
}
