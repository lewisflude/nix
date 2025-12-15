{
  config,
  systemConfig,
  pkgs,
  lib,
  ...
}:
let
  # All your substituters in one place
  extraSubstituters = [
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
  extraTrustedPublicKeys = [
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
  updateNixConf = pkgs.writeShellScript "update-nix-conf" ''
        set -euo pipefail
        NIX_CONF_DIR="${config.xdg.configHome}/nix"
        NIX_CONF_FILE="$NIX_CONF_DIR/nix.conf"

        mkdir -p "$NIX_CONF_DIR"

        # Start fresh with substituters
        cat > "$NIX_CONF_FILE" << 'EOF'
    extra-substituters = ${lib.concatStringsSep " " extraSubstituters}
    extra-trusted-public-keys = ${lib.concatStringsSep " " extraTrustedPublicKeys}
    EOF

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

  # REMOVE the programs.zsh.initContent block entirely - it's redundant and destructive
}
