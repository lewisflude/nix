_: {
  # Install Karabiner-Elements via homebrew
  # The actual configuration is managed in home/darwin/karabiner.nix
  homebrew.casks = ["karabiner-elements"];

  # Note: User must manually grant permissions after first install:
  # System Settings → Privacy & Security → Input Monitoring → Enable Karabiner
  # System Settings → Privacy & Security → Accessibility → Enable Karabiner-Elements
}
