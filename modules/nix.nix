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
#   - Darwin: `determinateNix.customSettings`. Determinate Nixd owns
#     nix.conf, and the Determinate nix-darwin module handles that
#     integration while keeping nix-darwin's Nix-dependent modules usable.
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
    always-allow-substitutes = true;
    builders-use-substitutes = true;
    keep-outputs = true;
    keep-derivations = true;
    warn-dirty = false;
    lazy-trees = true;
    # Parallel evaluation. `eval-cores = 0` parallelises nix search /
    # flake check / flake show / eval --json across all CPU cores.
    # The `parallel-eval` experimental feature additionally exposes
    # `builtins.parallel` for explicit use in expressions.
    eval-cores = 0;
    extra-substituters = constants.binaryCaches.substituters;
    extra-trusted-public-keys = constants.binaryCaches.trustedPublicKeys;
    experimental-features = [
      "nix-command"
      "flakes"
      "parallel-eval"
    ];
  };
in
{
  # Jupiter — NixOS, 24-core 13900K
  flake.modules.nixos.nix = _: {
    nix.settings = commonSettings // {
      max-jobs = 8;
      sandbox = true;
    };
  };

  # Mercury — Darwin laptop
  flake.modules.darwin.nix = _: {
    determinateNix = {
      enable = true;
      customSettings = commonSettings // {
        cores = 2;
        eval-cores = 4;
        max-jobs = 2;
        # github-runner on Darwin ships a sandbox profile, which Nix only
        # permits when sandboxing is relaxed.
        sandbox = "relaxed";
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
