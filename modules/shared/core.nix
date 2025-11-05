{
  config,
  inputs,
  lib,
  hostSystem,
  ...
}:
let
  platformLib = (import ../../lib/functions.nix { inherit lib; }).withSystem hostSystem;
  # Extract revision as string to avoid store path references in option documentation
  # We extract the value first to break any direct store path references
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
          "blake3-hashes" # Faster hashing algorithm (BLAKE3)
          "verified-fetches" # Verify git commit signatures via fetchGit
          "pipe-operators" # |> and <| operators for cleaner Nix code
          "no-url-literals" # Disallow unquoted URLs (prevents deprecated syntax)
          "git-hashing" # Git hashing for content-addressed store objects
          # "parallel-eval" # Disabled - slower on this system (Determinate Nix already has eval-cores/lazy-trees)
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
