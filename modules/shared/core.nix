{
  config,
  inputs,
  lib,
  hostSystem,
  ...
}:
let
  constants = import ../../lib/constants.nix;
  platformLib = (import ../../lib/functions.nix { inherit lib; }).withSystem hostSystem;

  revision =
    let
      inherit (inputs) self;
      revVal = self.rev or null;
      dirtyRevVal = self.dirtyRev or null;
    in
    if revVal != null then
      toString revVal
    else if dirtyRevVal != null then
      toString dirtyRevVal
    else
      null;
in
{
  nix = {
    settings = lib.mkMerge [
      {
        warn-dirty = false;
        trusted-users = lib.mkDefault [
          "root"
          config.host.username
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
        # Binary cache substituters
        # Shared configuration from lib/constants.nix
        extra-substituters = constants.binaryCaches.substituters;
        extra-trusted-public-keys = constants.binaryCaches.trustedPublicKeys;
      }
      (lib.mkIf (hostSystem == "aarch64-darwin") {
        extra-platforms = [ "x86_64-darwin" ];
      })
    ];
  };

  system.configurationRevision = lib.mkDefault revision;
  system.stateVersion = lib.mkDefault platformLib.platformStateVersion;
}
