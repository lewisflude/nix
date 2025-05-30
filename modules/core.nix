{ self, pkgs, username, ... }: {
  # Nix daemon & CLI settings
  nix = {
    enable = false; # managed by Determinate Nix installation
    # package explicit for clarity
    package = pkgs.nix;

    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      warn-dirty = false;
      trusted-users = [ "root" username ];
      trusted-substituters = [
        "https://nix-community.cachix.org"
        "https://cache.determinate.systems"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

    };
  };

  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.stateVersion = 6;

  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
  };
}
