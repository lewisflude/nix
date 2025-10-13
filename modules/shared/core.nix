{
  config,
  inputs,
  lib,
  ...
}: let
  platformLib = import ../../lib/functions.nix {
    inherit lib;
    system = config.nixpkgs.hostPlatform.system;
  };
in {
  nix = {
    settings = {
      warn-dirty = false;
      trusted-users = [
        "root"
        config.host.username
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };
  
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  system.stateVersion = lib.mkDefault platformLib.platformStateVersion;
  
  nixpkgs.config = {
    allowUnfree = true;
    allowUnsupportedSystem = false;
  };
}
