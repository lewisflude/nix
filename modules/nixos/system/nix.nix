{username, ...}: {
  # NixOS-specific Nix configuration

  # Enable the Nix daemon (managed by systemd on NixOS)
  nix.enable = true;

  # NixOS-specific Nix settings
  nix.settings = {
    # Ensure compatibility with NixOS
    sandbox = true;

    # Linux-specific trust settings
    trusted-users = [
      "root"
      "@wheel"
      username
    ];

    # Additional systemd integration
    use-xdg-base-directories = true;

    # Explicitly enable lazy-trees (enabled by default in Determinate Nix)
  };
}
