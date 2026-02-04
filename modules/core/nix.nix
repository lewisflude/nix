# Core Nix daemon configuration for NixOS and Darwin
# Uses top-level config.username from modules/meta.nix
# Dendritic pattern: No inputs parameter in lower-level modules
{ config, ... }:
let
  constants = config.constants;
  inherit (config) username;
in
{
  # NixOS Nix configuration
  flake.modules.nixos.nix =
    { lib, ... }:
    {
      nix.settings = {
        warn-dirty = false;
        trusted-users = [
          "root"
          username
        ];
        max-jobs = lib.mkDefault 16;
        max-substitution-jobs = lib.mkDefault 28;
        http-connections = lib.mkDefault 64;
        always-allow-substitutes = lib.mkDefault true;
        experimental-features = [
          "nix-command"
          "flakes"
          "ca-derivations"
          "fetch-closure"
          "parse-toml-timestamps"
          "blake3-hashes"
          "verified-fetches"
          "pipe-operators"
          "no-url-literals"
          "git-hashing"
        ];
        extra-substituters = constants.binaryCaches.substituters;
        extra-trusted-public-keys = constants.binaryCaches.trustedPublicKeys;
      };

      # Note: configurationRevision removed - not needed in lower-level modules
    };

  # Darwin Nix configuration
  # Disable nix-darwin's Nix management since Determinate Nix handles it
  # See: https://github.com/nix-darwin/nix-darwin/pull/1313
  flake.modules.darwin.nix =
    { lib, ... }:
    {
      # Let Determinate Nix manage the Nix daemon
      nix.enable = false;
    };
}
