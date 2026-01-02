{
  config,
  systemConfig,
  pkgs,
  lib,
  ...
}:
let
  updateNixConf = pkgs.writeShellScript "update-nix-conf" ''
    set -euo pipefail
    NIX_CONF_DIR="${config.xdg.configHome}/nix"
    NIX_CONF_FILE="$NIX_CONF_DIR/nix.conf"

    mkdir -p "$NIX_CONF_DIR"

    # Create user nix.conf with only GitHub token (if available)
    # Note: trusted-public-keys and substituters are configured at system level
    : > "$NIX_CONF_FILE"  # Clear file

    # Add GitHub token if available
    SECRET_PATH="${systemConfig.sops.secrets.GITHUB_TOKEN.path or ""}"
    if [ -n "$SECRET_PATH" ] && [ -r "$SECRET_PATH" ]; then
      GITHUB_TOKEN="$(${pkgs.coreutils}/bin/cat "$SECRET_PATH")"
      if [ -n "$GITHUB_TOKEN" ]; then
        echo "access-tokens = github.com=$GITHUB_TOKEN" >> "$NIX_CONF_FILE"
      fi
    fi

    chmod 600 "$NIX_CONF_FILE"
  '';
in
{
  home.sessionVariables = {
    NIX_USER_CONF_FILES = "${config.xdg.configHome}/nix/nix.conf";
  };

  home.activation.updateNixConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${updateNixConf}
  '';
}
