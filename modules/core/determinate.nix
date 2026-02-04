# Determinate Nix configuration for Darwin
# Declaratively configures nix.custom.conf via determinateNix.customSettings
# See: https://docs.determinate.systems/guides/nix-darwin/
{ config, ... }:
let
  constants = config.constants;
  inherit (config) username;
in
{
  flake.modules.darwin.determinate = {
    determinateNix = {
      enable = true;

      # Declaratively configure /etc/nix/nix.custom.conf
      customSettings = {
        # Allow user to manage binary caches (needed for devenv)
        trusted-users = [
          "root"
          username
        ];

        # Performance settings
        max-jobs = 16;
        max-substitution-jobs = 28;
        http-connections = 64;
        cores = 0;
        sandbox = false;

        # Binary caches from constants
        extra-substituters = constants.binaryCaches.substituters;
        extra-trusted-public-keys = constants.binaryCaches.trustedPublicKeys;
      };
    };
  };
}
