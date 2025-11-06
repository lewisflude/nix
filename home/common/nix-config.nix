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


    SECRET_PATH="${systemConfig.sops.secrets.GITHUB_TOKEN.path or ""}"

    if [ -n "$SECRET_PATH" ] && [ -r "$SECRET_PATH" ]; then
      GITHUB_TOKEN="$(cat "$SECRET_PATH")"


      if [ -n "$GITHUB_TOKEN" ]; then
        # Remove existing access-tokens line if present, then append new one
        # This preserves other settings like substituters
        if [ -f "$NIX_CONF_FILE" ]; then
          ${pkgs.gnused}/bin/sed -i '/^access-tokens.*github\.com/d' "$NIX_CONF_FILE" || true
        fi
        echo "access-tokens = github.com=$GITHUB_TOKEN" >> "$NIX_CONF_FILE"
        chmod 600 "$NIX_CONF_FILE"
      fi
    fi
  '';
in
{
  # Set NIX_USER_CONF_FILES to explicitly point to our config folder
  home.sessionVariables = {
    NIX_USER_CONF_FILES = "${config.xdg.configHome}/nix/nix.conf";
  };

  home.activation.updateNixConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${updateNixConf}
  '';

  programs.zsh.initContent = lib.mkAfter ''

    if [ -n "''${GITHUB_TOKEN:-}" ]; then
      mkdir -p ${config.xdg.configHome}/nix
      echo "access-tokens = github.com=$GITHUB_TOKEN" > ${config.xdg.configHome}/nix/nix.conf
      chmod 600 ${config.xdg.configHome}/nix/nix.conf
    fi
  '';
}
