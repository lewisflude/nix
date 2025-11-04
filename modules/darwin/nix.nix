{
  username,
  lib,
  ...
}: {
  # Determinate Nix configuration
  determinate-nix.customSettings = {
    flake-registry = "/etc/nix/flake-registry.json";
  };

  # Custom Nix configuration that gets included by Determinate Nix
  # This file is included via !include directive in /etc/nix/nix.conf
  environment.etc."nix/nix.custom.conf" = {
    text = ''
      # User permissions
      trusted-users = root @admin ${username}

      # Disable dirty git tree warnings
      warn-dirty = false

      # Performance optimizations
      auto-optimise-store = true
      max-jobs = auto
      build-cores = 0

      # Keep outputs for better caching and development
      keep-outputs = true
      keep-derivations = true
      fallback = true

      # Download optimization (500MB buffer)
      download-buffer-size = 524288000

      # Build sandbox (security)
      sandbox = true

      # Note: Binary caches and experimental features are configured in flake.nix nixConfig
      # Those settings apply to both Darwin and NixOS systems via the flake
      # Note: Determinate Nix sets 'eval-cores' and 'lazy-trees' in /etc/nix/nix.conf
    '';
  };

  # Note: nix.enable = false means nix-darwin doesn't manage the Nix daemon
  # Determinate Nix manages the daemon instead via determinate.darwinModules.default
  # This prevents conflicts between nix-darwin and Determinate Nix daemon management
  nix = {
    enable = false;

    # These settings are IGNORED when nix.enable = false
    # All active settings must be in environment.etc."nix/nix.custom.conf" above

    # Garbage collection is not configured because nix.enable = false
    # To run manually: nix-collect-garbage --delete-older-than 7d

    # Configure Nix path and channels
    nixPath = lib.mkDefault [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixpkgs"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };
}
