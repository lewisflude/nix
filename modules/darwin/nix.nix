{
  username,
  lib,
  config,
  pkgs,
  ...
}:
{
  # Nix settings for darwin
  # Note: Determinate Nix will automatically handle writing these to /etc/nix/nix.custom.conf
  # when the determinate-nix module is enabled
  nix.settings = {
    # Determinate-specific settings
    flake-registry = "/etc/nix/flake-registry.json";
    sandbox = "relaxed";

    # Trust settings - darwin-specific to include @admin group
    trusted-users = [
      "root"
      "@admin"
      username
    ];

    # Build settings
    warn-dirty = false;
    auto-optimise-store = true;
    max-jobs = "auto"; # Darwin uses auto instead of fixed number
    cores = 0;
    keep-outputs = true;
    keep-derivations = true;
    fallback = true;
    keep-going = true;

    # Network settings
    download-buffer-size = 524288000;
    http-connections = 64;
    max-substitution-jobs = 28;
    connect-timeout = 5;

    # Substituter settings
    always-allow-substitutes = true;
    builders-use-substitutes = true;
    narinfo-cache-positive-ttl = 30;
    narinfo-cache-negative-ttl = 1;

    # Binary cache substituters (from modules/shared/core.nix)
    extra-substituters = [
      "https://chaotic-nyx.cachix.org"
      "https://nix-community.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
      "https://numtide.cachix.org"
      "https://nixpkgs-python.cachix.org"
      "https://lewisflude.cachix.org"
      "https://niri.cachix.org"
      "https://ghostty.cachix.org"
      "https://yazi.cachix.org"
      "https://ags.cachix.org"
      "https://helix.cachix.org"
      "https://zed.cachix.org"
      "https://cache.garnix.io"
      "https://cache.thalheim.io"
      "https://devenv.cachix.org"
      "https://viperml.cachix.org"
      "https://cuda-maintainers.cachix.org"
      "https://claude-code.cachix.org"
    ];

    # Trusted public keys for binary caches
    extra-trusted-public-keys = [
      "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      "viperml.cachix.org-1:qrxbEKGdajQ+s0pzofucGqUKqkjT+N3c5vy7mOML04c="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
      "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc="
      "lewisflude.cachix.org-1:Y4J8FK/Rb7Es/PnsQxk2ZGPvSLup6ywITz8nimdVWXc="
      "ags.cachix.org-1:naAvMrz0CuYqeyGNyLgE010iUiuf/qx6kYrUv3NwAJ8="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
    ];

    # Determinate Systems trusted substituter
    trusted-substituters = [ "https://install.determinate.systems" ];

    # Experimental features
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
      "build-time-fetch-tree" # darwin-specific
    ];

    # Logging
    log-lines = 25;
  };

  system.activationScripts.nixGithubToken = lib.mkIf (config.sops.secrets ? GITHUB_TOKEN) {
    text = ''
      set -euo pipefail

      NIX_CUSTOM_CONF="/etc/nix/nix.custom.conf"
      SECRET_PATH="${config.sops.secrets.GITHUB_TOKEN.path}"


      if [ -z "$SECRET_PATH" ] || [ ! -r "$SECRET_PATH" ]; then
        echo "Warning: GitHub token secret not available" >&2
        exit 0
      fi

      GITHUB_TOKEN="$(${pkgs.coreutils}/bin/cat "$SECRET_PATH")"

      if [ -z "$GITHUB_TOKEN" ]; then
        echo "Warning: GitHub token is empty" >&2
        exit 0
      fi


      if [ ! -f "$NIX_CUSTOM_CONF" ]; then
        echo "Warning: $NIX_CUSTOM_CONF does not exist, creating it" >&2
        touch "$NIX_CUSTOM_CONF"
        chmod 644 "$NIX_CUSTOM_CONF"
      fi



      ${pkgs.gnused}/bin/sed -i "" '/^access-tokens.*github\.com/d' "$NIX_CUSTOM_CONF" 2>/dev/null || true


      echo "access-tokens = github.com=$GITHUB_TOKEN" >> "$NIX_CUSTOM_CONF"


      chmod 644 "$NIX_CUSTOM_CONF"
    '';
  };

  nix = {
    enable = false;

    # Flakes don't use channels - nixPath is only for legacy compatibility
    # Leaving empty for pure flakes approach
    nixPath = lib.mkDefault [ ];
  };
}
