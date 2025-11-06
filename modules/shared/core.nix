{
  config,
  inputs,
  lib,
  hostSystem,
  ...
}:
let
  platformLib = (import ../../lib/functions.nix { inherit lib; }).withSystem hostSystem;

  revision =
    let
      self = inputs.self or { };
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
        trusted-users = [
          "root"
          config.host.username
        ];
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
      }
      (lib.mkIf (hostSystem == "aarch64-darwin") {
        extra-platforms = [ "x86_64-darwin" ];
      })
    ];
  };

  system.configurationRevision = lib.mkDefault revision;
  system.stateVersion = lib.mkDefault platformLib.platformStateVersion;
}
