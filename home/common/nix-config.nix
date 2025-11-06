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
        echo "access-tokens = github.com=$GITHUB_TOKEN" > "$NIX_CONF_FILE"
        chmod 600 "$NIX_CONF_FILE"
      fi
    fi
  '';
in
{

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
