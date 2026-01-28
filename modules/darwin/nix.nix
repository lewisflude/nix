{
  username,
  lib,
  config,
  pkgs,
  ...
}:
let
  constants = import ../../lib/constants.nix;
in
{
  determinateNix.customSettings = {
    flake-registry = "/etc/nix/flake-registry.json";
    sandbox = "relaxed";

    trusted-users = [
      "root"
      "@admin"
      username
    ];

    warn-dirty = false;
    keep-outputs = true;
    keep-derivations = true;

    # Binary caches
    extra-substituters = constants.binaryCaches.substituters;
    extra-trusted-public-keys = constants.binaryCaches.trustedPublicKeys;
    trusted-substituters = [ "https://install.determinate.systems" ];

    # Experimental features
    experimental-features = [
      "nix-command"
      "flakes"
      "pipe-operators"
    ];

    log-lines = 25;
  };


  nix = {
    # Determinate Nix owns the daemon + /etc/nix/nix.conf; keep nix-darwin out
    enable = lib.mkForce false;

    # Flakes don't use channels - nixPath is only for legacy compatibility
    # Leaving empty for pure flakes approach
    nixPath = lib.mkDefault [ ];
    optimise = {
      # Automatic optimisation requires nix.enable = true; disable it while
      # Determinate Nix manages the daemon so the assertion stays satisfied.
      automatic = lib.mkDefault false;
    };
  };
}
