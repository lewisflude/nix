{
  self,
  username,
  system,
  lib,
  ...
}: let
  platformLib = import ../../lib/functions.nix {inherit lib system;};
in {
  nix = {
    settings = {
      warn-dirty = false;
      trusted-users = [
        "root"
        username
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };
  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.stateVersion = lib.mkDefault platformLib.platformStateVersion;
  nixpkgs = {
    hostPlatform = system;
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = false;
    };
  };
}
