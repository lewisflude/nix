{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Only configure if sops is enabled and GITHUB_TOKEN secret exists
  config = lib.mkIf (config.sops.secrets ? GITHUB_TOKEN) {
    # Script to update /etc/nix/nix.conf with GitHub token from sops
    # This runs during system activation to configure GitHub authentication for Nix
    system.activationScripts.nixGithubToken = lib.mkAfter ''
      set -euo pipefail

      NIX_CONF_FILE="/etc/nix/nix.conf"
      SECRET_PATH="${config.sops.secrets.GITHUB_TOKEN.path}"

      # Check if secret exists and is readable
      if [ ! -r "$SECRET_PATH" ]; then
        echo "Warning: GitHub token secret not available at $SECRET_PATH" >&2
        exit 0
      fi

      GITHUB_TOKEN="$(cat "$SECRET_PATH")"

      if [ -z "$GITHUB_TOKEN" ]; then
        echo "Warning: GitHub token is empty" >&2
        exit 0
      fi

      # Ensure nix.conf exists (should be created by NixOS already)
      if [ ! -f "$NIX_CONF_FILE" ]; then
        echo "Warning: $NIX_CONF_FILE does not exist, creating it" >&2
        touch "$NIX_CONF_FILE"
        chmod 644 "$NIX_CONF_FILE"
      fi

      # Remove any existing access-tokens lines (there might be multiple)
      # Then add the new one at the end
      ${pkgs.gnused}/bin/sed -i '/^access-tokens.*github\.com/d' "$NIX_CONF_FILE" 2>/dev/null || true

      # Add the GitHub access token at the end
      echo "access-tokens = github.com=$GITHUB_TOKEN" >> "$NIX_CONF_FILE"

      # Ensure proper permissions
      chmod 644 "$NIX_CONF_FILE"
    '';
  };
}
