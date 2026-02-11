# Core Nix daemon configuration for NixOS and Darwin
# Uses top-level config.username from modules/meta.nix
# Dendritic pattern: No inputs parameter in lower-level modules
{ config, ... }:
let
  inherit (config) constants;
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
        # 13900K: 24 cores (8P+16E). 4 jobs * 6 cores = 24 threads (matches physical cores)
        max-jobs = lib.mkDefault 4;
        cores = lib.mkDefault 6;
        max-substitution-jobs = lib.mkDefault 28;
        http-connections = lib.mkDefault 64;
        always-allow-substitutes = lib.mkDefault true;
        connect-timeout = 5;
        stalled-download-timeout = 10;
        experimental-features = [
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

      # Determinate Nix-specific settings (not in nix.settings schema)
      nix.extraOptions = ''
        eval-cores = 4
      '';

      # Note: configurationRevision removed - not needed in lower-level modules
    };

  # Darwin Nix configuration
  # Disable nix-darwin's Nix management since Determinate Nix handles it
  # See: https://github.com/nix-darwin/nix-darwin/pull/1313
  flake.modules.darwin.nix =
    _:
    {
      # Let Determinate Nix manage the Nix daemon
      nix.enable = false;
    };
}
