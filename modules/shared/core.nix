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
        max-jobs = 16;
        max-substitution-jobs = 28;
        http-connections = 64;
        always-allow-substitutes = true;
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
        # Note: chaotic-nyx.cachix.org is automatically added by chaotic.nixosModules.default
        # We use extra-substituters to add our caches without overriding chaotic's automatic configuration
        extra-substituters = [
          "https://nix-community.cachix.org"
          "https://nixpkgs-wayland.cachix.org"
          "https://numtide.cachix.org"
          "https://nixpkgs-python.cachix.org"
          "https://lewisflude.cachix.org"
          "https://niri.cachix.org"
          "https://ghostty.cachix.org"
          "https://yazi.cachix.org"
          "https://ags.cachix.org"
          "https://zed.cachix.org"
          "https://cache.garnix.io"
          "https://devenv.cachix.org"
          "https://viperml.cachix.org"
          "https://cuda-maintainers.cachix.org"
        ];
        extra-trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
          "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
          "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
          "viperml.cachix.org-1:qrxbEKGdajQ+s0pzofucGqUKqkjT+N3c5vy7mOML04c="
          "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
          "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
          "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
          "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
          "lewisflude.cachix.org-1:Y4J8FK/Rb7Es/PnsQxk2ZGPvSLup6ywITz8nimdVWXc="
          "ags.cachix.org-1:naAvMrz0CuYqeyGNyLgE010iUiuf/qx6kYrUv3NwAJ8="
          "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
          "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
          "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
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
