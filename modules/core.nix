{
  self,
  pkgs,
  username,
  ...
}:
{
  # Nix daemon & CLI settings
  nix = {
    enable = false; # managed by Determinate Nix installation
    # package explicit for clarity
    package = pkgs.nix;

    settings = {
      # Basic settings - detailed optimization handled in nix-optimization.nix
      warn-dirty = false;
      trusted-users = [
        "root"
        username
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
