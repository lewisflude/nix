{
  config,
  inputs,
  lib,
  hostSystem,
  ...
}: let
  platformLib = import ../../lib/functions.nix {
    inherit lib;
    system = hostSystem;
  };
in {
  nix = {
    settings = lib.mkMerge [
      {
        warn-dirty = false;
        trusted-users = [
          "root"
          config.host.username
        ];
        experimental-features = [
          "nix-command"
          "flakes"
        ];
      }
      (lib.mkIf (hostSystem == "aarch64-darwin") {
        extra-platforms = ["x86_64-darwin"];
      })
    ];
  };

  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  system.stateVersion = lib.mkDefault platformLib.platformStateVersion;

  nixpkgs.config = {
    allowUnfree = true;
    allowUnsupportedSystem = false;
  };
}
