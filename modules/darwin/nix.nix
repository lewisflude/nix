{
  username,
  lib,
  config,
  pkgs,
  ...
}:
{
  # Determinate Nix configuration
  determinate-nix.customSettings = {
    flake-registry = "/etc/nix/flake-registry.json";
  };

  # Custom Nix configuration that gets included by Determinate Nix
  # This file is included via !include directive in /etc/nix/nix.conf
  # Binary caches are configured in flake.nix nixConfig, so we only set performance and security options here
  environment.etc."nix/nix.custom.conf" = {
    text = ''
      # User permissions
      trusted-users = root @admin ${username}

      # Disable dirty git tree warnings
      warn-dirty = false

      # Performance optimizations
      auto-optimise-store = true
      max-jobs = auto
      cores = 0

      # Keep outputs for better caching and development
      keep-outputs = true
      keep-derivations = true
      fallback = true
      keep-going = true

      # Download optimization (500MB buffer)
      download-buffer-size = 524288000

      # High-throughput substitution parallelism (Tip 5)
      # Maximizes parallel TCP connections and substitution jobs for faster binary cache fetching
      # Optimized for high-RAM system (48GB) - set to 128 for maximum throughput
      # Note: With cache priorities properly set in flake.nix, timeout delays are minimized,
      # so higher parallelism (128) is safe and beneficial
      # Reference: https://brianmcgee.uk/posts/2023/12/13/how-to-optimise-substitutions-in-nix/
      http-connections = 128
      max-substitution-jobs = 128

      # Allow substitution for aggregator derivations (Tip 7)
      # Forces Nix to use binary cache even for derivations marked allowSubstitutes = false
      # Speeds up symlinkJoin and other lightweight aggregator builds
      always-allow-substitutes = true

      # Performance optimizations for faster evaluation and builds
      builders-use-substitutes = true

      # Cache TTL for faster lookups
      narinfo-cache-positive-ttl = 30
      narinfo-cache-negative-ttl = 1

      # Build sandbox (security)
      sandbox = true

      # Connection settings
      connect-timeout = 5

      # Remove FlakeHub cache from trusted-substituters
      # FlakeHub cache requires authentication and isn't needed (flakes use API, not binary cache)
      # This overrides Determinate Nix's default which includes cache.flakehub.com
      # See: flake.nix nixConfig comments and docs/CACHE_ERROR_IMPACT.md
      trusted-substituters = https://install.determinate.systems

      # Logging
      log-lines = 25

      # Build-time input fetching (Tip 11)
      # Enables deferring source fetching until actual build time for inputs marked with buildTime = true
      # This speeds up flake evaluation by not fetching inputs during evaluation phase
      # Note: This is also set in flake.nix nixConfig.experimental-features for consistency
      # Note: In nix.conf format, this should be space-separated if multiple features are needed
      extra-experimental-features = build-time-fetch-tree

      # Note: Binary caches are configured in flake.nix nixConfig.extra-substituters and extra-trusted-public-keys
      # Those settings apply to both Darwin and NixOS systems via the flake
      # Note: Determinate Nix sets 'eval-cores' and 'lazy-trees' in /etc/nix/nix.conf
      # Note: GitHub access token is added dynamically via activation script
    '';
  };

  # Configure GitHub token from sops if available
  system.activationScripts.nixGithubToken = lib.mkIf (config.sops.secrets ? GITHUB_TOKEN) {
    text = ''
      set -euo pipefail

      NIX_CUSTOM_CONF="/etc/nix/nix.custom.conf"
      SECRET_PATH="${config.sops.secrets.GITHUB_TOKEN.path}"

      # Check if secret exists and is readable
      if [ -z "$SECRET_PATH" ] || [ ! -r "$SECRET_PATH" ]; then
        echo "Warning: GitHub token secret not available" >&2
        exit 0
      fi

      GITHUB_TOKEN="$(cat "$SECRET_PATH")"

      if [ -z "$GITHUB_TOKEN" ]; then
        echo "Warning: GitHub token is empty" >&2
        exit 0
      fi

      # Ensure the custom config file exists (should be created by nix-darwin)
      if [ ! -f "$NIX_CUSTOM_CONF" ]; then
        echo "Warning: $NIX_CUSTOM_CONF does not exist, creating it" >&2
        touch "$NIX_CUSTOM_CONF"
        chmod 644 "$NIX_CUSTOM_CONF"
      fi

      # Remove any existing access-tokens lines for github.com (there might be multiple)
      # Then add the new one at the end
      ${pkgs.gnused}/bin/sed -i "" '/^access-tokens.*github\.com/d' "$NIX_CUSTOM_CONF" 2>/dev/null || true

      # Add the GitHub access token at the end
      echo "access-tokens = github.com=$GITHUB_TOKEN" >> "$NIX_CUSTOM_CONF"

      # Ensure proper permissions
      chmod 644 "$NIX_CUSTOM_CONF"
    '';
  };

  # Note: nix.enable = false means nix-darwin doesn't manage the Nix daemon
  # Determinate Nix manages the daemon instead via determinate.darwinModules.default
  # This prevents conflicts between nix-darwin and Determinate Nix daemon management
  nix = {
    enable = false;

    # These settings are IGNORED when nix.enable = false
    # All active settings must be in environment.etc."nix/nix.custom.conf" above

    # Garbage collection is not configured because nix.enable = false
    # To run manually: nix-collect-garbage --delete-older-than 7d

    # Configure Nix path and channels
    nixPath = lib.mkDefault [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixpkgs"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };
}
