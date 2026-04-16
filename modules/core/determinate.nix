# Determinate Nix configuration for Darwin
# Declaratively configures nix.custom.conf via determinateNix.customSettings
# See: https://docs.determinate.systems/guides/nix-darwin/
{ config, ... }:
let
  inherit (config) constants;
  inherit (config) username;
in
{
  flake.modules.darwin.determinate = {
    determinateNix = {
      enable = true;

      # Declaratively configure /etc/nix/nix.custom.conf
      customSettings = {
        # Allow user to manage binary caches (needed for cachix and nix develop)
        trusted-users = [
          "root"
          username
        ];

        # Performance settings
        max-jobs = 2;
        max-substitution-jobs = 28;
        http-connections = 64;
        connect-timeout = 5;
        stalled-download-timeout = 10;
        cores = 4;
        sandbox = false;
        always-allow-substitutes = true;
        eval-cores = 4;

        # Binary caches from constants
        extra-substituters = constants.binaryCaches.substituters;
        extra-trusted-public-keys = constants.binaryCaches.trustedPublicKeys;
      };
    };
  };
}
