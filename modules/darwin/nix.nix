{
  username,
  lib,
  config,
  pkgs,
  ...
}:
{
  # Nix settings for darwin
  # Using determinate-nix.customSettings instead of nix.settings
  # because Determinate Nix manages /etc/nix/nix.conf directly
  # See: https://docs.determinate.systems/determinate-nix/use-with/nix-darwin
  determinate-nix.customSettings = {
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

    # Resource limits to prevent excessive RAM usage during builds
    # max-jobs: Number of parallel build jobs (default "auto" = all cores)
    # Reduce this to 2-4 to limit RAM consumption
    max-jobs = 4;

    # cores: Number of cores each build job can use (0 = all available)
    # Set to 2-4 to prevent single builds from using all resources
    cores = 2;

    # Timeout for builds with no output (prevents stuck builds)
    max-silent-time = 3600; # 1 hour

    keep-outputs = true;
    keep-derivations = true;
    fallback = true;
    keep-going = true;

    # Network settings - optimized for M4 Pro
    download-buffer-size = 524288000;
    http-connections = 128; # Increased from 64 for faster downloads
    max-substitution-jobs = 64; # Increased from 28 for M4 Pro's performance
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
      "https://devenv.cachix.org"
      "https://viperml.cachix.org"
      "https://cuda-maintainers.cachix.org"
      "https://claude-code.cachix.org"
      "https://cache.numtide.com"
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
      "lewisflude.cachix.org-1:Y4J8FK/Rb7Es/PnsQxk2ZGPvSLup6ywITz8nimdVWXc="
      "ags.cachix.org-1:naAvMrz0CuYqeyGNyLgE010iUiuf/qx6kYrUv3NwAJ8="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
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
    # Determinate Nix owns the daemon + /etc/nix/nix.conf; keep nix-darwin out
    enable = lib.mkForce false;

    # Flakes don't use channels - nixPath is only for legacy compatibility
    # Leaving empty for pure flakes approach
    nixPath = lib.mkDefault [ ];
    optimise = {
      # Automatic optimisation requires nix.enable = true; disable it while
      # Determinate Nix manages the daemon so the assertion stays satisfied.
      automatic = lib.mkDefault false;
    };
  };
}
