{
  username,
  lib,
  config,
  pkgs,
  ...
}:
let
  constants = import ../../lib/constants.nix;
in
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
    # Note: always-allow-substitutes is managed by Determinate Nix, not allowed in customSettings
    builders-use-substitutes = true;
    narinfo-cache-positive-ttl = 30;
    narinfo-cache-negative-ttl = 1;

    # Binary cache substituters (shared from lib/constants.nix)
    extra-substituters = constants.binaryCaches.substituters;

    # Trusted public keys for binary caches (shared from lib/constants.nix)
    extra-trusted-public-keys = constants.binaryCaches.trustedPublicKeys;

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
