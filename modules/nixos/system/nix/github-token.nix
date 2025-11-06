{
  config,
  lib,
  pkgs,
  ...
}:
{

  config = lib.mkIf (config.sops.secrets ? GITHUB_TOKEN) {

    system.activationScripts.nixGithubToken = lib.mkAfter ''
      set -euo pipefail

      NIX_CONF_FILE="/etc/nix/nix.conf"
      SECRET_PATH="${config.sops.secrets.GITHUB_TOKEN.path}"


      if [ ! -r "$SECRET_PATH" ]; then
        echo "Warning: GitHub token secret not available at $SECRET_PATH" >&2
        exit 0
      fi

      GITHUB_TOKEN="$(cat "$SECRET_PATH")"

      if [ -z "$GITHUB_TOKEN" ]; then
        echo "Warning: GitHub token is empty" >&2
        exit 0
      fi


      if [ ! -f "$NIX_CONF_FILE" ]; then
        echo "Warning: $NIX_CONF_FILE does not exist, creating it" >&2
        touch "$NIX_CONF_FILE"
        chmod 644 "$NIX_CONF_FILE"
      fi



      ${pkgs.gnused}/bin/sed -i '/^access-tokens.*github\.com/d' "$NIX_CONF_FILE" 2>/dev/null || true


      echo "access-tokens = github.com=$GITHUB_TOKEN" >> "$NIX_CONF_FILE"


      chmod 644 "$NIX_CONF_FILE"
    '';
  };
}
