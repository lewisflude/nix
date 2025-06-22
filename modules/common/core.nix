{
  self,
  pkgs,
  username,
  system,
  lib,
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

  # Platform-specific configuration revision and state version
  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.stateVersion = if lib.hasInfix "darwin" system then 6 else "25.05";

  nixpkgs = {
    hostPlatform = system;
    config.allowUnfree = true;
  };
}
