{
  username,
  lib,
  ...
}: {
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

      # Better caching with additional substituters
      substituters = lib.mkForce [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = lib.mkForce [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      # Additional recommended settings
      keep-outputs = true; # Keep build outputs for better caching
      keep-derivations = true; # Keep .drv files for better rebuilds
      fallback = true; # Build from source if binary cache fails
    };

    # Note: Automatic garbage collection requires nix.enable = true
    # Since nix-darwin doesn't manage the Nix daemon in this config,
    # you can manually run: nix-collect-garbage --delete-older-than 7d
    # Or enable nix.enable = true to use automatic GC
    gc = lib.mkIf false {
      # Disabled because nix.enable = false
      automatic = true;
      interval = {
        Weekday = 1; # Monday
        Hour = 3;
        Minute = 30;
      };
      options = "--delete-older-than 7d";
    };

    # Configure Nix path and channels
    nixPath = lib.mkDefault [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixpkgs"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };
}
