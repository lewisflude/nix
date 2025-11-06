{
  username,
  lib,
  config,
  pkgs,
  ...
}:
{

  determinate-nix.customSettings = {
    flake-registry = "/etc/nix/flake-registry.json";
  };

  environment.etc."nix/nix.custom.conf" = {
    text = ''

      trusted-users = root @admin ${username}


      warn-dirty = false


      auto-optimise-store = true
      max-jobs = auto
      cores = 0


      keep-outputs = true
      keep-derivations = true
      fallback = true
      keep-going = true


      download-buffer-size = 524288000







      http-connections = 128
      max-substitution-jobs = 128




      always-allow-substitutes = true


      builders-use-substitutes = true


      narinfo-cache-positive-ttl = 30
      narinfo-cache-negative-ttl = 1


      sandbox = true


      connect-timeout = 5





      trusted-substituters = https://install.determinate.systems


      log-lines = 25






      extra-experimental-features = build-time-fetch-tree





    '';
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

      GITHUB_TOKEN="$(cat "$SECRET_PATH")"

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

    nixPath = lib.mkDefault [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixpkgs"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };
}
