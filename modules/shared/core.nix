{
  self,
  username,
  system,
  lib,
  ...
}: let
  platformLib = import ../../lib/functions.nix {inherit lib system;};
in {
  # Cross-platform Nix configuration
  nix = {
    settings =
      {
        # Basic cross-platform settings - detailed optimization handled in nix-optimization.nix
        warn-dirty = false;

        # Basic trusted users (platform-specific ones are handled in platform modules)
        trusted-users = [
          "root"
          username
        ];

        # Experimental features
        experimental-features =
          [
            "nix-command"
            "flakes"
          ]
          ++ lib.optionals platformLib.isDarwin ["lazy-trees"];
      }
      // lib.optionalAttrs platformLib.isDarwin {
        # Performance optimizations - lazy-trees only available on Darwin
        lazy-trees = true;
      };
  };

  # Configuration revision tracking
  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.stateVersion = lib.mkDefault platformLib.platformStateVersion;

  # Cross-platform nixpkgs configuration
  nixpkgs = {
    hostPlatform = system;
    config = {
      allowUnfree = true;
      allowBroken = true;
      allowUnsupportedSystem = false;
    };
  };
}
