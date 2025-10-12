{pkgs, ...}: {
  # Keyboard firmware tools for macOS
  # VIA is installed via modules/darwin/keyboard.nix (homebrew)
  #
  # This file is for Home Manager specific keyboard configurations

  # Additional packages that might be useful for keyboard development
  home.packages = with pkgs; [
    # QMK CLI tools (optional, for firmware development)
    # qmk # Uncomment if you need QMK CLI on macOS
  ];

  # Note: Firmware JSON files are cross-platform
  # Use the same mnk88-universal.json on both NixOS and macOS
  # Location: docs/reference/mnk88-universal.json
}
