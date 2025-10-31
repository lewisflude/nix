{
  username,
  lib,
  ...
}: {
  # Determinate Nix configuration
  determinate-nix.customSettings = {
    flake-registry = "/etc/nix/flake-registry.json";
  };

  environment.etc."nix/nix.custom.conf" = {
    text = ''
      trusted-users = root ${username}
      warn-dirty = false
    '';
  };

  # Note: nix.enable = false means nix-darwin doesn't manage the Nix daemon
  # You may want to set this to true if you want full nix-darwin management
  nix = {
    enable = false;

    settings = {
      sandbox = true;
      trusted-users = [
        "root"
        "@admin"
        username
      ];

      # Performance optimizations
      auto-optimise-store = true; # Deduplicate files in Nix store
      max-jobs = "auto"; # Use all CPU cores for builds
      build-cores = 0; # Use all cores per build job (0 = auto)

      # Note: Binary caches are configured in flake.nix nixConfig section
      # Those settings apply to both Darwin and NixOS systems
      # mkForce was removed to allow flake.nix caches to be used

      # Additional recommended settings
      keep-outputs = true; # Keep build outputs for better caching
      keep-derivations = true; # Keep .drv files for better rebuilds
      fallback = true; # Build from source if binary cache fails

      # Cache and download optimizations
      download-buffer-size = 524288000; # 500MB buffer for faster downloads
    };

    # Garbage collection is not configured because nix.enable = false
    # To run manually: nix-collect-garbage --delete-older-than 7d
    # Or enable nix.enable = true to use automatic GC

    # Configure Nix path and channels
    nixPath = lib.mkDefault [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixpkgs"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };
}
