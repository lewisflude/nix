{
  username,
  ...
}:
{
  # Darwin-specific Nix configuration

  # Custom Nix configuration for macOS
  environment.etc."nix/nix.custom.conf" = {
    text = ''
      # Written by modules/darwin/nix.nix
      lazy-trees = true
      trusted-users = root ${username}
      warn-dirty = false
    '';
  };

  # Darwin-specific Nix settings
  nix = {
    enable = false;
    settings = {
      # Ensure compatibility with macOS
      sandbox = true;

      # macOS-specific trust settings
      trusted-users = [
        "root"
        "@admin"
        username
      ];
    };
  };
}
