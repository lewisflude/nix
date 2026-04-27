# Nix daemon configuration — feature module.
#
# Both hosts run Determinate Nix (locked at 3.18.1 via the `determinate`
# flake input) for lazy-trees and the parallel-eval substrate. All
# Nix-daemon config is co-located here per dendritic Invariant 3
# (cross-class co-location); shared values flow through `commonSettings`
# so Jupiter and Mercury never drift.
#
# Surface areas differ by class:
#   - NixOS: standard `nix.settings`. The Determinate NixOS module
#     redirects /etc/nix/nix.conf -> /etc/nix/nix.custom.conf
#     transparently, so the upstream interface keeps working.
#   - Darwin: `determinateNix.customSettings`. nix-darwin's own Nix
#     management is disabled because Determinate Nixd owns nix.conf.
{ config, ... }:
let
  inherit (config) constants username;

  commonSettings = {
    trusted-users = [
      "root"
      username
    ];
    cores = 0;
    max-substitution-jobs = 28;
    http-connections = 64;
    connect-timeout = 5;
    stalled-download-timeout = 300;
    sandbox = true;
    always-allow-substitutes = true;
    warn-dirty = false;
    lazy-trees = true;
    extra-substituters = constants.binaryCaches.substituters;
    extra-trusted-public-keys = constants.binaryCaches.trustedPublicKeys;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
in
{
  # Jupiter — NixOS, 24-core 13900K
  flake.modules.nixos.nix = _: {
    nix.settings = commonSettings // {
      max-jobs = 8;
    };
  };

  # Mercury — Darwin laptop
  flake.modules.darwin.nix = _: {
    # Determinate Nixd owns /etc/nix/nix.conf; nix-darwin must not.
    nix.enable = false;

    determinateNix = {
      enable = true;
      customSettings = commonSettings // {
        max-jobs = 2;
      };
    };

    # Prevent Spotlight from indexing the Nix store.
    system.activationScripts.disableSpotlightNixStore.text = ''
      if [ -d "/nix/store" ]; then
        mdutil -i off /nix/store 2>/dev/null || true
      fi
    '';
  };
}
